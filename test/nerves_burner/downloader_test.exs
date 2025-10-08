defmodule NervesBurner.DownloaderTest do
  use ExUnit.Case

  # We can't fully test the downloader without making real HTTP requests,
  # but we can test the helper functions

  describe "get_cache_dir/0" do
    test "returns a cache directory path" do
      # Access the private function via reflection
      cache_dir = apply(NervesBurner.Downloader, :get_cache_dir, [])

      assert is_binary(cache_dir)
      assert String.length(cache_dir) > 0
    end

    test "cache directory contains 'nerves_burner'" do
      cache_dir = apply(NervesBurner.Downloader, :get_cache_dir, [])

      assert String.contains?(cache_dir, "nerves_burner")
    end

    test "cache directory is OS-appropriate" do
      cache_dir = apply(NervesBurner.Downloader, :get_cache_dir, [])

      case :os.type() do
        {:unix, :darwin} ->
          assert String.contains?(cache_dir, "Library/Caches")

        {:unix, _} ->
          # Should contain either XDG_CACHE_HOME or .cache
          assert String.contains?(cache_dir, "cache") or
                   String.contains?(cache_dir, "Cache")

        {:win32, _} ->
          assert String.contains?(cache_dir, "AppData") or
                   String.contains?(cache_dir, "Local")
      end
    end
  end

  describe "verify_file/2" do
    setup do
      # Create a temporary test file
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "test_firmware_#{:os.system_time(:millisecond)}.fw")
      content = "test firmware content"
      File.write!(test_file, content)

      on_exit(fn -> File.rm(test_file) end)

      {:ok, test_file: test_file, content_size: byte_size(content)}
    end

    test "returns :ok when size matches", %{test_file: test_file, content_size: size} do
      asset_info = %{url: "http://example.com", name: "test.fw", size: size}
      result = apply(NervesBurner.Downloader, :verify_file, [test_file, asset_info])

      assert result == :ok
    end

    test "returns error when size does not match", %{test_file: test_file} do
      asset_info = %{url: "http://example.com", name: "test.fw", size: 999_999}
      result = apply(NervesBurner.Downloader, :verify_file, [test_file, asset_info])

      assert {:error, message} = result
      assert String.contains?(message, "Size mismatch")
    end

    test "returns :ok when size is nil", %{test_file: test_file} do
      asset_info = %{url: "http://example.com", name: "test.fw", size: nil}
      result = apply(NervesBurner.Downloader, :verify_file, [test_file, asset_info])

      assert result == :ok
    end
  end

  describe "check_cached_file/2" do
    setup do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "cached_firmware_#{:os.system_time(:millisecond)}.fw")
      content = "cached firmware"
      File.write!(test_file, content)

      on_exit(fn -> File.rm(test_file) end)

      {:ok, test_file: test_file, content_size: byte_size(content)}
    end

    test "returns :valid for matching cached file", %{
      test_file: test_file,
      content_size: size
    } do
      asset_info = %{url: "http://example.com", name: "test.fw", size: size}
      result = apply(NervesBurner.Downloader, :check_cached_file, [test_file, asset_info])

      assert result == :valid
    end

    test "returns :invalid for non-matching cached file", %{test_file: test_file} do
      asset_info = %{url: "http://example.com", name: "test.fw", size: 999_999}
      result = apply(NervesBurner.Downloader, :check_cached_file, [test_file, asset_info])

      assert result == :invalid
    end

    test "returns :not_found for non-existent file" do
      non_existent = "/tmp/does_not_exist_#{:os.system_time(:millisecond)}.fw"
      asset_info = %{url: "http://example.com", name: "test.fw", size: 1000}
      result = apply(NervesBurner.Downloader, :check_cached_file, [non_existent, asset_info])

      assert result == :not_found
    end
  end
end
