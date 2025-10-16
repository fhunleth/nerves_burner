# VHS documentation: https://github.com/charmbracelet/vhs
#
# This script demonstrates the Nerves Burner interactive CLI
# 
# To use this script:
# 1. Build nerves_burner: mix escript.build
# 2. Run VHS: vhs demo.tape
#
# Note: This will actually run nerves_burner, so you'll need:
# - Elixir installed
# - fwup installed (optional, but recommended)
# - Network access for downloading firmware

# Output settings
Output demo.gif

# Set up a custom font size and theme
Set FontSize 14
Set Width 1400
Set Height 900
Set Theme "Dracula"
Set Padding 20

# Type speed
Set TypingSpeed 100ms

# Show the banner and initial menu
Type "./nerves_burner"
Sleep 500ms
Enter
Sleep 3s

# Select firmware image - Circuits Quickstart (option 1)
Type "1"
Sleep 300ms
Enter
Sleep 2s

# Select platform - Raspberry Pi 4 (option 1)
Type "1"
Sleep 300ms
Enter
Sleep 2s

# WiFi configuration - yes
Type "y"
Sleep 300ms
Enter
Sleep 1.5s

# Enter WiFi SSID
Type "MyHomeNetwork"
Sleep 300ms
Enter
Sleep 1.5s

# Enter WiFi passphrase (hidden)
Type "mypassword123"
Sleep 300ms
Enter
Sleep 5s

# Note: The download will actually happen, so timing may vary
# Select device - option 1 (adjust based on your available devices)
Type "1"
Sleep 300ms
Enter
Sleep 2s

# Confirm with 'yes'
Type "yes"
Sleep 300ms
Enter
Sleep 10s

# Wait to show final state
Sleep 3s
