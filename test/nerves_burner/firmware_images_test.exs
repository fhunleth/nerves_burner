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
  end
end
