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
         description:
           "Simple examples for GPIO, I2C, SPI and more - perfect for hardware experimentation",
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
         asset_pattern: fn platform -> "circuits_quickstart_#{platform}.fw" end
       }},
      {"Nerves Livebook",
       %{
         repo: "nerves-livebook/nerves_livebook",
         description: "Interactive notebooks for learning Elixir and Nerves on embedded devices",
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
         asset_pattern: fn platform -> "nerves_livebook_#{platform}.fw" end
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
end
