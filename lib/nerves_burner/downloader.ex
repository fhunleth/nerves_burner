defmodule NervesBurner.Downloader do
  @moduledoc """
  Handles downloading firmware from GitHub releases.
  """

  @doc """
  Downloads firmware for the specified image config and platform.
  """
  def download(image_config, platform) do
    with {:ok, release_url} <- get_latest_release_url(image_config.repo),
         {:ok, asset_url} <- find_asset_url(release_url, image_config.asset_pattern.(platform)),
         {:ok, firmware_path} <- download_file(asset_url, platform) do
      {:ok, firmware_path}
    end
  end

  defp get_latest_release_url(repo) do
    url = "https://api.github.com/repos/#{repo}/releases/latest"

    case http_get(url) do
      {:ok, body} ->
        case parse_json(body) do
          {:ok, %{"assets_url" => assets_url}} ->
            {:ok, assets_url}

          {:ok, %{"message" => message}} ->
            {:error, "GitHub API error: #{message}"}

          {:error, reason} ->
            {:error, "Failed to parse response: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp find_asset_url(assets_url, asset_name) do
    case http_get(assets_url) do
      {:ok, body} ->
        case parse_json(body) do
          {:ok, assets} when is_list(assets) ->
            case Enum.find(assets, fn asset -> asset["name"] == asset_name end) do
              %{"browser_download_url" => download_url} ->
                {:ok, download_url}

              nil ->
                {:error, "Asset '#{asset_name}' not found in release"}
            end

          {:error, reason} ->
            {:error, "Failed to parse assets: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp download_file(url, platform) do
    # Create tmp directory for downloads
    tmp_dir = System.tmp_dir!()
    filename = "firmware_#{platform}_#{:os.system_time(:millisecond)}.fw"
    dest_path = Path.join(tmp_dir, filename)

    IO.puts("Downloading from: #{url}")

    case http_download(url, dest_path) do
      :ok ->
        {:ok, dest_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp http_get(url) do
    headers = [
      {~c"user-agent", ~c"nerves_burner/0.1.0"},
      {~c"accept", ~c"application/vnd.github+json"}
    ]

    url_charlist = String.to_charlist(url)

    case :httpc.request(:get, {url_charlist, headers}, [{:timeout, 30_000}], []) do
      {:ok, {{_version, 200, _status}, _headers, body}} ->
        {:ok, to_string(body)}

      {:ok, {{_version, status_code, _status}, _headers, body}} ->
        {:error, "HTTP #{status_code}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp http_download(url, dest_path) do
    headers = [
      {~c"user-agent", ~c"nerves_burner/0.1.0"}
    ]

    url_charlist = String.to_charlist(url)

    # Use stream mode to handle large files
    request = {url_charlist, headers}
    http_options = [{:timeout, :infinity}, {:connect_timeout, 30_000}]
    options = [{:stream, String.to_charlist(dest_path)}, {:sync, true}]

    case :httpc.request(:get, request, http_options, options) do
      {:ok, :saved_to_file} ->
        IO.puts("✓ File saved to: #{dest_path}")
        :ok

      {:ok, {{_version, 200, _status}, _headers, _body}} ->
        :ok

      {:ok, {{_version, status_code, _status}, _headers, body}} ->
        {:error, "HTTP #{status_code}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end

  # Simple JSON parser using regex to extract specific fields
  # This is a minimal parser for GitHub API responses
  defp parse_json(json_string) do
    # Parse GitHub release API response
    cond do
      # Check if it's a release response with assets_url
      String.contains?(json_string, "assets_url") ->
        case Regex.run(~r/"assets_url":\s*"([^"]+)"/, json_string) do
          [_, url] -> {:ok, %{"assets_url" => url}}
          _ -> {:error, "Could not find assets_url"}
        end

      # Check if it's an error message
      String.contains?(json_string, "message") ->
        case Regex.run(~r/"message":\s*"([^"]+)"/, json_string) do
          [_, msg] -> {:ok, %{"message" => msg}}
          _ -> {:error, "Could not parse error message"}
        end

      # Try to parse as an assets array
      String.contains?(json_string, "browser_download_url") ->
        parse_assets_json(json_string)

      true ->
        {:error, "Unrecognized JSON format"}
    end
  end

  # Parse assets array from GitHub API
  defp parse_assets_json(json_string) do
    # Extract all assets with their names and download URLs
    assets =
      Regex.scan(~r/"name":\s*"([^"]+)"[^}]*"browser_download_url":\s*"([^"]+)"/, json_string)
      |> Enum.map(fn [_, name, url] -> %{"name" => name, "browser_download_url" => url} end)

    if length(assets) > 0 do
      {:ok, assets}
    else
      {:error, "No assets found in response"}
    end
  end
end
