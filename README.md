# Nerves Burner

A user-friendly tool for downloading and writing pre-built Nerves firmware images to MicroSD cards.

## Supported firmwares

* [Circuits Quickstart](https://github.com/elixir-circuits/circuits_quickstart) - Simple examples for GPIO, I2C, SPI and more
* [Nerves Livebook](https://github.com/nerves-livebook/nerves_livebook) - Interactive notebooks for learning Elixir and Nerves

## Installation

### Install Elixir

Please refer to the [Elixir installation docs](https://elixir-lang.org/install.html).

### Install fwup (optional)

Nerves Burner uses [fwup](https://github.com/fwup-home/fwup) to unpack and write
Nerves firmware images to MicroSD cards. This is convenient but not required.
If `fwup` is not installed, Nerves Burner will provide step-by-step instructions for using alternative tools such as `dd` (on Linux/macOS) or [Etcher](https://www.balena.io/etcher/) (cross-platform) to write the firmware image to your MicroSD card. You do not need to install `fwup` if you prefer to use these tools.
For more information, see the [Etcher documentation](https://github.com/balena-io/etcher) or refer to your operating system's instructions for using `dd`.

Installation instructions are at
[github.com/fwup-home/fwup](https://github.com/fwup-home/fwup#installing). If
you're using MacOS, just run `brew install fwup`.

### Download Pre-built Executable

Download the latest `nerves_burner` executable from the [Releases](https://github.com/fhunleth/nerves_burner/releases) page:

```bash
curl -L -o nerves_burner https://github.com/fhunleth/nerves_burner/releases/latest/download/nerves_burner
chmod +x nerves_burner
```

## Usage

Run the executable:

```bash
./nerves_burner
```

GitHub hosts the firmware images and sometimes rate limits downloads. If you're
affected, let `nerves_burner` know your personal access token and it will log in
for the download:

```bash
export GITHUB_TOKEN=your_github_personal_access_token
```
Create token at: https://github.com/settings/tokens (needs public repo read access only)

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

## Firmware Caching

Downloaded firmware is cached in OS-appropriate directories:

- **Linux**: `~/.cache/nerves_burner`
- **macOS**: `~/Library/Caches/nerves_burner`
- **Windows**: Local app data cache

## Contributing

Contributions are welcome!

If you maintain Nerves firmware and would like to have it included in
`nerves_burner`, please post an issue or send a PR. We'd like to include
maintained community projects as well so that it's easy to discover and try out
interesting Nerves projects.

