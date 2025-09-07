#!/bin/bash

# Resono Uninstallation Script
# Usage: curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/uninstall.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Resono Uninstaller${NC}"
echo -e "${BLUE}==================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect installation type and set paths
if [[ -f "/usr/local/bin/resono" ]]; then
    INSTALL_DIR="/usr/local/bin"
    RESONO_DIR="/usr/local/share/resono"
    INSTALL_TYPE="system-wide"
elif [[ -f "$HOME/.local/bin/resono" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    RESONO_DIR="$HOME/.local/share/resono"
    INSTALL_TYPE="user"
else
    print_error "Resono installation not found!"
    exit 1
fi

echo "Found $INSTALL_TYPE installation"

# Check if running as root for system-wide installation
if [[ "$INSTALL_TYPE" == "system-wide" ]] && [[ $EUID -ne 0 ]]; then
    print_error "System-wide installation requires root privileges."
    echo "Run with sudo: sudo uninstall.sh or curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/uninstall.sh | sudo bash"
    exit 1
fi

# Confirmation
echo ""
echo -e "${YELLOW}This will remove Resono from your system. Continue? (y/N)${NC}"
read -r response </dev/tty
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Remove files
echo ""
echo "Removing Resono..."

if [[ -f "$INSTALL_DIR/resono" ]]; then
    rm -f "$INSTALL_DIR/resono"
    print_status "Removed resono command"
fi

if [[ -d "$RESONO_DIR" ]]; then
    rm -rf "$RESONO_DIR"
    print_status "Removed resono directory"
fi

echo ""
echo -e "${GREEN}Resono has been uninstalled successfully!${NC}"
