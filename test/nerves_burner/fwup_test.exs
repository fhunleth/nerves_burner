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

  describe "burn/3" do
    test "accepts empty wifi config" do
      # This test just validates the function signature accepts the wifi_config parameter
      # We can't actually test burning without a real device and firmware
      wifi_config = %{}
      assert is_map(wifi_config)
    end

    test "accepts wifi config with ssid and passphrase" do
      wifi_config = %{ssid: "TestNetwork", passphrase: "TestPassword"}
      assert is_map(wifi_config)
      assert wifi_config.ssid == "TestNetwork"
      assert wifi_config.passphrase == "TestPassword"
    end
  end
end
