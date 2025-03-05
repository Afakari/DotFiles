#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CONFIG_REPO="https://github.com/afakari/dotfiles.git"
CONFIG_DIR="$HOME/configs_repo"
USER_HOME=$(eval echo ~$(logname))
WARP_PLUS_URL="https://github.com/bepass-org/warp-plus/releases/download/v1.2.5/warp-plus_linux-amd64.zip"
WARP_PLUS_ZIP="/tmp/warp-plus.zip"
WARP_PLUS_DIR="/tmp/warp-plus"

# Argument flags
NO_DNS=false
NO_GOLANG=false
NO_DOCKER=false
NO_VSCODE=false
NO_CHROME=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-dns) NO_DNS=true ;;
        --no-golang) NO_GOLANG=true ;;
        --no-docker) NO_DOCKER=true ;;
        --no-vscode) NO_VSCODE=true ;;
        --no-chrome) NO_CHROME=true ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
    shift
done

# Trap for graceful exit
trap 'echo -e "${RED}Script interrupted. Exiting...${NC}"; exit 1' INT TERM

# Helper function to print messages
log() {
    local level=$1
    local message=$2
    case $level in
        info) echo -e "${BLUE}[INFO]${NC} $message" ;;
        success) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        warning) echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        error) echo -e "${RED}[ERROR]${NC} $message" ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log info "Checking prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log error "This script must be run as root. Use sudo to execute the script."
        exit 1
    fi

    if ! ping -c 1 google.com &> /dev/null; then
        log error "Internet connection is required. Please check your connection and try again."
        exit 1
    fi
}

# Set up Iranian repositories
set_iranian_repos() {
    log info "Setting up Iranian repositories..."

    if [ -f /etc/os-release ]; then
        source /etc/os-release

        case $ID in
            ubuntu) mirror="http://ir.archive.ubuntu.com/ubuntu/" ;;
            debian) mirror="http://debian.ir/debian/" ;;
            *) log error "Unsupported OS: $ID"; exit 1 ;;
        esac

        cat > /etc/apt/sources.list <<EOL
deb $mirror ${VERSION_CODENAME} main restricted universe multiverse
deb $mirror ${VERSION_CODENAME}-updates main restricted universe multiverse
deb $mirror ${VERSION_CODENAME}-security main restricted universe multiverse
EOL
        log success "Iranian repositories configured for $ID ($VERSION_CODENAME)."
    else
        log error "Unable to determine OS version. /etc/os-release is missing."
        exit 1
    fi
}

# Set up DNS
setup_dns() {
    if $NO_DNS; then
        log warning "Skipping DNS setup as per --no-dns flag."
        return
    fi

    log info "Setting up DNS..."
    dns_servers=("178.22.122.100" "185.51.200.2")

    if [ -f /etc/resolv.conf ]; then
        log info "Backing up existing /etc/resolv.conf..."
        cp /etc/resolv.conf /etc/resolv.conf.bak

        log info "Updating DNS servers..."
        {
            for dns in "${dns_servers[@]}"; do
                echo "nameserver $dns"
            done
        } > /etc/resolv.conf

        log success "DNS setup complete. Current DNS servers:"
        cat /etc/resolv.conf
    else
        log error "DNS setup failed: /etc/resolv.conf not found."
        exit 1
    fi
}

# Update system
update_system() {
    log info "Updating system..."
    apt update -qq -y && apt upgrade -qq -y
    log success "System updated successfully."
}

# Install a package
install_package() {
    local package=$1
    log info "Installing $package..."
    if ! dpkg -l | grep -qw "$package"; then
        apt install -qq -y "$package" > /dev/null
        log success "$package installed successfully."
    else
        log warning "$package is already installed. Skipping installation."
    fi
}

