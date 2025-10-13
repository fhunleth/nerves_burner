# Fallback Mode Example Output

This document demonstrates the new fallback mode when fwup is not available on the system.

## Scenario: Running Nerves Burner without fwup installed

### User Experience

```
████▄▄    ▐███
█▌  ▀▀██▄▄  ▐█
█▌  ▄▄  ▀▀  ▐█   N  E  R  V  E  S
█▌  ▀▀██▄▄  ▐█
███▌    ▀▀████

Select a firmware image:

  1. Circuits Quickstart
  2. Nerves Livebook

Enter your choice (1-2): 1

Select a platform:

  1. Raspberry Pi Model B (rpi)
  2. Raspberry Pi Zero (rpi0)
  3. Raspberry Pi Zero 2W in 64-bit mode (rpi0_2)
  4. Raspberry Pi 2 (rpi2)
  5. Raspberry Pi 3 (rpi3)
  6. Raspberry Pi Zero 2W or 3A in 32-bit mode (rpi3a)
  7. Raspberry Pi 4 (rpi4)
  8. Raspberry Pi 5 (rpi5)
  9. Beaglebone Black and other Beaglebone variants (bbb)
  10. OSD32MP1 (osd32mp1)
  11. NPI i.MX6 ULL (npi_imx6ull)
  12. GRiSP 2 (grisp2)
  13. MangoPi MQ Pro (mangopi_mq_pro)

Enter your choice (1-13): 7

Downloading firmware...

Note: fwup is not available. Downloading alternative format: circuits_quickstart_rpi4.zip

Downloading from: https://github.com/elixir-circuits/circuits_quickstart/releases/download/v1.0.0/circuits_quickstart_rpi4.zip
[████████████████████████████████████████] 100% (456.7 MB)
✓ File saved to: /tmp/firmware_rpi4_1234567890.zip

✓ Firmware downloaded successfully!

⚠️  Note: fwup is not installed on this system.

File location: /tmp/firmware_rpi4_1234567890.zip

You can burn this image to a MicroSD card using:
1. Extract the ZIP file to get the .img file
2. Use one of the following tools:

  • Etcher (Recommended - Cross-platform GUI tool)
    Download from: https://etcher.balena.io/

  • dd (Linux/macOS command-line tool)
    Example: sudo dd if=<img-file> of=/dev/sdX bs=4M status=progress
    ⚠️  Warning: Double-check the device path (of=...) to avoid data loss!

  • Win32 Disk Imager (Windows)
    Download from: https://sourceforge.net/projects/win32diskimager/

For more information about fwup, visit: https://github.com/fwup-home/fwup#installing
```

## Key Features of Fallback Mode

1. **Automatic Detection**: The tool automatically detects if fwup is not available
2. **Alternative Formats**: Downloads zip or img.gz files instead of .fw files
3. **Clear Instructions**: Provides step-by-step guidance for manual burning
4. **Multiple Tools**: Suggests multiple burning tools based on user's platform
5. **File Path Display**: Shows exact location of downloaded file for easy access

## Supported Alternative Formats

The tool tries to find alternative formats in this order:
1. `.zip` files
2. `.img.gz` files
3. `.img` files

If none of these formats are available in the GitHub release, the tool will display an error message suggesting to install fwup.

## Burning Tools Recommended

### Etcher (Recommended)
- **Platform**: Windows, macOS, Linux
- **Interface**: User-friendly GUI
- **Download**: https://etcher.balena.io/
- **Best for**: Beginners and users who prefer graphical interfaces

### dd
- **Platform**: Linux, macOS
- **Interface**: Command-line
- **Best for**: Advanced users comfortable with terminal
- **Usage**: `sudo dd if=image.img of=/dev/sdX bs=4M status=progress`

### Win32 Disk Imager
- **Platform**: Windows
- **Interface**: GUI
- **Download**: https://sourceforge.net/projects/win32diskimager/
- **Best for**: Windows users who prefer a simple GUI tool
