# Next Steps Feature

## Overview

After successfully burning firmware to a MicroSD card, the Nerves Burner now displays customizable next steps to help users get started with their newly flashed device.

## How It Works

### 1. Firmware Configuration

Each firmware image in `lib/nerves_burner/firmware_images.ex` can include a `next_steps` configuration with:

- **Default steps**: Apply to all platforms
- **Platform-specific steps**: Override the default for specific boards

### 2. Configuration Format

```elixir
%{
  repo: "example/repo",
  description: "Example firmware",
  # ... other config ...
  next_steps: %{
    # Default steps shown for all platforms
    default: """
    1. Insert the MicroSD card into your device
    2. Power on the device
    3. Connect to the device
    """,
    # Optional platform-specific overrides
    platforms: %{
      "rpi" => """
      1. Insert the MicroSD card into your Raspberry Pi
      2. Power on via micro USB
      3. Wait 30-60 seconds for boot
      4. Connect via SSH to nerves.local
      """,
      "bbb" => """
      1. Insert the MicroSD card into your BeagleBone Black
      2. Power on the device
      3. Connect via USB or SSH
      """
    }
  }
}
```

### 3. Display Logic

The `next_steps/2` function in `NervesBurner.FirmwareImages`:
1. Checks if the firmware has next_steps defined
2. Looks for platform-specific steps first
3. Falls back to default steps if platform-specific aren't available
4. Returns `nil` if no next_steps are configured

### 4. User Experience

After successfully burning firmware:

```
✓ Firmware burned successfully!
You can now safely remove the MicroSD card.

📋 Next Steps:

1. Insert the MicroSD card into your Raspberry Pi
2. Power on the Raspberry Pi (connect to power via micro USB)
3. Wait for the device to boot (about 30-60 seconds)
4. Connect via serial console (pins 8 & 10) or SSH to nerves.local
5. Default credentials: username 'root', no password required
6. Try the examples in /root/circuits_quickstart
```

## Example Implementations

### Circuits Quickstart
- Provides platform-specific steps for `rpi` and `rpi0`
- Falls back to generic steps for other platforms
- Includes connection and example usage instructions

### Nerves Livebook
- Uses default steps for all platforms
- Focuses on web browser access to Livebook interface
- Emphasizes WiFi connectivity

## Adding Next Steps to New Firmware

When adding a new firmware image, include the `next_steps` field:

```elixir
{"My Firmware",
 %{
   repo: "user/repo",
   description: "...",
   platforms: ["rpi", "rpi4"],
   asset_pattern: fn platform -> "my_firmware_#{platform}.fw" end,
   next_steps: %{
     default: """
     1. Your default steps here
     2. ...
     """
   }
 }}
```

## Benefits

1. **User-friendly**: Guides users on what to do after burning
2. **Customizable**: Different firmware can have different instructions
3. **Board-specific**: Platforms can have tailored instructions
4. **Maintainable**: All instructions centralized in one place
5. **Extensible**: Easy to add new platforms or update existing ones

## Testing

Comprehensive tests in `test/nerves_burner/firmware_images_test.exs` verify:
- The `next_steps/2` function handles all cases correctly
- Platform-specific steps are returned when available
- Default fallback works properly
- Both firmware images have next steps defined
