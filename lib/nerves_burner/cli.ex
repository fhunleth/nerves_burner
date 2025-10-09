defmodule NervesBurner.CLI do
  @moduledoc """
  Main CLI entry point for the Nerves Burner application.
  """

  def main(_args) do
    print_banner()

    with {:ok, image_config} <- select_firmware_image(),
         {:ok, platform} <- select_platform(image_config),
         {:ok, wifi_config} <- get_wifi_credentials(),
         {:ok, firmware_path} <- download_firmware(image_config, platform),
         {:ok, device} <- select_device(),
         :ok <- burn_firmware(firmware_path, device, wifi_config) do
      IO.puts(IO.ANSI.format([:green, :bright, "\n✓ Firmware burned successfully!\n", :reset]))
      IO.puts(IO.ANSI.format([:cyan, "You can now safely remove the MicroSD card.\n", :reset]))
    else
      {:error, :cancelled} ->
        IO.puts(IO.ANSI.format([:yellow, "\nOperation cancelled by user.\n", :reset]))
        System.halt(0)

      {:error, reason} ->
        IO.puts(IO.ANSI.format([:red, :bright, "\n✗ Error: ", :reset, :red, "#{reason}\n", :reset]))
        System.halt(1)
    end
  end

  defp print_banner do
    logo = """
    \e[38;5;24m████▄▄    \e[38;5;74m▐███
    \e[38;5;24m█▌  ▀▀██▄▄  \e[38;5;74m▐█
    \e[38;5;24m█▌  \e[38;5;74m▄▄  \e[38;5;24m▀▀  \e[38;5;74m▐█   \e[39mN  E  R  V  E  S
    \e[38;5;24m█▌  \e[38;5;74m▀▀██▄▄  ▐█
    \e[38;5;24m███▌    \e[38;5;74m▀▀████\e[0m
    """

    IO.puts(["\n", logo])
  end

  defp select_firmware_image do
    IO.puts(IO.ANSI.format([:cyan, :bright, "Select a firmware image:", :reset, "\n"]))

    images = NervesBurner.FirmwareImages.list()

    images
    |> Enum.with_index(1)
    |> Enum.each(fn {{name, _config}, index} ->
      IO.puts(IO.ANSI.format(["  ", :yellow, "#{index}.", :reset, " #{name}"]))
    end)

    case get_user_choice(IO.ANSI.format(["\n", :green, "Enter your choice (1-#{length(images)}): ", :reset]), 1..length(images)) do
      {:ok, choice} ->
        {_name, config} = Enum.at(images, choice - 1)
        {:ok, config}

      error ->
        error
    end
  end

  defp select_platform(image_config) do
    platforms = image_config.platforms

    IO.puts(IO.ANSI.format(["\n", :cyan, :bright, "Select a platform:", :reset, "\n"]))

    platforms
    |> Enum.with_index(1)
    |> Enum.each(fn {platform, index} ->
      IO.puts(IO.ANSI.format(["  ", :yellow, "#{index}.", :reset, " #{platform}"]))
    end)

    case get_user_choice(IO.ANSI.format(["\n", :green, "Enter your choice (1-#{length(platforms)}): ", :reset]), 1..length(platforms)) do
      {:ok, choice} ->
        {:ok, Enum.at(platforms, choice - 1)}

      error ->
        error
    end
  end

  defp get_wifi_credentials do
    IO.puts(IO.ANSI.format(["\n", :cyan, :bright, "Would you like to configure WiFi credentials?", :reset]))
    IO.puts(IO.ANSI.format([:cyan, "(This is supported by Circuits Quickstart and Nerves Livebook firmware)\n", :reset]))

    case get_user_input(IO.ANSI.format([:green, "Configure WiFi? (y/n): ", :reset])) do
      input when input in ["y", "Y", "yes", "Yes", "YES"] ->
        get_wifi_details()

      _ ->
        {:ok, %{}}
    end
  end

  defp get_wifi_details do
    ssid = get_user_input(IO.ANSI.format(["\n", :green, "Enter WiFi SSID: ", :reset]))

    if ssid == "" do
      IO.puts(IO.ANSI.format([:yellow, "WiFi SSID cannot be empty. Skipping WiFi configuration.", :reset]))
      {:ok, %{}}
    else
      passphrase = get_user_input(IO.ANSI.format([:green, "Enter WiFi passphrase: ", :reset]))

      if passphrase == "" do
        IO.puts(IO.ANSI.format([:yellow, "WiFi passphrase cannot be empty. Skipping WiFi configuration.", :reset]))
        {:ok, %{}}
      else
        {:ok, %{ssid: ssid, passphrase: passphrase}}
      end
    end
  end

  defp download_firmware(image_config, platform) do
    IO.puts(IO.ANSI.format(["\n", :cyan, :bright, "Downloading firmware...", :reset]))

    case NervesBurner.Downloader.download(image_config, platform) do
      {:ok, path} ->
        IO.puts(IO.ANSI.format([:green, "✓ Download complete: ", :reset, "#{path}\n"]))
        {:ok, path}

      {:error, reason} ->
        {:error, "Download failed: #{reason}"}
    end
  end

  defp select_device do
    case scan_devices() do
      {:ok, [_ | _] = devices} ->
        choose_device(devices)

      {:ok, []} ->
        IO.puts(IO.ANSI.format(["\n", :yellow, "No MicroSD cards detected.", :reset]))

        case get_user_input(IO.ANSI.format(["\n", :green, "Would you like to rescan? (y/n): ", :reset])) do
          input when input in ["y", "Y", "yes", "Yes"] ->
            select_device()

          _ ->
            {:error, :cancelled}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp scan_devices do
    IO.puts(IO.ANSI.format(["\n", :cyan, "Scanning for MicroSD cards...", :reset]))

    case NervesBurner.Fwup.scan_devices() do
      {:ok, devices} ->
        {:ok, devices}

      {:error, reason} ->
        {:error, "Failed to scan devices: #{reason}"}
    end
  end

  defp choose_device(devices) do
    IO.puts(IO.ANSI.format(["\n", :cyan, :bright, "Available devices:", :reset, "\n"]))

    devices
    |> Enum.with_index(1)
    |> Enum.each(fn {device, index} ->
      size_info = if device.size, do: " (#{format_size(device.size)})", else: ""
      IO.puts(IO.ANSI.format(["  ", :yellow, "#{index}.", :reset, " #{device.path}#{size_info}"]))
    end)

    IO.puts(IO.ANSI.format(["  ", :yellow, "#{length(devices) + 1}.", :reset, " Rescan"]))

    case get_user_choice(
           IO.ANSI.format(["\n", :green, "Enter your choice (1-#{length(devices) + 1}): ", :reset]),
           1..(length(devices) + 1)
         ) do
      {:ok, choice} when choice == length(devices) + 1 ->
        select_device()

      {:ok, choice} ->
        device = Enum.at(devices, choice - 1)
        confirm_device(device)

      error ->
        error
    end
  end

  defp confirm_device(device) do
    IO.puts(IO.ANSI.format(["\n", :red, :bright, "⚠️  WARNING: ", :reset, :red, "All data on #{device.path} will be erased!", :reset]))

    case get_user_input(IO.ANSI.format([:yellow, "Are you sure you want to continue? (yes/no): ", :reset])) do
      input when input in ["yes", "Yes", "YES"] ->
        {:ok, device.path}

      _ ->
        IO.puts(IO.ANSI.format(["\n", :yellow, "Device selection cancelled.", :reset]))
        select_device()
    end
  end

  defp burn_firmware(firmware_path, device_path, wifi_config) do
    IO.puts(IO.ANSI.format(["\n", :cyan, :bright, "Burning firmware to #{device_path}...", :reset]))

    if Map.has_key?(wifi_config, :ssid) do
      IO.puts(IO.ANSI.format([:cyan, "Setting WiFi SSID: #{wifi_config.ssid}", :reset]))
    end

    IO.puts(IO.ANSI.format([:yellow, "This may take several minutes. Please do not remove the card.\n", :reset]))

    case NervesBurner.Fwup.burn(firmware_path, device_path, wifi_config) do
      :ok ->
        :ok

      {:error, reason} ->
        {:error, "Failed to burn firmware: #{reason}"}
    end
  end

  defp get_user_choice(prompt, range) do
    case get_user_input(prompt) do
      "" ->
        {:error, :cancelled}

      input ->
        case Integer.parse(input) do
          {num, _} ->
            if num in range do
              {:ok, num}
            else
              IO.puts(IO.ANSI.format([:red, "Invalid choice. Please try again.", :reset]))
              get_user_choice(prompt, range)
            end

          _ ->
            IO.puts(IO.ANSI.format([:red, "Invalid choice. Please try again.", :reset]))
            get_user_choice(prompt, range)
        end
    end
  end

  defp get_user_input(prompt) do
    IO.gets(prompt)
    |> to_string()
    |> String.trim()
  end

  defp format_size(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_000_000_000_000 ->
        "#{Float.round(bytes / 1_000_000_000_000, 2)} TB"

      bytes >= 1_000_000_000 ->
        "#{Float.round(bytes / 1_000_000_000, 2)} GB"

      bytes >= 1_000_000 ->
        "#{Float.round(bytes / 1_000_000, 2)} MB"

      bytes >= 1_000 ->
        "#{Float.round(bytes / 1_000, 2)} KB"

      true ->
        "#{bytes} B"
    end
  end

  defp format_size(_), do: ""
end
