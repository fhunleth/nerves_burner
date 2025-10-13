defmodule NervesBurner.FirmwareImages do
  @moduledoc """
  Configuration for available firmware images.
  """

  # Platform-specific configurations
  # These define special behaviors for certain platforms
  @platform_configs %{
    "grisp2" => %{
      # GRiSP2 stores firmware on eMMC and requires img.gz format
      force_alternative_format: true,
      alternative_pattern: fn base_name -> "#{base_name}.img.gz" end,
      message: "GRiSP2 requires img.gz format for eMMC installation"
    }
  }

  @doc """
  Returns platform-specific configuration if it exists.
  """
  def get_platform_config(platform) do
    Map.get(@platform_configs, platform)
  end

  @doc """
  Lists all available firmware images with their configurations.
  """
  def list do
    [
      {"Circuits Quickstart",
       %{
         repo: "elixir-circuits/circuits_quickstart",
         description: "Simple examples for GPIO, I2C, SPI and more",
         long_description: """
         A collection of ready-to-run examples demonstrating how to use Elixir Circuits libraries for hardware interaction. Perfect for learning and experimentation with:
         - GPIO (General Purpose Input/Output) pins
         - I2C communication with sensors and peripherals
         - SPI (Serial Peripheral Interface) devices
         - PWM (Pulse Width Modulation) for controlling LEDs and motors

         Great starting point for anyone new to hardware programming with Nerves.
         """,
         url: "https://github.com/elixir-circuits/circuits_quickstart",
         platforms: [
           "rpi",
           "rpi0",
           "rpi0_2",
           "rpi2",
           "rpi3",
           "rpi3a",
           "rpi4",
           "rpi5",
           "bbb",
           "osd32mp1",
           "npi_imx6ull",
           "grisp2",
           "mangopi_mq_pro"
         ],
         asset_pattern: fn platform -> "circuits_quickstart_#{platform}.fw" end,
         next_steps: %{
           default: """
           For instructions on using Circuits Quickstart, please visit:
           https://github.com/elixir-circuits/circuits_quickstart?tab=readme-ov-file#testing-the-firmware
           """,
           platforms: %{
             "grisp2" => """
             For GRiSP 2 installation instructions, please visit:
             https://github.com/elixir-circuits/circuits_quickstart?tab=readme-ov-file#grisp-2-installation
             """
           }
         }
       }},
      {"Nerves Livebook",
       %{
         repo: "nerves-livebook/nerves_livebook",
         description: "Interactive notebooks for learning Elixir and Nerves",
         long_description: """
         Run Livebook directly on your embedded device for an interactive development and learning experience. Features include:
         - Pre-installed notebooks with Nerves examples and tutorials
         - Interactive code execution and visualization
         - Built-in documentation and learning resources
         - WiFi configuration support for easy network access
         - Explore hardware capabilities through live coding

         Ideal for learning Elixir, experimenting with Nerves, or building prototypes interactively.
         """,
         url: "https://github.com/nerves-livebook/nerves_livebook",
         platforms: [
           "rpi",
           "rpi0",
           "rpi0_2",
           "rpi2",
           "rpi3",
           "rpi3a",
           "rpi4",
           "rpi5",
           "bbb",
           "osd32mp1",
           "npi_imx6ull",
           "grisp2",
           "mangopi_mq_pro"
         ],
         asset_pattern: fn platform -> "nerves_livebook_#{platform}.fw" end,
         next_steps: %{
           # Default next steps for all platforms
           default: """
           For instructions on getting started, please visit:
           https://github.com/nerves-livebook/nerves_livebook#readme
           """,
           platforms: %{
             "grisp2" => """
             For GRiSP 2 installation instructions, please visit:
             https://github.com/nerves-livebook/nerves_livebook?tab=readme-ov-file#grisp-2-installation
             """
           }
         }
       }}
    ]
  end

  @doc """
  Returns the friendly name for a platform code.
  """
  def platform_name(platform) do
    case platform do
      "rpi" -> "Raspberry Pi Model B (rpi)"
      "rpi0" -> "Raspberry Pi Zero (rpi0)"
      "rpi0_2" -> "Raspberry Pi Zero 2W in 64-bit mode (rpi0_2)"
      "rpi2" -> "Raspberry Pi 2 (rpi2)"
      "rpi3" -> "Raspberry Pi 3 (rpi3)"
      "rpi3a" -> "Raspberry Pi Zero 2W or 3A in 32-bit mode (rpi3a)"
      "rpi4" -> "Raspberry Pi 4 (rpi4)"
      "rpi5" -> "Raspberry Pi 5 (rpi5)"
      "bbb" -> "Beaglebone Black and other Beaglebone variants (bbb)"
      "osd32mp1" -> "OSD32MP1 (osd32mp1)"
      "npi_imx6ull" -> "NPI i.MX6 ULL (npi_imx6ull)"
      "grisp2" -> "GRiSP 2 (grisp2)"
      "mangopi_mq_pro" -> "MangoPi MQ Pro (mangopi_mq_pro)"
      _ -> platform
    end
  end

  @doc """
  Returns the next steps for a given firmware image and platform.

  Checks for platform-specific next steps first, then falls back to the default.
  Returns nil if no next steps are defined.
  """
  def next_steps(image_config, platform) do
    case Map.get(image_config, :next_steps) do
      nil ->
        nil

      next_steps_config ->
        # First check for platform-specific next steps
        platform_steps =
          case Map.get(next_steps_config, :platforms) do
            nil -> nil
            platforms_map -> Map.get(platforms_map, platform)
          end

        # Fall back to default if no platform-specific steps
        platform_steps || Map.get(next_steps_config, :default)
    end
  end
end
