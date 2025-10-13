defmodule NervesBurner.FirmwareImagesTest do
  use ExUnit.Case
  doctest NervesBurner.FirmwareImages

  describe "list/0" do
    test "returns a list of firmware images" do
      images = NervesBurner.FirmwareImages.list()

      assert is_list(images)
      assert length(images) > 0
    end

    test "each image has a name and config" do
      images = NervesBurner.FirmwareImages.list()

      Enum.each(images, fn {name, config} ->
        assert is_binary(name)
        assert is_map(config)
        assert Map.has_key?(config, :repo)
        assert Map.has_key?(config, :platforms)
        assert Map.has_key?(config, :asset_pattern)
        assert Map.has_key?(config, :description)
        assert Map.has_key?(config, :long_description)
        assert Map.has_key?(config, :url)
      end)
    end

    test "includes Circuits Quickstart" do
      images = NervesBurner.FirmwareImages.list()
      names = Enum.map(images, fn {name, _} -> name end)

      assert "Circuits Quickstart" in names
    end

    test "includes Nerves Livebook" do
      images = NervesBurner.FirmwareImages.list()
      names = Enum.map(images, fn {name, _} -> name end)

      assert "Nerves Livebook" in names
    end

    test "each image has valid platforms" do
      images = NervesBurner.FirmwareImages.list()

      Enum.each(images, fn {_name, config} ->
        assert is_list(config.platforms)
        assert length(config.platforms) > 0
        Enum.each(config.platforms, &assert(is_binary(&1)))
      end)
    end

    test "includes all expected platforms" do
      images = NervesBurner.FirmwareImages.list()

      expected_platforms = [
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
      ]

      Enum.each(images, fn {_name, config} ->
        Enum.each(expected_platforms, fn platform ->
          assert platform in config.platforms,
                 "Platform #{platform} should be in the platforms list"
        end)
      end)
    end

    test "each image has description and url" do
      images = NervesBurner.FirmwareImages.list()

      Enum.each(images, fn {_name, config} ->
        assert is_binary(config.description)
        assert String.length(config.description) > 0
        assert is_binary(config.long_description)
        assert String.length(config.long_description) > 0
        assert is_binary(config.url)
        assert String.starts_with?(config.url, "https://")
      end)
    end

    test "Circuits Quickstart has proper description and url" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Circuits Quickstart" end)

      assert config.description =~ ~r/GPIO|I2C|SPI/i
      assert config.long_description =~ ~r/GPIO|I2C|SPI/i
      assert config.url == "https://github.com/elixir-circuits/circuits_quickstart"
    end

    test "Nerves Livebook has proper description and url" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Nerves Livebook" end)

      assert config.description =~ ~r/notebook|learning|Elixir|Nerves/i
      assert config.long_description =~ ~r/Livebook|interactive/i
      assert config.url == "https://github.com/nerves-livebook/nerves_livebook"
    end
  end

  describe "platform_name/1" do
    test "returns friendly names for known platforms" do
      assert NervesBurner.FirmwareImages.platform_name("rpi") ==
               "Raspberry Pi Model B (rpi)"

      assert NervesBurner.FirmwareImages.platform_name("rpi0") ==
               "Raspberry Pi Zero (rpi0)"

      assert NervesBurner.FirmwareImages.platform_name("rpi0_2") ==
               "Raspberry Pi Zero 2W in 64-bit mode (rpi0_2)"

      assert NervesBurner.FirmwareImages.platform_name("rpi3a") ==
               "Raspberry Pi Zero 2W or 3A in 32-bit mode (rpi3a)"

      assert NervesBurner.FirmwareImages.platform_name("bbb") ==
               "Beaglebone Black and other Beaglebone variants (bbb)"

      assert NervesBurner.FirmwareImages.platform_name("grisp2") ==
               "GRiSP 2 (grisp2)"
    end

    test "returns platform code for unknown platforms" do
      assert NervesBurner.FirmwareImages.platform_name("unknown") == "unknown"
    end
  end

  describe "next_steps/2" do
    test "returns nil for image config without next_steps" do
      config = %{repo: "test/test", platforms: ["rpi"]}
      assert NervesBurner.FirmwareImages.next_steps(config, "rpi") == nil
    end

    test "returns default next steps when no platform-specific steps exist" do
      config = %{
        next_steps: %{
          default: "Default steps here"
        }
      }

      assert NervesBurner.FirmwareImages.next_steps(config, "rpi") == "Default steps here"
    end

    test "returns platform-specific next steps when available" do
      config = %{
        next_steps: %{
          default: "Default steps",
          platforms: %{
            "rpi" => "RPi specific steps"
          }
        }
      }

      assert NervesBurner.FirmwareImages.next_steps(config, "rpi") == "RPi specific steps"
    end

    test "falls back to default when platform-specific steps not found" do
      config = %{
        next_steps: %{
          default: "Default steps",
          platforms: %{
            "rpi" => "RPi specific steps"
          }
        }
      }

      assert NervesBurner.FirmwareImages.next_steps(config, "bbb") == "Default steps"
    end

    test "Circuits Quickstart has next steps defined" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Circuits Quickstart" end)

      assert Map.has_key?(config, :next_steps)
      assert Map.has_key?(config.next_steps, :default)
      assert is_binary(config.next_steps.default)
      assert String.length(config.next_steps.default) > 0
    end

    test "Nerves Livebook has next steps defined" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Nerves Livebook" end)

      assert Map.has_key?(config, :next_steps)
      assert Map.has_key?(config.next_steps, :default)
      assert is_binary(config.next_steps.default)
      assert String.length(config.next_steps.default) > 0
    end

    test "next_steps for Circuits Quickstart returns proper steps for rpi platform" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Circuits Quickstart" end)

      steps = NervesBurner.FirmwareImages.next_steps(config, "rpi")
      assert is_binary(steps)
      assert steps =~ ~r/Raspberry Pi/i
    end

    test "next_steps for Circuits Quickstart falls back to default for platforms without specific steps" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Circuits Quickstart" end)

      steps = NervesBurner.FirmwareImages.next_steps(config, "bbb")
      assert is_binary(steps)
      assert steps == config.next_steps.default
    end

    test "next_steps for Nerves Livebook returns default steps" do
      images = NervesBurner.FirmwareImages.list()
      {_name, config} = Enum.find(images, fn {name, _} -> name == "Nerves Livebook" end)

      steps = NervesBurner.FirmwareImages.next_steps(config, "rpi4")
      assert is_binary(steps)
      assert steps =~ ~r/Livebook/i
    end
  end
end
