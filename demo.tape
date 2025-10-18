# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
# VHS documentation: https://github.com/charmbracelet/vhs
#
# This script creates the Nerves Burner demo video
#
# To use this script:
# 1. rm $HOME/Library/Caches/nerves_burner/*
# 2. Insert one MicroSD card that's ok to erase
# 3. Run 'fwup -D' to see that it's detected
# 4. mix escript.build
# 5. vhs demo.tape
#

# Output settings
Output demo.gif

# Set up a custom font size and theme
Set FontSize 14
Set Width 1024
Set Height 768
Set Theme "Dracula"
Set Padding 20

# Type speed
Set TypingSpeed 100ms

# Show the banner and initial menu
Type "./nerves_burner"
Enter

# Select firmware image - Circuits Quickstart (option 1)
Wait /Enter your choice.*/
Sleep 4s
Type "1"
Sleep 300ms
Enter

# Select target - Raspberry Pi 5 (option 8)
Wait /Enter your choice.*/
Sleep 1s
Type "8"
Sleep 300ms
Enter

# WiFi configuration - yes
Wait /Configure WiFi.*/
Sleep 1s
Type "y"
Sleep 300ms
Enter
Sleep 1.5s

# Enter WiFi SSID
Type "MyNetwork"
Sleep 300ms
Enter
Sleep 1.5s

# Enter WiFi passphrase
Type "Password123"
Sleep 300ms
Enter

# Note: The download will actually happen, so timing may vary
# Select device - option 1 (hope)
Wait@30s /Enter your choice.*/
Sleep 1s
Type "1"
Sleep 300ms
Enter

# Confirm with 'yes'
Wait /Are you sure.*/
Sleep 1s
Type "yes"
Sleep 300ms
Enter
Wait@30s

# Wait to show final state
Sleep 10s
