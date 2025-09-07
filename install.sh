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
    INSTALL_DIR="/usr/local/bin"
    RESONO_DIR="/usr/local/share/resono"
    INSTALL_TYPE="system-wide"
    print_status "Installing system-wide"
else
    INSTALL_DIR="$HOME/.local/bin"
    RESONO_DIR="$HOME/.local/share/resono"
    INSTALL_TYPE="user"
    print_status "Installing for current user"
fi

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$RESONO_DIR"

# Download Resono from GitHub
echo "Downloading Resono from GitHub..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if ! curl -fsSL -o resono.tar.gz https://github.com/kaizoku73/Resono/archive/refs/heads/main.tar.gz; then
    print_error "Failed to download Resono from GitHub"
    exit 1
fi

tar -xzf resono.tar.gz
cd Resono-main

print_status "Downloaded and extracted Resono"

# Copy files to installation directory
echo "Installing Resono files..."
cp -r * "$RESONO_DIR/"
print_status "Files copied to $RESONO_DIR"

# Install Python dependencies
echo "Installing Python dependencies..."
if [[ -f "$RESONO_DIR/requirements.txt" ]]; then
    if [[ $INSTALL_TYPE == "user" ]]; then
        python3 -m pip install -r "$RESONO_DIR/requirements.txt"
    else
        python3 -m pip install -r "$RESONO_DIR/requirements.txt"
    fi
    print_status "Dependencies installed"
else
    print_warning "No requirements.txt found, skipping dependencies"
fi

# Executable wrapper script
echo "Creating resono command..."
cat > "$INSTALL_DIR/resono" << EOF
#!/bin/bash
# Resono wrapper script
cd "$RESONO_DIR"
exec python3 cli.py "\$@"
EOF

chmod +x "$INSTALL_DIR/resono"
print_status "Resono command created"

# Verify installation
echo "Verifying installation..."

if command -v resono &> /dev/null; then
    print_status "Resono command is available!"
else
    print_error "Installation failed - resono command not found"
    
    if [[ $INSTALL_TYPE == "user" ]]; then
        print_warning "~/.local/bin might not be in your PATH"
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "Then run: source ~/.bashrc"
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