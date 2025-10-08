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

    case Req.get(url, headers: [{"accept", "application/vnd.github+json"}]) do
      {:ok, %{status: 200, body: body}} ->
        case body do
          %{"assets_url" => assets_url} ->
            {:ok, assets_url}

          %{"message" => message} ->
            {:error, "GitHub API error: #{message}"}

          _ ->
            {:error, "Unexpected response format"}
        end

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp find_asset_url(assets_url, asset_name) do
    case Req.get(assets_url, headers: [{"accept", "application/vnd.github+json"}]) do
      {:ok, %{status: 200, body: assets}} when is_list(assets) ->
        case Enum.find(assets, fn asset -> asset["name"] == asset_name end) do
          %{"browser_download_url" => download_url} ->
            {:ok, download_url}

          nil ->
            {:error, "Asset '#{asset_name}' not found in release"}
        end

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp download_file(url, platform) do
    # Create tmp directory for downloads
    tmp_dir = System.tmp_dir!()
    filename = "firmware_#{platform}_#{:os.system_time(:millisecond)}.fw"
    dest_path = Path.join(tmp_dir, filename)

    IO.puts("Downloading from: #{url}")

    case Req.get(url, into: File.stream!(dest_path)) do
      {:ok, %{status: 200}} ->
        IO.puts("✓ File saved to: #{dest_path}")
        {:ok, dest_path}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Download failed: #{inspect(reason)}"}
    end
  end
end
