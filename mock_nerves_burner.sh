#!/bin/bash
# Mock script for demonstrating Nerves Burner CLI in VHS
# This simulates the interactive flow without requiring actual Elixir/fwup

# Colors
CYAN='\e[38;5;74m'
CYAN_BRIGHT='\e[96m'
YELLOW='\e[33m'
GREEN='\e[92m'
RED='\e[91m'
MAGENTA='\e[95m'
FAINT='\e[2m'
BRIGHT='\e[1m'
RESET='\e[0m'

# Banner
echo ""
echo -e "\e[38;5;24m████▄▄    \e[38;5;74m▐███"
echo -e "\e[38;5;24m█▌  ▀▀██▄▄  \e[38;5;74m▐█"
echo -e "\e[38;5;24m█▌  \e[38;5;74m▄▄  \e[38;5;24m▀▀  \e[38;5;74m▐█   ${RESET}N  E  R  V  E  S"
echo -e "\e[38;5;24m█▌  \e[38;5;74m▀▀██▄▄  ▐█"
echo -e "\e[38;5;24m███▌    \e[38;5;74m▀▀████${RESET}"
echo ""
echo -e "${FAINT}Nerves Burner v0.2.0${RESET}"
echo ""

sleep 0.5

# Select firmware image
echo -e "${CYAN_BRIGHT}Select a firmware image:${RESET}"
echo ""
echo -e "  ${YELLOW}1.${RESET} ${BRIGHT}Circuits Quickstart${RESET}"
echo -e "     ${FAINT}Simple examples for GPIO, I2C, SPI and more${RESET}"
echo -e "  ${YELLOW}2.${RESET} ${BRIGHT}Nerves Livebook${RESET}"
echo -e "     ${FAINT}Interactive notebooks for learning Elixir and Nerves${RESET}"
echo ""
echo -e "  ${YELLOW}?.${RESET} Learn more about a firmware image"
echo ""
echo -ne "${GREEN}Enter your choice (1-2 or ?): ${RESET}"
read -r choice
echo ""

sleep 0.3

# Select platform
echo -e "${CYAN_BRIGHT}Select a platform:${RESET}"
echo ""
echo -e "  ${YELLOW}1.${RESET} Raspberry Pi 4 (rpi4)"
echo -e "  ${YELLOW}2.${RESET} Raspberry Pi 5 (rpi5)"
echo -e "  ${YELLOW}3.${RESET} Raspberry Pi 3 (rpi3)"
echo -e "  ${YELLOW}4.${RESET} Raspberry Pi Zero 2 W (rpi0_2)"
echo -e "  ${YELLOW}5.${RESET} Raspberry Pi Zero (rpi0)"
echo ""
echo -ne "${GREEN}Enter your choice (1-5): ${RESET}"
read -r platform
echo ""

sleep 0.3

# WiFi configuration
echo -e "${CYAN_BRIGHT}Would you like to configure WiFi credentials?${RESET}"
echo -e "${CYAN}(This is supported by Circuits Quickstart and Nerves Livebook firmware)${RESET}"
echo ""
echo -ne "${GREEN}Configure WiFi? (y/n): ${RESET}"
read -r wifi
echo ""

if [[ "$wifi" == "y" || "$wifi" == "Y" ]]; then
  sleep 0.3
  echo -ne "${GREEN}Enter WiFi SSID: ${RESET}"
  read -r ssid
  echo ""
  
  sleep 0.3
  echo -ne "${GREEN}Enter WiFi passphrase: ${RESET}"
  read -rs passphrase
  echo ""
  echo ""
fi

sleep 0.5

# Downloading
echo -e "${CYAN_BRIGHT}Downloading firmware...${RESET}"
echo -e "${CYAN}Fetching release information from GitHub...${RESET}"
sleep 0.8
echo -e "${CYAN}Found: circuits_quickstart_rpi4.fw (v1.24.5)${RESET}"
sleep 0.5
echo -e "${CYAN}Downloading to cache: ~/.cache/nerves_burner/${RESET}"
sleep 0.5

# Simulate download progress
echo -ne "${CYAN}Progress: [                    ] 0%${RESET}\r"
sleep 0.2
echo -ne "${CYAN}Progress: [#####               ] 25%${RESET}\r"
sleep 0.2
echo -ne "${CYAN}Progress: [##########          ] 50%${RESET}\r"
sleep 0.2
echo -ne "${CYAN}Progress: [###############     ] 75%${RESET}\r"
sleep 0.2
echo -ne "${CYAN}Progress: [####################] 100%${RESET}\r"
echo ""
sleep 0.3
echo -e "${CYAN}Verifying downloaded file...${RESET}"
sleep 0.5
echo -e "${GREEN}✓ Download complete${RESET}"
echo ""

sleep 0.5

# Device selection
echo -e "${CYAN_BRIGHT}Scanning for MicroSD cards...${RESET}"
sleep 0.8
echo -e "${CYAN}Available devices:${RESET}"
echo ""
echo -e "  ${YELLOW}1.${RESET} /dev/sdb (15.93 GB)"
echo -e "  ${YELLOW}2.${RESET} Rescan for devices"
echo ""
echo -ne "${GREEN}Enter your choice (1-2): ${RESET}"
read -r device
echo ""

sleep 0.3

# Confirmation
echo -e "${RED}${BRIGHT}⚠️  WARNING: All data on /dev/sdb will be erased!${RESET}"
echo -ne "${GREEN}Are you sure? Type 'yes' to continue: ${RESET}"
read -r confirm
echo ""

if [[ "$confirm" == "yes" ]]; then
  sleep 0.5
  
  # Burning
  echo -e "${CYAN_BRIGHT}Burning firmware to /dev/sdb...${RESET}"
  sleep 0.5
  
  # Simulate burn progress
  echo -ne "${CYAN}Writing: [                    ] 0%${RESET}\r"
  sleep 0.3
  echo -ne "${CYAN}Writing: [######              ] 30%${RESET}\r"
  sleep 0.3
  echo -ne "${CYAN}Writing: [############        ] 60%${RESET}\r"
  sleep 0.3
  echo -ne "${CYAN}Writing: [##################  ] 90%${RESET}\r"
  sleep 0.3
  echo -ne "${CYAN}Writing: [####################] 100%${RESET}\r"
  echo ""
  sleep 0.3
  
  echo -e "${GREEN}✓ Firmware burned successfully!${RESET}"
  echo -e "${CYAN}You can now safely remove the MicroSD card.${RESET}"
  echo ""
  
  sleep 0.5
  
  # Next steps
  echo -e "${CYAN_BRIGHT}📋 Next Steps:${RESET}"
  echo ""
  echo "1. Eject the MicroSD card from your computer"
  echo "2. Insert it into your Raspberry Pi"
  echo "3. Power on your device"
  echo "4. Connect via SSH or open http://nerves.local in your browser"
  echo ""
  echo -e "${CYAN}For more information, visit:${RESET}"
  echo "https://github.com/elixir-circuits/circuits_quickstart"
  echo ""
else
  echo -e "${YELLOW}Operation cancelled.${RESET}"
  echo ""
fi
