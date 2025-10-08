defmodule NervesBurner.Downloader do
  @moduledoc """
  Handles downloading firmware from GitHub releases.
  """

  @doc """
  Downloads firmware for the specified image config and platform.
  """
  def download(image_config, platform) do
    with {:ok, release_url} <- get_latest_release_url(image_config.repo),
         {:ok, asset_info} <- find_asset_url(release_url, image_config.asset_pattern.(platform)),
         {:ok, firmware_path} <- download_file(asset_info, platform) do
      {:ok, firmware_path}
    end
  end

  defp get_latest_release_url(repo) do
    url = "https://api.github.com/repos/#{repo}/releases/latest"

    case Req.get(url, headers: github_headers()) do
      {:ok, %{status: 200, body: body}} ->
        case body do
          %{"assets_url" => assets_url} ->
            {:ok, assets_url}

          %{"message" => message} ->
            {:error, "GitHub API error: #{message}"}

          _ ->
            {:error, "Unexpected response format"}
        end

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body, status)
        {:error, "Failed to fetch release info from #{url}. #{error_message}"}

      {:error, reason} ->
        {:error, "HTTP request failed for #{url}: #{inspect(reason)}"}
    end
  end

  defp find_asset_url(assets_url, asset_name) do
    case Req.get(assets_url, headers: github_headers()) do
      {:ok, %{status: 200, body: assets}} when is_list(assets) ->
        case Enum.find(assets, fn asset -> asset["name"] == asset_name end) do
          %{"browser_download_url" => download_url} = asset ->
            # Extract size if available
            asset_info = %{
              url: download_url,
              name: asset_name,
              size: asset["size"]
            }

            {:ok, asset_info}

          nil ->
            {:error, "Asset '#{asset_name}' not found in release"}
        end

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body, status)
        {:error, "Failed to fetch assets from #{assets_url}. #{error_message}"}

      {:error, reason} ->
        {:error, "HTTP request failed for #{assets_url}: #{inspect(reason)}"}
    end
  end

  defp download_file(asset_info, _platform) do
    url = asset_info.url
    cache_dir = get_cache_dir()
    cache_path = Path.join(cache_dir, asset_info.name)

    # Check if cached file exists and is valid
    case check_cached_file(cache_path, asset_info) do
      :valid ->
        IO.puts("✓ Using cached firmware: #{cache_path}")
        {:ok, cache_path}

      :invalid ->
        IO.puts("Cached file invalid, re-downloading...")
        do_download(url, cache_path, asset_info)

      :not_found ->
        do_download(url, cache_path, asset_info)
    end
  end

  defp do_download(url, dest_path, asset_info) do
    # Ensure cache directory exists
    dest_path |> Path.dirname() |> File.mkdir_p!()

    IO.puts("Downloading from: #{url}")

    case Req.get(url, into: File.stream!(dest_path)) do
      {:ok, %{status: 200}} ->
        # Verify the downloaded file (size only, no hash yet)
        case verify_size(dest_path, asset_info.size) do
          :ok ->
            # Store hash for future verification
            store_hash(dest_path)
            IO.puts("✓ File saved to: #{dest_path}")
            {:ok, dest_path}

          {:error, reason} ->
            File.rm(dest_path)
            {:error, "Downloaded file verification failed: #{reason}"}
        end

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body, status)
        {:error, error_message}

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end

  defp get_cache_dir do
    case :os.type() do
      {:unix, :darwin} ->
        # macOS: ~/Library/Caches/nerves_burner
        home = System.user_home!()
        Path.join([home, "Library", "Caches", "nerves_burner"])

      {:unix, _} ->
        # Linux: $XDG_CACHE_HOME/nerves_burner or ~/.cache/nerves_burner
        case System.get_env("XDG_CACHE_HOME") do
          nil ->
            home = System.user_home!()
            Path.join([home, ".cache", "nerves_burner"])

          cache_home ->
            Path.join(cache_home, "nerves_burner")
        end

      {:win32, _} ->
        # Windows: %LOCALAPPDATA%\nerves_burner\cache
        case System.get_env("LOCALAPPDATA") do
          nil ->
            home = System.user_home!()
            Path.join([home, "AppData", "Local", "nerves_burner", "cache"])

          local_app_data ->
            Path.join([local_app_data, "nerves_burner", "cache"])
        end
    end
  end

  defp check_cached_file(cache_path, asset_info) do
    if File.exists?(cache_path) do
      case verify_file(cache_path, asset_info) do
        :ok -> :valid
        {:error, _} -> :invalid
      end
    else
      :not_found
    end
  end

  defp verify_file(file_path, asset_info) do
    # Verify file size if available
    with :ok <- verify_size(file_path, asset_info.size),
         :ok <- verify_hash(file_path, asset_info) do
      :ok
    end
  end

  defp verify_size(_file_path, nil), do: :ok

  defp verify_size(file_path, expected_size) do
    case File.stat(file_path) do
      {:ok, %{size: actual_size}} ->
        if actual_size == expected_size do
          :ok
        else
          {:error, "Size mismatch: expected #{expected_size}, got #{actual_size}"}
        end

      {:error, reason} ->
        {:error, "Failed to stat file: #{inspect(reason)}"}
    end
  end

  defp verify_hash(file_path, _asset_info) do
    hash_file = file_path <> ".sha256"

    # If we have a stored hash, verify it
    if File.exists?(hash_file) do
      case File.read(hash_file) do
        {:ok, stored_hash} ->
          computed_hash = compute_sha256(file_path)

          if String.trim(stored_hash) == computed_hash do
            :ok
          else
            {:error, "Hash mismatch"}
          end

        {:error, _} ->
          # Can't read hash file, assume valid
          :ok
      end
    else
      # No hash file yet, assume valid
      :ok
    end
  end

  defp compute_sha256(file_path) do
    file_path
    |> File.stream!([], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, acc ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  defp store_hash(file_path) do
    hash = compute_sha256(file_path)
    hash_file = file_path <> ".sha256"
    File.write(hash_file, hash)
  end

  # Build headers for GitHub API requests, including auth token if available
  defp github_headers do
    base_headers = [{"accept", "application/vnd.github+json"}]

    token = System.get_env("GITHUB_TOKEN") || System.get_env("GITHUB_API_TOKEN")

    case token do
      nil ->
        base_headers

      "" ->
        base_headers

      token ->
        # GitHub API uses 'token' prefix, not 'Bearer'
        [{"authorization", "token #{token}"} | base_headers]
    end
  end

  # Extract error message from GitHub API response
  defp extract_error_message(body, status) when is_map(body) do
    case body do
      %{"message" => message, "documentation_url" => doc_url} ->
        "HTTP #{status}: #{message}. See #{doc_url}"

      %{"message" => message} ->
        "HTTP #{status}: #{message}"

      _ ->
        "HTTP #{status}"
    end
  end

  defp extract_error_message(body, status) when is_binary(body) do
    # Try to extract message from HTML or plain text response
    if String.contains?(body, "API rate limit exceeded") do
      "HTTP #{status}: API rate limit exceeded. Consider setting GITHUB_TOKEN environment variable."
    else
      # Truncate long responses
      truncated = String.slice(body, 0, 200)
      "HTTP #{status}: #{truncated}"
    end
  end

  defp extract_error_message(_body, status) do
    "HTTP #{status}"
  end
end
