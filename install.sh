#!/bin/bash

# Resono Installation Script with Automatic Virtual Environment
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
    echo -e "${YELLOW}⚠ ${NC} $1"
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

# Check if python3-venv is available (required on some systems like Ubuntu)
if ! python3 -c "import venv" &>/dev/null; then
    print_error "Python venv module is not available."
    echo "Please install python3-venv package:"
    echo "  Ubuntu/Debian: sudo apt install python3-venv"
    echo "  CentOS/RHEL: sudo yum install python3-venv"
    echo "  Or: python3 -m pip install --user virtualenv"
    exit 1
fi
print_status "Python venv module found"

# Determine installation directory
if [[ $EUID -eq 0 ]]; then
    INSTALL_DIR="/usr/local/bin"
    RESONO_DIR="/usr/local/share/resono"
    VENV_DIR="/usr/local/share/resono/venv"
    INSTALL_TYPE="system-wide"
    print_status "Installing system-wide"
else
    INSTALL_DIR="$HOME/.local/bin"
    RESONO_DIR="$HOME/.local/share/resono"
    VENV_DIR="$HOME/.local/share/resono/venv"
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

# Verify the expected directory structure
echo "Verifying repository structure..."
if [[ ! -d "resono" ]]; then
    print_error "Expected 'resono' directory not found in repository"
    echo "Repository structure:"
    ls -la
    exit 1
fi

if [[ ! -f "resono/cli.py" ]]; then
    print_error "cli.py not found in resono/ directory"
    echo "Contents of resono/ directory:"
    ls -la resono/
    exit 1
fi

if [[ ! -f "requirements.txt" ]]; then
    print_error "requirements.txt not found in root directory"
    exit 1
fi

print_status "Repository structure verified"

# Create virtual environment
echo "Creating virtual environment..."
if [[ -d "$VENV_DIR" ]]; then
    print_warning "Virtual environment already exists, removing old one..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
print_status "Virtual environment created at $VENV_DIR"

# Activate virtual environment and install dependencies
echo "Installing Python dependencies in virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip in the virtual environment
python -m pip install --upgrade pip

# Install requirements
python -m pip install -r requirements.txt
print_status "Dependencies installed in virtual environment"

# Copy files to installation directory
echo "Installing Resono files..."

# Copy the entire resono package directory
cp -r resono "$RESONO_DIR/"

# Copy supporting files to the installation directory
cp requirements.txt "$RESONO_DIR/"
cp README.md "$RESONO_DIR/" 2>/dev/null || true
cp LICENSE "$RESONO_DIR/" 2>/dev/null || true

print_status "Files copied to $RESONO_DIR"

# Verify cli.py is in the correct location
if [[ ! -f "$RESONO_DIR/resono/cli.py" ]]; then
    print_error "cli.py not found at expected location: $RESONO_DIR/resono/cli.py"
    echo "Installation directory contents:"
    ls -la "$RESONO_DIR"
    exit 1
fi

# Test if the resono package can be imported and cli.py works
echo "Testing Resono installation..."
cd "$RESONO_DIR"

# Test with the virtual environment
if ! "$VENV_DIR/bin/python" -c "import sys; sys.path.append('$RESONO_DIR'); from resono import cli" &>/dev/null; then
    print_warning "Python import test failed, but continuing..."
else
    print_status "Python import test passed"
fi

# Test cli.py directly
if "$VENV_DIR/bin/python" resono/cli.py --help &>/dev/null; then
    print_status "cli.py execution test passed"
else
    print_warning "cli.py execution test failed, but continuing..."
fi

# Create executable wrapper script that uses the virtual environment
echo "Creating resono command..."
cat > "$INSTALL_DIR/resono" << 'EOF'
#!/bin/bash
# Resono wrapper script with virtual environment

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine the installation directory based on script location
if [[ "$SCRIPT_DIR" == "/usr/local/bin" ]]; then
    RESONO_DIR="/usr/local/share/resono"
    VENV_DIR="/usr/local/share/resono/venv"