# Install a .deb package
install_deb_package() {
    local url=$1
    local deb_file=${url##*/}
    log info "Downloading and installing $deb_file..."
    wget -q --show-progress -O /tmp/"$deb_file" "$url"
    dpkg -i /tmp/"$deb_file" > /dev/null 2>&1 || apt install -f -y > /dev/null 2>&1
    rm /tmp/"$deb_file"
    log success "$deb_file installed successfully."
}

# Install Go
install_golang() {
    if $NO_GOLANG; then
        log warning "Skipping Go installation as per --no-golang flag."
        return
    fi

    log info "Installing Go..."
    wget -c --show-progress https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local
    export PATH=$PATH:/usr/local/go/bin
    source ~/.profile
    go version || {
        log error "Go installation failed. Please check logs."
        exit 1
    }
    log success "Go installed successfully."
}

# Install Docker
install_docker() {
    if $NO_DOCKER; then
        log warning "Skipping Docker installation as per --no-docker flag."
        return
    fi

    log info "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -qq -y
    apt-get install -qq -y docker-ce docker-ce-cli containerd.io > /dev/null
    docker --version || {
        log error "Docker installation failed. Please check logs."
        exit 1
    }
    log success "Docker installed successfully."
}

# Set up Oh My Zsh
setup_oh_my_zsh() {
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        log info "Installing Oh My Zsh..."
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" || {
            log error "Oh My Zsh installation failed. Please check logs."
            exit 1
        }
        log success "Oh My Zsh installed successfully."
    else
        log warning "Oh My Zsh is already installed. Skipping installation."
    fi
}

# Copy configuration files
copy_config_files() {
    log info "Downloading configuration files..."
    if [ -d "$CONFIG_DIR" ]; then
        log info "Configuration directory already exists. Updating..."
        git -C "$CONFIG_DIR" pull
    else
        git clone "$CONFIG_REPO" "$CONFIG_DIR"
    fi

    log info "Copying configuration files..."
    cp -r "$CONFIG_DIR"/dotfiles/zshrc "$USER_HOME"/.zshrc
    cp -r "$CONFIG_DIR"/dotfiles/tmux.conf "$USER_HOME"/.tmux.conf
    mkdir -p "$USER_HOME"/.local/kitty
    cp -r "$CONFIG_DIR"/dotfiles/kitty.conf "$USER_HOME"/.local/kitty/kitty.conf

    # Ensure the user owns their home directory files
    chown -R "$(logname):$(logname)" "$USER_HOME"
    log success "Configuration files copied successfully."
}

# Install Warp
install_warp() {
    log info "Setting up Warp..."
    if ! command -v warp &> /dev/null; then
        log info "Downloading Warp Plus..."
        wget -q --show-progress "$WARP_PLUS_URL" -O "$WARP_PLUS_ZIP"

        log info "Extracting Warp Plus..."
        mkdir -p "$WARP_PLUS_DIR"
        unzip -q "$WARP_PLUS_ZIP" -d "$WARP_PLUS_DIR"

        log info "Installing Warp..."
        mv "$WARP_PLUS_DIR"/warp-plus /usr/local/bin/warp

        log info "Cleaning up..."
        rm -rf "$WARP_PLUS_ZIP" "$WARP_PLUS_DIR"

        log success "Warp installed successfully. You can now use the 'warp' command."
    else
        log warning "Warp is already installed. Skipping installation."
    fi
}

# Main function
main() {
    check_prerequisites
    set_iranian_repos
    update_system

    packages=(apt-transport-https ca-certificates lsb-release xclip python3 python3-pip vim zsh tmux kitty tor git wget fzf autojump)
    for package in "${packages[@]}"; do
        install_package "$package"
    done

    if ! $NO_VSCODE && ! command -v code &> /dev/null; then
        install_deb_package "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    else
        log warning "Visual Studio Code installation skipped or already installed."
    fi

    if ! $NO_CHROME && ! command -v google-chrome &> /dev/null; then
        install_deb_package "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    else
        log warning "Google Chrome installation skipped or already installed."
    fi

    setup_oh_my_zsh
    install_golang
    install_docker
    install_warp
    copy_config_files

    log success "Environment setup complete! You may need to log out and log back in for changes to take effect."
}

# Run the script
main
