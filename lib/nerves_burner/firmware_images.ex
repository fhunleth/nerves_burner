# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBurner.FirmwareImages do
  @moduledoc """
  Configuration for available firmware images.
  """

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
         fw_asset_pattern: fn platform -> "circuits_quickstart_#{platform}.fw" end,
         image_asset_pattern: fn platform -> "circuits_quickstart_#{platform}.img.gz" end,
         next_steps: """
         For instructions on using Circuits Quickstart, please visit:
         https://github.com/elixir-circuits/circuits_quickstart?tab=readme-ov-file#testing-the-firmware
         """,
         overrides: %{
           "grisp2" => %{
             use_image_asset: true,
             next_steps: """
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
         fw_asset_pattern: fn platform -> "nerves_livebook_#{platform}.fw" end,
         image_asset_pattern: fn platform -> "nerves_livebook_#{platform}.img.gz" end,
         next_steps: """
         For instructions on getting started, please visit:
         https://github.com/nerves-livebook/nerves_livebook#readme
         """,
         overrides: %{
           "grisp2" => %{
             use_image_asset: true,
             next_steps: """
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

  Checks for platform-specific next steps in overrides first, then falls back to default.
  Returns nil if no next steps are defined.
  """
  def next_steps(image_config, platform) do
    # Check for platform overrides first
    case get_platform_override(image_config, platform) do
      %{next_steps: override_steps} ->
        override_steps

      _ ->
        # Fall back to default next steps
        Map.get(image_config, :next_steps)
    end
  end

  @doc """
  Returns the platform-specific override configuration if it exists.
  """
  def get_platform_override(image_config, platform) do
    case Map.get(image_config, :overrides) do
      nil -> nil
      overrides -> Map.get(overrides, platform)
    end
  end
end
