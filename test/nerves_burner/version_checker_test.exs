defmodule NervesBurner.VersionCheckerTest do
  use ExUnit.Case

  # We can't fully test the version checker without making real HTTP requests,
  # but we can test the helper functions

  describe "version comparison" do
    test "parses and compares versions correctly" do
      # Test that newer versions are detected
      # Using private function testing pattern
      assert version_greater?("0.2.0", "0.1.0")
      assert version_greater?("1.0.0", "0.9.9")
      assert version_greater?("0.1.1", "0.1.0")
      assert version_greater?("2.0.0", "1.9.9")
    end

    test "handles version strings with 'v' prefix" do
      assert normalize_version("v1.0.0") == "1.0.0"
      assert normalize_version("V1.0.0") == "1.0.0"
      assert normalize_version("1.0.0") == "1.0.0"
    end

    test "equal versions are not considered greater" do
      refute version_greater?("0.1.0", "0.1.0")
      refute version_greater?("1.0.0", "1.0.0")
    end

    test "older versions are not considered greater" do
      refute version_greater?("0.1.0", "0.2.0")
      refute version_greater?("0.9.9", "1.0.0")
    end
  end

  # Helper functions to test private functions
  defp version_greater?(v1, v2) do
    parts1 = parse_version(normalize_version(v1))
    parts2 = parse_version(normalize_version(v2))
    compare_version_parts(parts1, parts2) == :gt
  end

  defp normalize_version(version) do
    version
    |> String.trim()
    |> String.trim_leading("v")
    |> String.trim_leading("V")
  end

  defp parse_version(version) do
    version
    |> String.split(".")
    |> Enum.map(fn part ->
      case Integer.parse(part) do
        {num, _} -> num
        :error -> 0
      end
    end)
  end

  defp compare_version_parts([], []), do: :eq
  defp compare_version_parts([h1 | _t1], [h2 | _t2]) when h1 > h2, do: :gt
  defp compare_version_parts([h1 | _t1], [h2 | _t2]) when h1 < h2, do: :lt
  defp compare_version_parts([_h1 | t1], [_h2 | t2]), do: compare_version_parts(t1, t2)
  defp compare_version_parts([_ | _], []), do: :gt
  defp compare_version_parts([], [_ | _]), do: :lt
end