elif [[ "$SCRIPT_DIR" == "$HOME/.local/bin" ]]; then
    RESONO_DIR="$HOME/.local/share/resono"
    VENV_DIR="$HOME/.local/share/resono/venv"
else
    # Fallback - try to find it relative to script location
    RESONO_DIR="$(dirname "$SCRIPT_DIR")/share/resono"
    VENV_DIR="$RESONO_DIR/venv"
fi

# Check if resono directory exists
if [[ ! -d "$RESONO_DIR" ]]; then
    echo "Error: Resono installation directory not found: $RESONO_DIR" >&2
    exit 1
fi

# Check if virtual environment exists
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Error: Resono virtual environment not found: $VENV_DIR" >&2
    echo "Try reinstalling Resono with the install script." >&2
    exit 1
fi

# Check if cli.py exists
if [[ ! -f "$RESONO_DIR/resono/cli.py" ]]; then
    echo "Error: cli.py not found at: $RESONO_DIR/resono/cli.py" >&2
    exit 1
fi

# Check if Python interpreter exists in venv
if [[ ! -f "$VENV_DIR/bin/python" ]]; then
    echo "Error: Python interpreter not found in virtual environment: $VENV_DIR/bin/python" >&2
    exit 1
fi

# Set PYTHONPATH to include the installation directory
export PYTHONPATH="$RESONO_DIR:${PYTHONPATH:-}"

# Execute cli.py using the virtual environment's Python interpreter
# This ensures all dependencies are available and isolated
exec "$VENV_DIR/bin/python" "$RESONO_DIR/resono/cli.py" "$@"
EOF

chmod +x "$INSTALL_DIR/resono"
print_status "Resono command created"

# Verify installation
echo "Verifying installation..."

# Check if resono command is in PATH
if command -v resono &> /dev/null; then
    print_status "Resono command is available in PATH!"
    
    # Test the actual command
    echo "Testing resono command..."
    if timeout 10 resono --help &>/dev/null; then
        print_status "Resono command works correctly!"
    else
        print_warning "Resono command found but help test failed"
        echo "You may need to check the installation"
    fi
else
    print_error "Installation failed - resono command not found in PATH"
    
    if [[ $INSTALL_TYPE == "user" ]]; then
        print_warning "~/.local/bin might not be in your PATH"
        echo ""
        echo "To add ~/.local/bin to your PATH, run one of these commands:"
        echo "For bash users:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
        echo ""
        echo "For zsh users:"
        echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
        echo ""
        echo "Or use the full path: ~/.local/bin/resono"
    fi
    exit 1
fi

# Cleanup
cleanup

echo ""
echo -e "${GREEN}Resono installed successfully!${NC}"
echo ""
echo -e "${BLUE}Installation Details:${NC}"
echo "  Command location: $INSTALL_DIR/resono"
echo "  Package location: $RESONO_DIR/resono/"
echo "  Virtual environment: $VENV_DIR"
echo "  Installation type: $INSTALL_TYPE"
echo ""

# Show virtual environment info
echo -e "${BLUE}Virtual Environment Info:${NC}"
echo "  All Python dependencies are isolated in their own virtual environment"
echo "  No conflicts with your system Python packages"
echo "  Virtual environment is automatically activated when you run 'resono'"
echo ""

# Usage examples
echo -e "${BLUE}Usage Examples:${NC}"
echo "  # Embed a secret message"
echo "  resono embed --in \"secret message\" --cover audio.wav --key password"
echo ""
echo "  # Embed from a file"
echo "  resono embed --in secret.txt --cover song.wav --key mypassword"
echo ""
echo "  # Extract hidden message"
echo "  resono extract --stego encoded.wav --key password"
echo ""
echo -e "${BLUE}Get Help:${NC}"
echo "  resono --help"
echo "  resono embed --help"
echo "  resono extract --help"

if [[ $INSTALL_TYPE == "user" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    print_warning "Remember to add ~/.local/bin to your PATH to use 'resono' from anywhere!"
fi

echo ""
echo -e "${GREEN}Note: Resono runs in its own virtual environment, so there's no need to activate any venv manually!${NC}"