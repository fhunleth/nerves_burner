defmodule NervesBurner.Downloader do
  @moduledoc """
  Handles downloading firmware from GitHub releases.
  """

  alias NervesBurner.Output

  @doc """
  Downloads firmware for the specified image config and platform.
  If fwup is available, downloads .fw file. Otherwise, downloads alternative format (zip or img.gz).
  """
  def download(image_config, platform) do
    fwup_available = NervesBurner.Fwup.available?()

    with {:ok, release_url} <- get_latest_release_url(image_config.repo),
         {:ok, asset_info} <-
           find_asset_url(release_url, image_config.asset_pattern.(platform), fwup_available),
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

  defp find_asset_url(assets_url, asset_name, fwup_available) do
    case Req.get(assets_url, headers: github_headers()) do
      {:ok, %{status: 200, body: assets}} when is_list(assets) ->
        # Look for SHA256SUMS file in the assets
        sha256sums_url =
          case Enum.find(assets, fn a -> a["name"] == "SHA256SUMS" end) do
            %{"browser_download_url" => url} -> url
            nil -> nil
          end

        if fwup_available do
          # Try to find .fw file
          case Enum.find(assets, fn asset -> asset["name"] == asset_name end) do
            %{"browser_download_url" => download_url} = asset ->
              asset_info = %{
                url: download_url,
                name: asset_name,
                size: asset["size"],
                sha256sums_url: sha256sums_url
              }

              {:ok, asset_info}

            nil ->
              {:error, "Asset '#{asset_name}' not found in release"}
          end
        else
          # fwup not available, try to find alternative formats
          find_alternative_asset(assets, asset_name, sha256sums_url)
        end

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body, status)
        {:error, "Failed to fetch assets from #{assets_url}. #{error_message}"}

      {:error, reason} ->
        {:error, "HTTP request failed for #{assets_url}: #{inspect(reason)}"}
    end
  end

  defp find_alternative_asset(assets, asset_name, sha256sums_url) do
    # Get base name without .fw extension
    base_name = String.replace_suffix(asset_name, ".fw", "")

    # Try to find zip or img.gz alternatives
    alternative_patterns = [
      "#{base_name}.zip",
      "#{base_name}.img.gz",
      "#{base_name}.img"
    ]

    result =
      Enum.find_value(alternative_patterns, fn pattern ->
        case Enum.find(assets, fn asset -> asset["name"] == pattern end) do
          %{"browser_download_url" => download_url} = asset ->
            {:ok, download_url, pattern, asset["size"]}

          nil ->
            nil
        end
      end)

    case result do
      {:ok, download_url, pattern, size} ->
        Output.warning(
          "\nNote: fwup is not available. Downloading alternative format: #{pattern}"
        )

        asset_info = %{
          url: download_url,
          name: pattern,
          size: size,
          sha256sums_url: sha256sums_url
        }

        {:ok, asset_info}

      nil ->
        {:error,
         "No suitable alternative format (zip, img.gz, img) found for '#{asset_name}'. Please install fwup to use .fw files."}
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

    Output.labeled("Downloading from: ", "#{url}")

    case do_download_with_progress(url, dest_path) do
      :ok ->
        # Verify the downloaded file size
        case verify_size(dest_path, asset_info.size) do
          :ok ->
            # Try to download and store hash from GitHub if available
            case fetch_and_store_hash_from_github(dest_path, asset_info) do
              :ok ->
                # Verify the downloaded file against the GitHub hash
                case verify_hash(dest_path, asset_info) do
                  :ok ->
                    Output.success("✓ Hash verified from SHA256SUMS")
                    Output.labeled("✓ File saved to: ", "#{dest_path}", :green)
                    {:ok, dest_path}

                  {:error, reason} ->
                    File.rm(dest_path)
                    {:error, "Hash verification failed: #{reason}"}
                end

              {:error, reason} ->
                # If GitHub hash not available, ask user for confirmation
                IO.puts("")
                Output.warning("⚠ Warning: SHA256SUMS file not available (#{inspect(reason)})")

                IO.puts("Hash cannot be verified from the release.")
                IO.puts("A local hash will be computed and saved for future verification.")
                IO.write("Continue with download? (yes/no): ")

                case IO.gets("") |> String.trim() |> String.downcase() do
                  answer when answer in ["yes", "y"] ->
                    # Compute and store hash locally
                    case compute_and_store_hash(dest_path) do
                      :ok ->
                        Output.success("✓ Local hash computed and saved")
                        Output.labeled("✓ File saved to: ", "#{dest_path}", :green)
                        {:ok, dest_path}

                      {:error, hash_error} ->
                        Output.warning(
                          "⚠ Warning: Failed to compute hash: #{inspect(hash_error)}"
                        )

                        IO.puts("Starting new download...")
                        File.rm(dest_path)
                        do_download(url, dest_path, asset_info)
                    end

                  _ ->
                    File.rm(dest_path)
                    {:error, "Download cancelled by user"}
                end
            end

          {:error, reason} ->
            File.rm(dest_path)
            {:error, "Downloaded file verification failed: #{reason}"}
        end

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end

  defp do_download_with_progress(url, path) do
    # Try to get total size for a proper percentage bar
    total =
      case Req.head!(url: url).headers |> Map.get("content-length") do
        [len | _] -> String.to_integer(len)
        _ -> 0
      end

    {:ok, io} = File.open(path, [:write, :binary])

    # Stream the body; update the bar on each chunk
    fun = fn
      {:status, _}, {req, res} ->
        {:cont, {req, res}}

      {:headers, _}, {req, res} ->
        {:cont, {req, res}}

      {:data, chunk}, {req, res} ->
        :ok = IO.binwrite(io, chunk)

        downloaded =
          (Req.Response.get_private(res, :downloaded) || 0)
          |> Kernel.+(byte_size(chunk))

        res = Req.Response.put_private(res, :downloaded, downloaded)

        if total > 0 do
          ProgressBar.render(downloaded, total, suffix: :bytes)
        end

        {:cont, {req, res}}
    end

    if total > 0 do
      Req.get!(url: url, raw: true, into: fun)
    else
      # No Content-Length? Show an indeterminate animation while downloading.
      ProgressBar.render_indeterminate([text: "Downloading…"], fn ->
        Req.get!(url: url, raw: true, into: fun)
      end)
    end

    File.close(io)
    :ok
  rescue
    reason -> {:error, reason}
  end

  @doc false
  def get_cache_dir do
    :filename.basedir(:user_cache, ~c"nerves_burner")
    |> List.to_string()
  end

  @doc false
  def check_cached_file(cache_path, asset_info) do
    if File.exists?(cache_path) do
      hash_file = cache_path <> ".sha256"

      # If there's no local hash, treat as failed download and redownload
      if not File.exists?(hash_file) do
        IO.puts("Cached firmware has no hash file, removing and re-downloading...")
        File.rm(cache_path)
        :not_found
      else
        case verify_file(cache_path, asset_info) do
          :ok -> :valid
          {:error, _} -> :invalid
        end
      end
    else
      :not_found
    end
  end

  @doc false
  def verify_file(file_path, asset_info) do
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
            IO.puts("✓ Hash verified")
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

  @doc false
  def compute_sha256(file_path) do
    file_path
    |> File.stream!([], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, acc ->
      :crypto.hash_update(acc, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  @doc false
  def store_hash(file_path) do
    hash = compute_sha256(file_path)
    hash_file = file_path <> ".sha256"
    File.write(hash_file, hash)
  end

  defp compute_and_store_hash(file_path) do
    try do
      hash = compute_sha256(file_path)
      hash_file = file_path <> ".sha256"
      File.write(hash_file, hash)
      :ok
    rescue
      error ->
        {:error, error}
    end
  end

  defp fetch_and_store_hash_from_github(file_path, asset_info) do
    case asset_info.sha256sums_url do
      nil ->
        {:error, :no_hash_available}

      sha256sums_url ->
        case Req.get(sha256sums_url) do
          {:ok, %{status: 200, body: body}} ->
            # Parse SHA256SUMS file to find hash for this specific file
            # Format: "hash  filename" (two spaces between hash and filename)
            hash =
              body
              |> String.split("\n")
              |> Enum.find_value(fn line ->
                case String.split(line, ~r/\s+/, parts: 2) do
                  [hash, filename] ->
                    if String.trim(filename) == asset_info.name do
                      String.downcase(String.trim(hash))
                    else
                      nil
                    end

                  _ ->
                    nil
                end
              end)

            case hash do
              nil ->
                {:error, :hash_not_found_in_sums_file}

              hash ->
                # Verify it's a valid SHA256 hash (64 hex characters)
                if String.match?(hash, ~r/^[0-9a-f]{64}$/) do
                  hash_file = file_path <> ".sha256"
                  File.write(hash_file, hash)
                  :ok
                else
                  {:error, :invalid_hash_format}
                end
            end

          _ ->
            {:error, :download_failed}
        end
    end
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
