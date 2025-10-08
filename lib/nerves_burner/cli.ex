defmodule NervesBurner.CLI do
  @moduledoc """
  Main CLI entry point for the Nerves Burner application.
  """

  def main(_args) do
    IO.puts("\n=== Nerves Firmware Burner ===\n")

    with {:ok, image_config} <- select_firmware_image(),
         {:ok, platform} <- select_platform(image_config),
         {:ok, wifi_config} <- get_wifi_credentials(),
         {:ok, firmware_path} <- download_firmware(image_config, platform),
         {:ok, device} <- select_device(),
         :ok <- burn_firmware(firmware_path, device, wifi_config) do
      IO.puts("\n✓ Firmware burned successfully!")
      IO.puts("You can now safely remove the MicroSD card.\n")
    else
      {:error, :cancelled} ->
        IO.puts("\nOperation cancelled by user.\n")
        System.halt(0)

      {:error, reason} ->
        IO.puts("\n✗ Error: #{reason}\n")
        System.halt(1)
    end
  end

  defp select_firmware_image do
    IO.puts("Select a firmware image:\n")

    images = NervesBurner.FirmwareImages.list()

    images
    |> Enum.with_index(1)
    |> Enum.each(fn {{name, _config}, index} ->
      IO.puts("  #{index}. #{name}")
    end)

    case get_user_choice("\nEnter your choice (1-#{length(images)}): ", 1..length(images)) do
      {:ok, choice} ->
        {_name, config} = Enum.at(images, choice - 1)
        {:ok, config}

      error ->
        error
    end
  end

  defp select_platform(image_config) do
    platforms = image_config.platforms

    IO.puts("\nSelect a platform:\n")

    platforms
    |> Enum.with_index(1)
    |> Enum.each(fn {platform, index} ->
      IO.puts("  #{index}. #{platform}")
    end)

    case get_user_choice("\nEnter your choice (1-#{length(platforms)}): ", 1..length(platforms)) do
      {:ok, choice} ->
        {:ok, Enum.at(platforms, choice - 1)}

      error ->
        error
    end
  end

  defp get_wifi_credentials do
    IO.puts("\nWould you like to configure WiFi credentials?")
    IO.puts("(This is supported by Circuits Quickstart and Nerves Livebook firmware)\n")

    case get_user_input("Configure WiFi? (y/n): ") do
      input when input in ["y", "Y", "yes", "Yes", "YES"] ->
        get_wifi_details()

      _ ->
        {:ok, %{}}
    end
  end

  defp get_wifi_details do
    ssid = get_user_input("\nEnter WiFi SSID: ")

    if ssid == "" do
      IO.puts("WiFi SSID cannot be empty. Skipping WiFi configuration.")
      {:ok, %{}}
    else
      passphrase = get_user_input("Enter WiFi passphrase: ")

      if passphrase == "" do
        IO.puts("WiFi passphrase cannot be empty. Skipping WiFi configuration.")
        {:ok, %{}}
      else
        {:ok, %{ssid: ssid, passphrase: passphrase}}
      end
    end
  end

  defp download_firmware(image_config, platform) do
    IO.puts("\nDownloading firmware...")

    case NervesBurner.Downloader.download(image_config, platform) do
      {:ok, path} ->
        IO.puts("✓ Download complete: #{path}\n")
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
        IO.puts("\nNo MicroSD cards detected.")

        case get_user_input("\nWould you like to rescan? (y/n): ") do
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
    IO.puts("\nScanning for MicroSD cards...")

    case NervesBurner.Fwup.scan_devices() do
      {:ok, devices} ->
        {:ok, devices}

      {:error, reason} ->
        {:error, "Failed to scan devices: #{reason}"}
    end
  end

  defp choose_device(devices) do
    IO.puts("\nAvailable devices:\n")

    devices
    |> Enum.with_index(1)
    |> Enum.each(fn {device, index} ->
      size_info = if device.size, do: " (#{format_size(device.size)})", else: ""
      IO.puts("  #{index}. #{device.path}#{size_info}")
    end)

    IO.puts("  #{length(devices) + 1}. Rescan")

    case get_user_choice(
           "\nEnter your choice (1-#{length(devices) + 1}): ",
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
    IO.puts("\n⚠️  WARNING: All data on #{device.path} will be erased!")

    case get_user_input("Are you sure you want to continue? (yes/no): ") do
      input when input in ["yes", "Yes", "YES"] ->
        {:ok, device.path}

      _ ->
        IO.puts("\nDevice selection cancelled.")
        select_device()
    end
  end

  defp burn_firmware(firmware_path, device_path, wifi_config) do
    IO.puts("\nBurning firmware to #{device_path}...")

    if Map.has_key?(wifi_config, :ssid) do
      IO.puts("Setting WiFi SSID: #{wifi_config.ssid}")
    end

    IO.puts("This may take several minutes. Please do not remove the card.\n")

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
              IO.puts("Invalid choice. Please try again.")
              get_user_choice(prompt, range)
            end

          _ ->
            IO.puts("Invalid choice. Please try again.")
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
