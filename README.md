# Nerves Burner

A user-friendly Elixir script for downloading and burning pre-built Nerves firmware images to MicroSD cards.

## Features

- Interactive menu-driven interface
- Support for multiple firmware images:
  - Circuits Quickstart
  - Nerves Livebook
- Support for multiple platforms:
  - Raspberry Pi (rpi0, rpi3, rpi4, rpi5)
  - BeagleBone Black (bbb)
  - OSD32MP1 (osd32mp1)
  - MangoPi MQ Pro (mangopi_mq_pro)
- Automatic firmware download from GitHub releases with progress indication
- Automatic MicroSD card detection via fwup
- Safe device selection with confirmation prompts

## Prerequisites

1. **Elixir and Erlang**: Install Elixir (version 1.14 or later) and Erlang/OTP
   - On Ubuntu/Debian: `sudo apt install erlang elixir`
   - On macOS: `brew install elixir`
   - On Windows: Download from [Elixir's website](https://elixir-lang.org/install.html)

2. **fwup**: Install the fwup utility for burning firmware
   - Installation instructions: https://github.com/fwup-home/fwup#installing
   - On Ubuntu/Debian: Download the .deb package from releases
   - On macOS: `brew install fwup`
   - On Windows: Download the installer from releases

3. **GitHub Token** (Optional): If you encounter rate limiting errors from GitHub, set the `GITHUB_TOKEN` or `GITHUB_API_TOKEN` environment variable:
   ```bash
   export GITHUB_TOKEN=your_github_personal_access_token
   # or
   export GITHUB_API_TOKEN=your_github_personal_access_token
   ```
   The token only needs public repository read access. Create one at: https://github.com/settings/tokens

## Building

### Quick Start

The easiest way to build is using the installation script:

```bash
./install.sh
```

This will:
- Check for Elixir and fwup
- Build the executable
- Show instructions for adding to PATH

### Manual Build

Alternatively, build manually:

```bash
# Build the executable
mix escript.build
```

This creates an executable script named `nerves_burner` in the project root.

## Usage

Simply run the executable:

```bash
./nerves_burner
```

The script will guide you through:

1. **Firmware Selection**: Choose from available firmware images
2. **Platform Selection**: Select your target hardware platform
3. **Download**: The firmware will be downloaded from GitHub releases
4. **Device Selection**: Select the MicroSD card to burn (with rescan option)
5. **Confirmation**: Confirm the operation (requires typing "yes")
6. **Burning**: The firmware is written to the card with progress indication

## Example Session

```
=== Nerves Firmware Burner ===

Select a firmware image:

  1. Circuits Quickstart
  2. Nerves Livebook

Enter your choice (1-2): 1

Select a platform:

  1. rpi0
  2. rpi3
  3. rpi4
  4. rpi5
  5. bbb
  6. osd32mp1
  7. mangopi_mq_pro

Enter your choice (1-7): 4

Downloading firmware...
Downloading from: https://github.com/...
✓ Download complete: /tmp/firmware_rpi5_1234567890.fw

Scanning for MicroSD cards...

Available devices:

  1. /dev/sdb (15.93 GB)
  2. Rescan

Enter your choice (1-2): 1

⚠️  WARNING: All data on /dev/sdb will be erased!
Are you sure you want to continue? (yes/no): yes

Burning firmware to /dev/sdb...
This may take several minutes. Please do not remove the card.

[Progress output from fwup...]

✓ Firmware burned successfully!
You can now safely remove the MicroSD card.
```

## Safety Features

- Requires explicit "yes" confirmation before burning
- Shows device size to help identify the correct device
- Provides option to rescan devices
- Clear warnings about data loss

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
