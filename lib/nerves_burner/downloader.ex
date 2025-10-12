defmodule NervesBurner.Downloader do
  @moduledoc """
  Handles downloading firmware from GitHub releases.
  """

  @doc """
  Downloads firmware for the specified image config and platform.
  If fwup is available, downloads .fw file. Otherwise, downloads alternative format (zip or img.gz).
  """
  def download(image_config, platform) do
    fwup_available = NervesBurner.Fwup.available?()
    
    with {:ok, release_url} <- get_latest_release_url(image_config.repo),
         {:ok, asset_url} <- find_asset_url(release_url, image_config.asset_pattern.(platform), fwup_available),
         {:ok, firmware_path} <- download_file(asset_url, platform, fwup_available) do
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
        if fwup_available do
          # Try to find .fw file
          case Enum.find(assets, fn asset -> asset["name"] == asset_name end) do
            %{"browser_download_url" => download_url} ->
              {:ok, download_url}

            nil ->
              {:error, "Asset '#{asset_name}' not found in release"}
          end
        else
          # fwup not available, try to find alternative formats
          find_alternative_asset(assets, asset_name)
        end

      {:ok, %{status: status, body: body}} ->
        error_message = extract_error_message(body, status)
        {:error, "Failed to fetch assets from #{assets_url}. #{error_message}"}

      {:error, reason} ->
        {:error, "HTTP request failed for #{assets_url}: #{inspect(reason)}"}
    end
  end

  defp find_alternative_asset(assets, asset_name) do
    # Get base name without .fw extension
    base_name = String.replace_suffix(asset_name, ".fw", "")
    
    # Try to find zip or img.gz alternatives
    alternative_patterns = [
      "#{base_name}.zip",
      "#{base_name}.img.gz",
      "#{base_name}.img"
    ]
    
    result = Enum.find_value(alternative_patterns, fn pattern ->
      case Enum.find(assets, fn asset -> asset["name"] == pattern end) do
        %{"browser_download_url" => download_url} -> {:ok, download_url, pattern}
        nil -> nil
      end
    end)
    
    case result do
      {:ok, download_url, pattern} ->
        IO.puts(IO.ANSI.format([
          :yellow, 
          "\nNote: fwup is not available. Downloading alternative format: #{pattern}",
          :reset
        ]))
        {:ok, download_url}
      
      nil ->
        {:error, "No suitable alternative format (zip, img.gz, img) found for '#{asset_name}'. Please install fwup to use .fw files."}
    end
  end

  defp download_file(url, platform, fwup_available) do
    # Create tmp directory for downloads
    tmp_dir = System.tmp_dir!()
    
    # Determine file extension from URL
    extension = 
      cond do
        String.ends_with?(url, ".fw") -> ".fw"
        String.ends_with?(url, ".zip") -> ".zip"
        String.ends_with?(url, ".img.gz") -> ".img.gz"
        String.ends_with?(url, ".img") -> ".img"
        fwup_available -> ".fw"
        true -> ".zip"
      end
    
    filename = "firmware_#{platform}_#{:os.system_time(:millisecond)}#{extension}"
    dest_path = Path.join(tmp_dir, filename)

    IO.puts(IO.ANSI.format([:cyan, "Downloading from: ", :reset, "#{url}"]))

    case do_download(url, dest_path) do
      :ok ->
        IO.puts(IO.ANSI.format([:green, "✓ File saved to: ", :reset, "#{dest_path}"]))
        {:ok, dest_path}

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end

  defp do_download(url, path) do
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
