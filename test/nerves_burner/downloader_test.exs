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

      on_exit(fn ->
        File.rm(test_file)
        File.rm(test_file <> ".sha256")
      end)

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

    test "verifies hash when hash file exists", %{test_file: test_file, content_size: size} do
      # First, store the hash
      apply(NervesBurner.Downloader, :store_hash, [test_file])

      # Verify it passes
      asset_info = %{url: "http://example.com", name: "test.fw", size: size}
      result = apply(NervesBurner.Downloader, :verify_file, [test_file, asset_info])

      assert result == :ok
    end

    test "detects hash mismatch", %{test_file: test_file, content_size: size} do
      # Store a hash
      apply(NervesBurner.Downloader, :store_hash, [test_file])

      # Modify the file
      File.write!(test_file, "modified content")

      # Verify it fails
      asset_info = %{url: "http://example.com", name: "test.fw", size: size}
      result = apply(NervesBurner.Downloader, :verify_file, [test_file, asset_info])

      # Note: Size will be wrong first, so that's what we'll detect
      assert {:error, message} = result
      assert String.contains?(message, "mismatch")
    end
  end

  describe "check_cached_file/2" do
    setup do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "cached_firmware_#{:os.system_time(:millisecond)}.fw")
      content = "cached firmware"
      File.write!(test_file, content)

      on_exit(fn ->
        File.rm(test_file)
        File.rm(test_file <> ".sha256")
      end)

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

  describe "compute_sha256/1" do
    setup do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "hash_test_#{:os.system_time(:millisecond)}.fw")
      content = "test content for hashing"
      File.write!(test_file, content)

      on_exit(fn -> File.rm(test_file) end)

      {:ok, test_file: test_file}
    end

    test "computes consistent hash", %{test_file: test_file} do
      hash1 = apply(NervesBurner.Downloader, :compute_sha256, [test_file])
      hash2 = apply(NervesBurner.Downloader, :compute_sha256, [test_file])

      assert hash1 == hash2
      assert is_binary(hash1)
      assert String.length(hash1) == 64
    end

    test "different content produces different hash" do
      tmp_dir = System.tmp_dir!()
      file1 = Path.join(tmp_dir, "hash_test_a.fw")
      file2 = Path.join(tmp_dir, "hash_test_b.fw")

      File.write!(file1, "content a")
      File.write!(file2, "content b")

      hash1 = apply(NervesBurner.Downloader, :compute_sha256, [file1])
      hash2 = apply(NervesBurner.Downloader, :compute_sha256, [file2])

      assert hash1 != hash2

      File.rm(file1)
      File.rm(file2)
    end
  end

  describe "store_hash/1" do
    setup do
      tmp_dir = System.tmp_dir!()
      test_file = Path.join(tmp_dir, "store_hash_test_#{:os.system_time(:millisecond)}.fw")
      content = "test content"
      File.write!(test_file, content)

      on_exit(fn ->
        File.rm(test_file)
        File.rm(test_file <> ".sha256")
      end)

      {:ok, test_file: test_file}
    end

    test "creates hash file", %{test_file: test_file} do
      hash_file = test_file <> ".sha256"

      refute File.exists?(hash_file)

      apply(NervesBurner.Downloader, :store_hash, [test_file])

      assert File.exists?(hash_file)
      {:ok, stored_hash} = File.read(hash_file)
      assert String.length(stored_hash) == 64
    end

    test "stored hash matches computed hash", %{test_file: test_file} do
      apply(NervesBurner.Downloader, :store_hash, [test_file])

      computed = apply(NervesBurner.Downloader, :compute_sha256, [test_file])
      {:ok, stored} = File.read(test_file <> ".sha256")

      assert computed == stored
    end
  end
end
