defmodule NervesBurner.Fwup do
  @moduledoc """
  Interface to the fwup tool for burning firmware to MicroSD cards.
  """

  alias NervesBurner.InteractiveShell

  @doc """
  Scans for available devices (MicroSD cards).
  """
  def scan_devices do
    case System.cmd("fwup", ["--detect"], stderr_to_stdout: true) do
      {output, 0} ->
        devices =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(&parse_device_line/1)
          |> Enum.reject(&is_nil/1)

        {:ok, devices}

      {error, _} ->
        if String.contains?(error, "No potential target devices found") do
          {:ok, []}
        else
          {:error, error}
        end
    end
  rescue
    e in ErlangError ->
      if e.original == :enoent do
        {:error,
         "fwup not found. Please install fwup: https://github.com/fwup-home/fwup#installing"}
      else
        {:error, "Failed to run fwup: #{inspect(e)}"}
      end
  end

  @doc """
  Burns firmware to the specified device.
  """
  def burn(firmware_path, device_path) do
    fwup_args = ["-d", device_path, firmware_path]

    {cmd, args} =
      if requires_sudo?() do
        {"sudo", ["fwup" | fwup_args]}
      else
        {"fwup", fwup_args}
      end

    InteractiveShell.shell(cmd, args)
  end

  defp requires_sudo?() do
    case :os.type() do
      {:unix, :linux} -> true
      {:unix, :darwin} -> false
      _ -> false
    end
  end

  # Parse a device line from fwup --detect output
  # Example: "/dev/sdc,15931539456"
  defp parse_device_line(line) do
    case String.split(line, ",", parts: 2) do
      [path, size_str] ->
        size =
          case Integer.parse(size_str) do
            {num, _} -> num
            _ -> nil
          end

        %{path: path, size: size}

      [path] ->
        %{path: path, size: nil}

      _ ->
        nil
    end
  end
end
