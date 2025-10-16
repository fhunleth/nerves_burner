<!--
  SPDX-License-Identifier: CC0-1.0
  SPDX-FileCopyrightText: None
-->

# AGENTS.md - Technical Documentation for AI Agents

This document provides comprehensive technical information about the Nerves Burner project for AI agents working on code changes, bug fixes, and feature additions.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Module Reference](#module-reference)
4. [Development Workflow](#development-workflow)
5. [Testing](#testing)
6. [Build and Deployment](#build-and-deployment)
7. [Key Features](#key-features)
8. [Code Style and Conventions](#code-style-and-conventions)
9. [Common Tasks](#common-tasks)

## Project Overview

**Nerves Burner** is an Elixir-based command-line tool for downloading and burning pre-built Nerves firmware images to MicroSD cards. It's distributed as a standalone escript executable.

### Project Statistics
- **Language**: Elixir 1.14+
- **Total Source Lines**: ~600 lines
- **Test Coverage**: 44 tests, all passing
- **Main Modules**: 8 modules
- **Dependencies**: req, progress_bar, credo (dev), dialyxir (dev)

### Key Requirements
- Elixir 1.14 or later
- Erlang/OTP (compatible with Elixir version)
- fwup (optional, for automatic firmware burning)
- GitHub API access (optional token for rate limiting)

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     NervesBurner.CLI                        │
│              (Main Entry Point & User Interface)            │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐  ┌──────────────┐  ┌─────────────────┐
│ FirmwareImages│  │  Downloader  │  │      Fwup       │
│   (Config)    │  │ (GitHub API) │  │ (Device Tools)  │
└───────────────┘  └──────────────┘  └─────────────────┘
        │                   │                   │
        │                   ▼                   │
        │           ┌──────────────┐           │
        │           │VersionChecker│           │
        │           │ (Auto-update)│           │
        │           └──────────────┘           │
        │                                       │
        └───────────────────┬───────────────────┘
                            ▼
                    ┌──────────────┐
                    │    Output    │
                    │  (Formatting)│
                    └──────────────┘
```

### Module Structure

```
lib/
├── nerves_burner.ex                  # Main application module
└── nerves_burner/
    ├── cli.ex                        # Interactive CLI interface (424 lines)
    ├── firmware_images.ex            # Firmware configurations
    ├── downloader.ex                 # GitHub release downloader (473 lines)
    ├── fwup.ex                       # fwup integration (80 lines)
    ├── version_checker.ex            # Auto-update functionality
    ├── output.ex                     # ANSI formatting helpers (100 lines)
    └── interactive_shell.ex          # Shell interaction utilities
```

## Module Reference

### NervesBurner.CLI

**Purpose**: Main command-line interface and user interaction.

**Key Functions**:
- `main/1` - Entry point for escript, orchestrates the entire flow
- `select_firmware_image/0` - Interactive firmware selection menu
- `select_platform/1` - Platform selection menu
- `select_device/0` - Device selection with rescan option
- `confirm_device/1` - Safety confirmation dialog (requires "yes")
- `configure_wifi/0` - WiFi credentials configuration (optional)

**Flow Control**: Uses Elixir's `with` construct for clean error handling and flow control.

**Color Scheme**: Uses Output module for consistent ANSI formatting throughout.

### NervesBurner.FirmwareImages

**Purpose**: Centralized firmware image configuration.

**Data Structure**:
```elixir
%{
  repo: "org/repo",                    # GitHub repository
  description: "Description text",     # User-facing description
  platforms: ["rpi4", "rpi5", ...],   # Supported platforms
  asset_pattern: fn platform -> ... end, # Asset filename pattern
  fallback_asset_pattern: fn platform -> ... end, # For non-fwup formats
  next_steps: %{                       # Post-burn instructions
    default: "...",
    platforms: %{"platform" => "..."}
  }
}
```

**Key Functions**:
- `list/0` - Returns list of {name, config} tuples
- `platform_name/1` - Maps platform code to friendly name
- `next_steps/2` - Returns platform-specific or default next steps

**Supported Platforms**:
- Raspberry Pi: rpi, rpi0, rpi0_2, rpi2, rpi3, rpi3a, rpi4, rpi5
- BeagleBone Black: bbb
- OSD32MP1: osd32mp1
- NPI i.MX6 ULL: npi_imx6ull
- GRiSP 2: grisp2
- MangoPi MQ Pro: mangopi_mq_pro

### NervesBurner.Downloader

**Purpose**: GitHub release download with intelligent caching and verification.

**Key Features**:
- Fetches latest release from GitHub API using `req` library
- Intelligent firmware caching in OS-appropriate directories
- SHA256 verification of cached files
- Automatic re-download on verification failure
- Support for both `.fw` (fwup) and alternative formats (zip, img.gz)

**Key Functions**:
- `download/2` - Main download coordinator
- `get_latest_release_url/1` - Fetch release info from GitHub API
- `find_asset_url/2` - Locate firmware asset and extract metadata
- `download_file/2` - Check cache or download to cache directory
- `get_cache_dir/0` - Get OS-appropriate cache directory
- `verify_file/2` - Verify cached file size and SHA256 hash
- `compute_sha256/1` - Compute SHA256 hash of firmware file
- `get_sha256_from_github/2` - Download and parse SHA256SUMS file

**Cache Directories**:
- Linux: `~/.cache/nerves_burner` (respects `$XDG_CACHE_HOME`)
- macOS: `~/Library/Caches/nerves_burner`
- Windows: User's local app data cache directory

**Verification Process**:
1. Check file size matches expected size from GitHub
2. Verify SHA256 hash:
   - If GitHub provides SHA256SUMS file, use that
   - Otherwise, compute hash locally after first download
3. Re-download if verification fails

### NervesBurner.Fwup

**Purpose**: Integration with fwup command-line tool.

**Key Functions**:
- `available?/0` - Check if fwup is installed
- `scan_devices/0` - List available MicroSD cards
- `burn/2` - Write firmware to device (streams progress)
- `parse_device_line/1` - Parse fwup --detect output

**Device Scanning**: Uses `fwup --detect` to list removable storage devices with sizes.

**Burning**: Streams progress output from fwup to console, handling both stdout and stderr.

### NervesBurner.VersionChecker

**Purpose**: Automatic version checking and updating.

**Key Functions**:
- `check_and_offer_update/1` - Main entry point, checks and prompts
- `get_latest_version/0` - Fetches latest version from GitHub
- `download_and_replace/2` - Downloads and installs new version
- `compare_versions/2` - Semantic version comparison

**Environment Variables**:
- `NERVES_BURNER_FORCE_UPDATE=1` - Force update check (for testing)
- `GITHUB_TOKEN` or `GITHUB_API_TOKEN` - GitHub API authentication

**Update Process**:
1. Check GitHub releases for latest version
2. Compare with current version
3. Prompt user if newer version available
4. Download new version
5. Replace current executable
6. Verify installation

### NervesBurner.Output

**Purpose**: Centralized ANSI formatting for console output.

**Key Functions**:
- `section/1` - Section headers (cyan, bright)
- `success/1` - Success messages (green, bright)
- `info/1` - Informational messages (cyan)
- `warning/1` - Warning messages (yellow)
- `error/1` - Error messages (red, bright)
- `menu_option/2` - Menu items with numbered prefixes
- `menu_option_with_parts/3` - Menu items with main and secondary text
- `prompt/1` - Formatted user input prompts
- `critical_warning/1` - Critical warnings with warning symbol
- `labeled/3` - Labeled output with customizable colors

**Color Scheme**:
- **Cyan (bright)**: Section headers and main actions
- **Yellow**: Menu option numbers and cautions
- **Green**: User input prompts and success
- **Red (bright)**: Critical warnings and errors
- **Magenta**: Branding and titles

**Design Principles**:
- Consistent formatting across all output
- Graceful degradation on terminals without ANSI support
- All functions include `@spec` type annotations
- Centralized for easy maintenance

### NervesBurner.InteractiveShell

**Purpose**: Helper utilities for shell interaction.

**Key Functions**: String manipulation and user input handling utilities.

## Development Workflow

### Setup

```bash
# Install dependencies
mix deps.get

# Format code
mix format

# Run static analysis
mix credo

# Run type checking
mix dialyzer

# Run tests
mix test

# Build executable
mix escript.build
```

### Project Configuration

**mix.exs**:
- App: `:nerves_burner`
- Version: `0.1.0`
- Elixir: `~> 1.14`
- Main module: `NervesBurner.CLI`
- Build: Escript

**Dependencies**:
- `:req` ~> 0.5 - Modern HTTP client with JSON support
- `:progress_bar` ~> 3.0 - Progress bar for downloads
- `:credo` ~> 1.6 - Static analysis (dev/test only)
- `:dialyxir` ~> 1.4 - Type checking (dev/test only)

### Code Formatting

Uses standard Elixir formatting:
```bash
mix format
```

Configuration in `.formatter.exs`.

## Testing

### Test Structure

```
test/
├── test_helper.exs
└── nerves_burner/
    ├── firmware_images_test.exs   # Firmware config tests
    ├── fwup_test.exs              # Fwup integration tests
    ├── downloader_test.exs        # Download logic tests
    ├── output_test.exs            # Output formatting tests
    └── version_checker_test.exs   # Version checking tests
```

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/nerves_burner/firmware_images_test.exs

# Run with coverage
mix test --cover
```

### Test Coverage

- **Total tests**: 44 tests
- **Status**: All passing
- **Coverage areas**:
  - Firmware image configuration
  - Platform name mapping
  - Next steps retrieval
  - Fwup device parsing
  - Output formatting
  - Version comparison
  - Download caching and verification

### Testing Best Practices

- Use `ExUnit` for all tests
- Mock external dependencies (GitHub API, fwup commands)
- Test both success and error paths
- Verify user-facing output formatting
- Test edge cases (missing files, invalid input, etc.)

## Build and Deployment

### Building Executable

```bash
# Build escript
mix escript.build

# This creates: ./nerves_burner (executable)
```

### Distribution

The project can be distributed as:
1. **Pre-built executable**: Single file, no Elixir installation required
2. **Source**: Users can build with `mix escript.build`

### Release Process

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Build executable: `mix escript.build`
4. Create GitHub release with executable as asset
5. Update README.md with new version number

### GitHub Actions CI/CD

Located in `.github/workflows/`:

**CI Workflow (`ci.yml`)**:
- Runs on pull requests and pushes to main branch
- Steps:
  1. Code formatting check
  2. Compilation with warnings as errors
  3. Run test suite
  4. Build escript
  5. Run static analysis (credo)
  6. Run type checking (dialyzer)

**Release Workflow (`release.yml`)**:
- Runs when a version tag is pushed (e.g., `v1.0.0`)
- Automatically:
  1. Builds the escript
  2. Creates a GitHub Release for the tag
  3. Uploads the `nerves_burner` executable as release asset

**Creating a Release**:
```bash
# Tag the release
git tag v1.0.0
git push origin v1.0.0
```

The workflow will handle building and uploading the executable.

## Key Features

### 1. Automatic Version Checking

**Implementation**: `NervesBurner.VersionChecker`

- Checks GitHub releases on startup
- Displays current version below banner
- Prompts for update if newer version available
- Auto-downloads and replaces executable
- Graceful error handling (silent on network issues)
- Testing mode: `NERVES_BURNER_FORCE_UPDATE=1`

### 2. Firmware Caching

**Implementation**: `NervesBurner.Downloader`

- Caches in OS-appropriate directories (using `:filename.basedir/2`)
- Verifies files with size + SHA256 hash
- Downloads SHA256SUMS from GitHub if available
- Falls back to local hash computation
- Auto re-downloads on verification failure
- Saves bandwidth and time for repeated burns

### 3. Fallback Mode (Without fwup)

**Implementation**: `NervesBurner.CLI` + `NervesBurner.Downloader`

When fwup is not available:
- Downloads alternative format (zip, img.gz)
- Displays file location
- Provides manual burning instructions
- Suggests multiple tools (Etcher, dd, Win32 Disk Imager)
- Maintains full functionality for download

### 4. WiFi Configuration

**Implementation**: `NervesBurner.CLI.configure_wifi/0`

- Optional feature for supported firmware
- Prompts for SSID and passphrase
- Passes to fwup via metadata flags
- Currently supported: Circuits Quickstart, Nerves Livebook

### 5. Next Steps Guidance

**Implementation**: `NervesBurner.FirmwareImages.next_steps/2`

- Post-burn instructions displayed to user
- Customizable per firmware
- Platform-specific overrides available
- Links to documentation and getting started guides

### 6. ANSI Colors and Formatting

**Implementation**: `NervesBurner.Output`

- Professional, welcoming interface
- Consistent color scheme throughout
- NERVES logo with ANSI art
- Graceful degradation on plain terminals
- Centralized formatting for maintainability

## Code Style and Conventions

### Elixir Style Guide

Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide):

- Use 2-space indentation
- Use snake_case for atoms, functions, and variables
- Use PascalCase for module names
- Maximum line length: 98 characters (enforced by formatter)
- Use pipe operator `|>` for data transformation chains
- Use `with` for complex control flow

### Documentation

- Add `@moduledoc` to all public modules
- Add `@doc` to all public functions
- Add `@spec` type annotations to public functions
- Use doctest examples where appropriate

### Error Handling

- Use `{:ok, result}` and `{:error, reason}` tuples
- Pattern match in function heads when possible
- Use `with` for multiple operations that can fail
- Provide user-friendly error messages via `Output.error/1`

### Module Organization

1. Module documentation (`@moduledoc`)
2. Module attributes and aliases
3. Public API (exported functions)
4. Private helper functions

### Naming Conventions

- Boolean functions: `available?`, `valid?`, `exists?`
- Functions that perform side effects: imperative verbs (`burn`, `download`, `scan`)
- Functions that return data: nouns or descriptive phrases (`platform_name`, `next_steps`)

## Common Tasks

### Adding a New Firmware Image

1. Add entry to `NervesBurner.FirmwareImages.list/0`:
```elixir
{"My Firmware",
 %{
   repo: "user/my_firmware",
   description: "Description of firmware",
   platforms: ["rpi4", "rpi5"],
   asset_pattern: fn platform -> "my_firmware_#{platform}.fw" end,
   fallback_asset_pattern: fn platform -> "my_firmware_#{platform}.zip" end,
   next_steps: %{
     default: """
     Instructions here...
     """
   }
 }}
```

2. Add tests in `test/nerves_burner/firmware_images_test.exs`
3. Update README.md with new firmware info

### Adding a New Platform

1. Add platform to supported platforms list in firmware config
2. Add friendly name in `NervesBurner.FirmwareImages.platform_name/1`:
```elixir
def platform_name("new_platform"), do: "Friendly Name (new_platform)"
```

3. Ensure asset pattern handles the new platform
4. Add tests

### Modifying Output Formatting

All output formatting is centralized in `NervesBurner.Output`:

1. Modify or add function in `output.ex`
2. Update callers if signature changed
3. Add tests in `test/nerves_burner/output_test.exs`
4. Run `mix test` to verify

### Adding New CLI Menu Option

1. Update relevant menu function in `NervesBurner.CLI`
2. Add new handler function if needed
3. Update tests
4. Ensure proper error handling

### Debugging

**Enable verbose output**: Modify output functions to show more detail

**Test specific scenarios**:
```bash
# Test with force update
NERVES_BURNER_FORCE_UPDATE=1 ./nerves_burner

# Test with GitHub token
GITHUB_TOKEN=your_token ./nerves_burner

# Test without fwup
mv /usr/local/bin/fwup /usr/local/bin/fwup.bak
./nerves_burner
mv /usr/local/bin/fwup.bak /usr/local/bin/fwup
```

**Check logs**: Look for error messages in console output

### Performance Optimization

**Caching**: Already implemented for firmware downloads

**Network**: Uses `req` library with connection pooling

**File I/O**: Streams large files, computes hashes in chunks

### Security Considerations

**GitHub API**: Use tokens to avoid rate limiting
- Tokens only need public repository read access
- Never commit tokens to repository

**User Input**: All user input is validated before use
- Device selection requires exact "yes" confirmation
- No shell injection vulnerabilities (uses System.cmd/3, not shell commands)

**File Downloads**: Verify integrity with SHA256 hashes
- Always verify cached files before use
- Re-download if hash doesn't match

## Refactoring History

### Output Module Introduction

**Before**: 533 lines in CLI, verbose ANSI formatting
**After**: 424 lines in CLI, 100 lines in Output module
**Reduction**: 20% in CLI module
**Benefits**:
- DRY principle applied
- Easier maintenance
- Better testability
- Type-safe with `@spec` annotations

### Downloader Caching Enhancement

**Added**:
- OS-appropriate cache directories
- SHA256 verification
- GitHub SHA256SUMS file parsing
- Automatic re-download on failure

**Benefits**:
- Faster repeated burns
- Bandwidth savings
- Integrity verification
- Better user experience

## Troubleshooting

### Common Issues

**"mix: command not found"**
- Solution: Install Elixir and Erlang

**"fwup: command not found"**
- Solution: Tool automatically enters fallback mode
- Optional: Install fwup for automatic burning

**GitHub rate limiting**
- Solution: Set `GITHUB_TOKEN` environment variable

**Permission denied when burning**
- Solution: Run with sudo or add user to appropriate group
- On Linux: `sudo usermod -aG disk $USER` (requires logout/login)

**Cache verification failures**
- Solution: Tool automatically re-downloads
- Manual: Delete cache directory and retry

## Additional Resources

- **Main Repository**: https://github.com/fhunleth/nerves_burner
- **Nerves Project**: https://nerves-project.org/
- **fwup**: https://github.com/fwup-home/fwup
- **Elixir**: https://elixir-lang.org/

## Contributing

When contributing:

1. Follow existing code style
2. Add tests for new features
3. Update documentation (this file and README.md)
4. Run full test suite before submitting
5. Ensure CI passes
6. Use descriptive commit messages

## Version History

See `CHANGELOG.md` for detailed version history.
