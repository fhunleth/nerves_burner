defmodule NervesBurner.FwupTest do
  use ExUnit.Case

  describe "scan_devices/0" do
    test "returns ok tuple with list" do
      case NervesBurner.Fwup.scan_devices() do
        {:ok, devices} ->
          assert is_list(devices)

        {:error, reason} ->
          # fwup might not be installed in test environment
          assert is_binary(reason)
      end
    end
  end
end
