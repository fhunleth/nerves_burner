# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBurner.OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias NervesBurner.Output

  describe "section/1" do
    test "prints section header with cyan bright formatting" do
      output = capture_io(fn -> Output.section("Test Section") end)
      assert output =~ "Test Section"
    end
  end

  describe "success/1" do
    test "prints success message with green bright formatting" do
      output = capture_io(fn -> Output.success("Success message") end)
      assert output =~ "Success message"
    end
  end

  describe "info/1" do
    test "prints info message with cyan formatting" do
      output = capture_io(fn -> Output.info("Info message") end)
      assert output =~ "Info message"
    end
  end

  describe "warning/1" do
    test "prints warning message with yellow formatting" do
      output = capture_io(fn -> Output.warning("Warning message") end)
      assert output =~ "Warning message"
    end
  end

  describe "error/1" do
    test "prints error message with red bright formatting" do
      output = capture_io(fn -> Output.error("Error message") end)
      assert output =~ "Error message"
    end
  end

  describe "menu_option/2" do
    test "prints menu option with number and text" do
      output = capture_io(fn -> Output.menu_option(1, "Option text") end)
      assert output =~ "1."
      assert output =~ "Option text"
    end

    test "accepts string number" do
      output = capture_io(fn -> Output.menu_option("?", "Help option") end)
      assert output =~ "?."
      assert output =~ "Help option"
    end
  end

  describe "menu_option_with_parts/3" do
    test "prints menu option with main and secondary text" do
      output = capture_io(fn -> Output.menu_option_with_parts(1, "Main", "Secondary") end)
      assert output =~ "1."
      assert output =~ "Main"
      assert output =~ "Secondary"
    end

    test "handles nil secondary text" do
      output = capture_io(fn -> Output.menu_option_with_parts(1, "Main", nil) end)
      assert output =~ "1."
      assert output =~ "Main"
    end
  end

  describe "prompt/1" do
    test "returns formatted prompt without printing" do
      result = Output.prompt("Enter choice: ")
      assert is_list(result)
    end
  end

  describe "critical_warning/1" do
    test "prints critical warning with warning symbol" do
      output = capture_io(fn -> Output.critical_warning("Critical warning") end)
      assert output =~ "⚠️  WARNING:"
      assert output =~ "Critical warning"
    end
  end

  describe "labeled/3" do
    test "prints labeled output with default cyan color" do
      output = capture_io(fn -> Output.labeled("Label: ", "Value") end)
      assert output =~ "Label:"
      assert output =~ "Value"
    end

    test "prints labeled output with custom color" do
      output = capture_io(fn -> Output.labeled("Label: ", "Value", :green) end)
      assert output =~ "Label:"
      assert output =~ "Value"
    end
  end
end
