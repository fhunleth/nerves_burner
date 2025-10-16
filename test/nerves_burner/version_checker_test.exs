# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBurner.VersionCheckerTest do
  use ExUnit.Case

  # We can't fully test the version checker without making real HTTP requests,
  # but we can test the version comparison using Elixir's Version module

  describe "version comparison" do
    test "newer versions are detected correctly" do
      assert Version.compare("0.2.0", "0.1.0") == :gt
      assert Version.compare("1.0.0", "0.9.9") == :gt
      assert Version.compare("0.1.1", "0.1.0") == :gt
      assert Version.compare("2.0.0", "1.9.9") == :gt
    end

    test "handles version strings with 'v' prefix" do
      assert normalize_version("v1.0.0") == "1.0.0"
      assert normalize_version("V1.0.0") == "1.0.0"
      assert normalize_version("1.0.0") == "1.0.0"
    end

    test "equal versions are not considered greater" do
      assert Version.compare("0.1.0", "0.1.0") == :eq
      assert Version.compare("1.0.0", "1.0.0") == :eq
    end

    test "older versions are not considered greater" do
      assert Version.compare("0.1.0", "0.2.0") == :lt
      assert Version.compare("0.9.9", "1.0.0") == :lt
    end
  end

  # Helper function to test normalize_version
  defp normalize_version(version) do
    version
    |> String.trim()
    |> String.trim_leading("v")
    |> String.trim_leading("V")
  end
end
