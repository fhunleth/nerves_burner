# ANSI Colors Implementation

This document describes the ANSI colors and art added to the Nerves Burner CLI.

## Overview

The Nerves Burner now features professional ANSI art and colorization throughout all menus and messages, making the tool more welcoming and easier to use for new users.

## Color Scheme

The following color scheme has been applied consistently throughout the application:

### Primary Colors
- **Cyan (bright)**: Section headers and main action indicators
- **Yellow**: Menu option numbers
- **Green**: User input prompts and success indicators
- **Red (bright)**: Critical warnings and errors
- **Magenta**: Branding and title text

### Secondary Colors
- **Cyan (normal)**: Informational messages
- **Yellow (normal)**: Cautionary messages
- **Red (normal)**: Error details

## ANSI Art Banner

A professional ASCII art logo displaying "NERVES" has been added to the welcome screen:

```
███╗   ██╗███████╗██████╗ ██╗   ██╗███████╗███████╗
████╗  ██║██╔════╝██╔══██╗██║   ██║██╔════╝██╔════╝
██╔██╗ ██║█████╗  ██████╔╝██║   ██║█████╗  ███████╗
██║╚██╗██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ╚════██║
██║ ╚████║███████╗██║  ██║ ╚████╔╝ ███████╗███████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚══════╝
```

Followed by the tagline: "Firmware Burner - Making IoT Easy"

## Colorized Sections

### 1. Welcome Banner
- NERVES logo in cyan (bright)
- Tagline in magenta

### 2. Firmware Selection Menu
- Header in cyan (bright)
- Option numbers in yellow
- Prompts in green

### 3. Platform Selection Menu
- Header in cyan (bright)
- Option numbers in yellow
- Prompts in green

### 4. WiFi Configuration
- Headers in cyan (bright)
- Info text in cyan
- Prompts in green
- Warnings in yellow

### 5. Download Progress
- Action messages in cyan (bright)
- Download URLs in cyan
- Success indicators in green
- File paths in default color

### 6. Device Selection
- Scanning message in cyan
- Header in cyan (bright)
- Device list numbers in yellow
- Prompts in green
- No devices warning in yellow

### 7. Confirmation Dialog
- Warning text in red (bright) with emoji
- Detailed warning in red
- Confirmation prompt in yellow

### 8. Burning Process
- Action message in cyan (bright)
- WiFi info in cyan
- Warning message in yellow

### 9. Success Messages
- Success indicator in green (bright)
- Completion message in cyan

### 10. Error Messages
- Error indicator in red (bright)
- Error details in red
- Invalid choice messages in red

### 11. Cancellation Messages
- Cancellation notices in yellow

## Technical Implementation

All colors are implemented using `IO.ANSI.format/1` which provides:

1. **Graceful Degradation**: If the terminal doesn't support ANSI colors, the output will be plain text
2. **Proper Reset**: All color sequences are properly reset to avoid color bleeding
3. **Professional Appearance**: Colors are used consistently and meaningfully

## Example Usage

```elixir
# Section header
IO.puts(IO.ANSI.format([:cyan, :bright, "Select a firmware image:", :reset, "\n"]))

# Menu option
IO.puts(IO.ANSI.format(["  ", :yellow, "1.", :reset, " Circuits Quickstart"]))

# User prompt
IO.puts(IO.ANSI.format(["\n", :green, "Enter your choice (1-2): ", :reset]))

# Warning
IO.puts(IO.ANSI.format(["\n", :red, :bright, "⚠️  WARNING: ", :reset, :red, "All data will be erased!", :reset]))

# Success
IO.puts(IO.ANSI.format([:green, :bright, "\n✓ Firmware burned successfully!\n", :reset]))

# Error
IO.puts(IO.ANSI.format([:red, :bright, "\n✗ Error: ", :reset, :red, "#{reason}\n", :reset]))
```

## Files Modified

- `lib/nerves_burner/cli.ex`: Main CLI interface with all menu interactions
- `lib/nerves_burner/downloader.ex`: Download progress messages

## Design Principles

1. **Consistency**: Same colors used for same types of messages throughout
2. **Accessibility**: Professional appearance without being overwhelming
3. **Safety**: Critical warnings use bright red for maximum visibility
4. **Usability**: Color helps users quickly identify different types of information
5. **Compatibility**: Graceful degradation on terminals without ANSI support
