#!/bin/bash

# Resono Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/kaizoku73/Resono/main/install.sh | bash

set -euo pipefail

# Cleanup function for temp directory
cleanup() {
    if [[ -n "${TEMP_DIR:-}" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Resono Audio Steganography Installer${NC}"
echo -e "${BLUE}======================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check for required dependencies
echo "Checking system requirements..."

# Check Python 3
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is required but not installed."
    echo "Please install Python 3.7+ and try again."
    exit 1
fi
print_status "Python 3 found: $(python3 --version)"

# Check pip
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    print_error "pip is required but not installed."
    echo "Please install pip and try again."
    exit 1
fi
print_status "pip found"

# Determine installation directory
if [[ $EUID -eq 0 ]]; then
    # Running as root - system-wide install
    INSTALL_DIR="/usr/local/bin"
    RESONO_DIR="/usr/local/share/resono"
    PIP_CMD="python3 -m pip install"
    INSTALL_TYPE="system-wide"
    print_status "Installing system-wide (requires root privileges)"
else
    # User installation
    INSTALL_DIR="$HOME/.local/bin"
    RESONO_DIR="$HOME/.local/share/resono"
    PIP_CMD="python3 -m pip install"
    INSTALL_TYPE="user"
    print_status "Installing for current user"
fi

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$RESONO_DIR"

# Try to install from PyPI first (when published)
echo "Installing Resono..."
if $PIP_CMD resono &> /dev/null; then
    print_status "Resono installed from PyPI"
else
    print_warning "PyPI installation failed, installing from GitHub..."
    
    # Download and install from GitHub
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if ! curl -fsSL -o resono.tar.gz https://github.com/kaizoku73/Resono/archive/refs/heads/main.tar.gz; then
        print_error "Failed to download Resono from GitHub"
        exit 1
    fi
    
    tar -xzf resono.tar.gz
    cd Resono-main
    
    print_status "Downloaded and extracted Resono"
    
    # Install from source
    if ! $PIP_CMD . ; then
        print_error "Failed to install Resono from source"
        exit 1
    fi
    
    print_status "Resono installed from GitHub source"
fi

# Verify installation
echo "Verifying installation..."

if command -v resono &> /dev/null; then
    print_status "Resono command is available!"
    
    # Try to get version
    VERSION_OUTPUT=$(resono --version 2>/dev/null || resono --help 2>/dev/null | head -1 || echo "Version unknown")
    print_status "Installation verified: $VERSION_OUTPUT"
else
    print_error "Installation failed - resono command not found"
    
    if [[ $INSTALL_TYPE == "user" ]]; then
        print_warning "~/.local/bin might not be in your PATH"
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "Then run: source ~/.bashrc"
        echo ""
        echo "Or for this session only:"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    exit 1
fi

# Cleanup
cleanup

echo ""
echo -e "${GREEN}Resono installed successfully!${NC}"
echo ""

# Usage examples
if [[ $INSTALL_TYPE == "system-wide" ]]; then
    echo -e "${BLUE}Usage:${NC}"
    echo "   resono embed --in \"secret message\" --cover audio.wav --key password"
    echo "   resono extract --stego encoded.wav --key password"
else
    # Check if ~/.local/bin is in PATH for user installation
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        echo -e "${BLUE}Usage:${NC}"
        echo "   resono embed --in \"secret message\" --cover audio.wav --key password"
        echo "   resono extract --stego encoded.wav --key password"
    else
        echo -e "${BLUE}Usage (add to PATH first):${NC}"
        echo "   ~/.local/bin/resono embed --in \"secret message\" --cover audio.wav --key password"
        echo "   ~/.local/bin/resono extract --stego encoded.wav --key password"
        echo ""
        print_warning "~/.local/bin is not in your PATH"
        echo "To use 'resono' from anywhere, run:"
        echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
    fi
fi

echo ""
echo -e "${BLUE}Examples:${NC}"
echo "   resono embed --in secret.txt --cover song.wav --key mypassword"
echo "   resono embed --in \"Hidden message\" --cover audio.wav --key secret123"
echo "   resono extract --stego encoded.wav --key mypassword"
echo ""
echo -e "${BLUE}Help:${NC}"
echo "   resono --help"
echo "   resono embed --help"
echo "   resono extract --help"