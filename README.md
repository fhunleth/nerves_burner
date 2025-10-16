# Nerves Burner

A user-friendly tool for downloading and burning pre-built Nerves firmware images to MicroSD cards.

## Features

- **Automatic version checking** and self-updating
- Interactive menu-driven interface
- Support for multiple firmware images (Circuits Quickstart, Nerves Livebook)
- Support for Raspberry Pi, BeagleBone, and other platforms
- Automatic firmware download with progress indication
- Intelligent firmware caching to save bandwidth
- Works with or without fwup (automatic burning or manual instructions)
- Safe device selection with confirmation prompts
- Optional WiFi credentials configuration
- Post-burn guidance and next steps

## Installation

### Download Pre-built Executable (Recommended)

Download the latest `nerves_burner` executable from the [Releases](https://github.com/fhunleth/nerves_burner/releases) page:

```bash
# Download the latest release (replace VERSION with actual version)
curl -L -o nerves_burner https://github.com/fhunleth/nerves_burner/releases/download/vVERSION/nerves_burner
chmod +x nerves_burner

# Run it
./nerves_burner
```

**No Elixir/Erlang installation required!**

### Prerequisites

**fwup** (Optional but recommended for automatic burning):
- Installation: https://github.com/fwup-home/fwup#installing
- Ubuntu/Debian: Download .deb package from releases
- macOS: `brew install fwup`
- Windows: Download installer from releases
- **Note**: Without fwup, you'll get manual burning instructions

**GitHub Token** (Optional, for rate limiting):
```bash
export GITHUB_TOKEN=your_github_personal_access_token
```
Create token at: https://github.com/settings/tokens (needs public repo read access only)

## Usage

Run the executable:

```bash
./nerves_burner
```

### With fwup (automatic burning):

1. Select firmware image
2. Select your hardware platform
3. Configure WiFi (optional)
4. Download firmware
5. Select MicroSD card
6. Confirm (type "yes")
7. Burn firmware

### Without fwup (manual burning):

1. Select firmware and platform
2. Download firmware (alternative format)
3. Follow provided instructions for burning with:
   - **Etcher** (recommended - GUI, cross-platform)
   - **dd** (Linux/macOS command-line)
   - **Win32 Disk Imager** (Windows)

## Example

```
$ ./nerves_burner

Select a firmware image:
  1. Circuits Quickstart
  2. Nerves Livebook

Enter your choice (1-2): 1

Select a platform:
  1. Raspberry Pi 4 (rpi4)
  ...

Enter your choice: 1

Configure WiFi? (y/n): y
Enter WiFi SSID: MyNetwork
Enter WiFi passphrase: ********

Downloading firmware...
✓ Download complete

Scanning for MicroSD cards...
Available devices:
  1. /dev/sdb (15.93 GB)

Enter your choice: 1

⚠️  WARNING: All data on /dev/sdb will be erased!
Are you sure? (yes/no): yes

Burning firmware...
✓ Firmware burned successfully!

📋 Next Steps:
[Instructions displayed here]
```

## Environment Variables

**GITHUB_TOKEN / GITHUB_API_TOKEN**: Avoid rate limiting
```bash
export GITHUB_TOKEN=your_github_personal_access_token
```

**NERVES_BURNER_FORCE_UPDATE**: Force update check (for testing)
```bash
export NERVES_BURNER_FORCE_UPDATE=1
```

## Safety Features

- Explicit "yes" confirmation required before burning
- Device size display for correct identification
- Rescan option for device detection
- Clear warnings about data loss

## Firmware Caching

Downloaded firmware is cached in OS-appropriate directories:
- **Linux**: `~/.cache/nerves_burner`
- **macOS**: `~/Library/Caches/nerves_burner`
- **Windows**: Local app data cache

Cached files are verified with SHA256 hashes before use. Invalid files are automatically re-downloaded.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
