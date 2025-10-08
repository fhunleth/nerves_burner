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
         platforms: ["rpi0", "rpi3", "rpi4", "rpi5", "bbb", "osd32mp1", "mangopi_mq_pro"],
         asset_pattern: fn platform -> "circuits_quickstart_#{platform}.fw" end
       }},
      {"Nerves Livebook",
       %{
         repo: "nerves-livebook/nerves_livebook",
         platforms: ["rpi0", "rpi3", "rpi4", "rpi5", "bbb", "osd32mp1", "mangopi_mq_pro"],
         asset_pattern: fn platform -> "nerves_livebook_#{platform}.fw" end
       }}
    ]
  end
end
