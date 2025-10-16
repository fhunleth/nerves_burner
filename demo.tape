# VHS documentation: https://github.com/charmbracelet/vhs
#
# This script demonstrates the Nerves Burner interactive CLI

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
Type "./mock_nerves_burner.sh"
Sleep 500ms
Enter
Sleep 2.5s

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
Sleep 3s

# Select device - option 1
Type "1"
Sleep 300ms
Enter
Sleep 2s

# Confirm with 'yes'
Type "yes"
Sleep 300ms
Enter
Sleep 4s

# Wait to show final state
Sleep 3s
