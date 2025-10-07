#!/bin/bash
# Installation script for Nerves Burner

set -e

echo "=== Nerves Burner Installation ==="
echo ""

# Check for Elixir
if ! command -v elixir &> /dev/null; then
    echo "Error: Elixir is not installed."
    echo "Please install Elixir first: https://elixir-lang.org/install.html"
    exit 1
fi

echo "✓ Elixir found: $(elixir --version | head -n 1)"

# Check for fwup
if ! command -v fwup &> /dev/null; then
    echo "Warning: fwup is not installed."
    echo "Please install fwup: https://github.com/fwup-home/fwup#installing"
    echo "The tool will still build but won't be able to burn firmware."
    echo ""
fi

# Build the escript
echo "Building nerves_burner..."
mix escript.build

if [ -f nerves_burner ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "You can now run the tool with:"
    echo "  ./nerves_burner"
    echo ""
    echo "Or install it to your PATH:"
    echo "  sudo cp nerves_burner /usr/local/bin/"
else
    echo "Error: Build failed"
    exit 1
fi
