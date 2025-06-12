#!/bin/bash

set -euo pipefail

# Colors for output
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[0;34m'
declare -r NC='\033[0m' # No Color

# Constants
declare -r CONFIG_REPO="https://github.com/afakari/dotfiles.git"
declare -r CONFIG_DIR="$HOME/configs_repo"
declare -r USER_HOME=$(eval echo ~$(logname))
declare -r USER_NAME=$(logname)
declare -r WARP_PLUS_URL="https://github.com/bepass-org/warp-plus/releases/download/v1.2.5/warp-plus_linux-amd64.zip"
declare -r WARP_PLUS_ZIP="/tmp/warp-plus.zip"
declare -r WARP_PLUS_DIR="/tmp/warp-plus"
declare -r PYENV_VERSION="3.11.12"
declare -r OPENJDK_VERSION="17"

# Argument flags
declare NO_DNS=false
declare NO_GOLANG=false
declare NO_DOCKER=false
declare NO_VSCODE=false
declare NO_CHROME=false
declare NO_RUST=false
declare NO_ALACRITTY=false
declare NO_PYENV=false
declare NO_SDKMAN=false

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-dns) NO_DNS=true ;;
            --no-golang) NO_GOLANG=true ;;
            --no-docker) NO_DOCKER=true ;;
            --no-vscode) NO_VSCODE=true ;;
            --no-chrome) NO_CHROME=true ;;
            --no-rust) NO_RUST=true ;;
            --no-alacritty) NO_ALACRITTY=true ;;
            --no-pyenv) NO_PYENV=true ;;
            --no-sdkman) NO_SDKMAN=true ;;
            *) log error "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done
}

# Log function
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
    [[ $EUID -ne 0 ]] && { log error "This script must be run as root."; exit 1; }
    ping -c 1 google.com &> /dev/null || { log error "Internet connection required."; exit 1; }
    [[ -d "$USER_HOME" ]] || { log error "User home directory $USER_HOME does not exist."; exit 1; }
}

# Set up Iranian repositories
set_iranian_repos() {
    log info "Setting up Iranian repositories..."
    source /etc/os-release || { log error "/etc/os-release missing."; exit 1; }
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
}

# Set up DNS
setup_dns() {
    $NO_DNS && { log warning "Skipping DNS setup."; return; }
    log info "Setting up DNS..."
    local dns_servers=("178.22.122.100" "185.51.200.2")
    [[ -f /etc/resolv.conf ]] && cp /etc/resolv.conf /etc/resolv.conf.bak
    {
        for dns in "${dns_servers[@]}"; do
            echo "nameserver $dns"
        done
    } > /etc/resolv.conf || { log error "DNS setup failed."; exit 1; }
    log success "DNS setup complete."
}

# Update system
update_system() {
    log info "Updating system..."
    apt update -qq -y && apt upgrade -qq -y
    log success "System updated."
}

# Install package
install_package() {
    local package=$1
    log info "Installing $package..."
    dpkg -l | grep -qw "$package" && { log warning "$package already installed."; return; }
    apt install -qq -y "$package" > /dev/null || { log error "$package installation failed."; exit 1; }
    log success "$package installed."
}

# Install .deb package
install_deb_package() {
    local url=$1
    local deb_file=${url##*/}
    log info "Installing $deb_file..."
    wget -q --show-progress -O /tmp/"$deb_file" "$url"
    dpkg -i /tmp/"$deb_file" > /dev/null 2>&1 || apt install -f -y > /dev/null 2>&1
    rm /tmp/"$deb_file"
    log success "$deb_file installed."
}

# Install Rust
install_rust() {
    $NO_RUST && { log warning "Skipping Rust installation."; return; }
    log info "Installing Rust for user $USER_NAME..."
    sudo -u "$USER_NAME" bash -c "[[ -d \"$USER_HOME/.cargo\" ]] && { echo 'Rust already installed.'; exit 0; } || true"
    sudo -u "$USER_NAME" bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    sudo -u "$USER_NAME" bash -c "source \"$USER_HOME/.cargo/env\" && rustc --version" || { log error "Rust installation failed."; exit 1; }
    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.cargo" "$USER_HOME/.rustup"
    log success "Rust installed."
}

# Install Alacritty dependencies
install_alacritty_deps() {
    log info "Installing Alacritty dependencies..."
    local deps=(
        cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev
        libxkbcommon-dev python3 build-essential
    )
    for dep in "${deps[@]}"; do
        install_package "$dep"
    done
}

# Install Alacritty
install_alacritty() {
    $NO_ALACRITTY && { log warning "Skipping Alacritty installation."; return; }
    log info "Installing Alacritty..."
    command -v alacritty &> /dev/null && { log warning "Alacritty already installed."; return; }
    install_alacritty_deps
    sudo -u "$USER_NAME" git clone https://github.com/alacritty/alacritty.git /tmp/alacritty
    cd /tmp/alacritty
    sudo -u "$USER_NAME" bash -c "source \"$USER_HOME/.cargo/env\" && cargo build --release"
    mv target/release/alacritty /usr/local/bin/
    cd - && rm -rf /tmp/alacritty
    chown "$USER_NAME:$USER_NAME" /usr/local/bin/alacritty
    alacritty --version || { log error "Alacritty installation failed."; exit 1; }
    log success "Alacritty installed."
}

# Install pyenv dependencies
install_pyenv_deps() {
    log info "Installing pyenv dependencies..."
    local deps=(
        build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev
        libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev
        libxmlsec1-dev libffi-dev liblzma-dev
    )
    for dep in "${deps[@]}"; do
        install_package "$dep"
    done
}

# Install pyenv
install_pyenv() {
    $NO_PYENV && { log warning "Skipping pyenv installation."; return; }
    log info "Installing pyenv for user $USER_NAME..."
    sudo -u "$USER_NAME" bash -c "[[ -d \"$USER_HOME/.pyenv\" ]] && { echo 'pyenv already installed.'; exit 0; } || true"
    install_pyenv_deps
    sudo -u "$USER_NAME" bash -c "curl https://pyenv.run | bash"
    sudo -u "$USER_NAME" bash -c "echo 'export PYENV_ROOT=\"\$HOME/.pyenv\"' >> \"$USER_HOME/.zshrc\""
    sudo -u "$USER_NAME" bash -c "echo '[[ -d \$PYENV_ROOT/bin ]] && export PATH=\"\$PYENV_ROOT/bin:\$PATH\"' >> \"$USER_HOME/.zshrc\""
    sudo -u "$USER_NAME" bash -c "echo 'eval \"\$(pyenv init -)\"' >> \"$USER_HOME/.zshrc\""
    sudo -u "$USER_NAME" bash -c "export PYENV_ROOT=\"\$HOME/.pyenv\" && export PATH=\"\$PYENV_ROOT/bin:\$PATH\" && eval \"\$(pyenv init -)\" && pyenv install $PYENV_VERSION && pyenv global $PYENV_VERSION"
    sudo -u "$USER_NAME" bash -c "export PYENV_ROOT=\"\$HOME/.pyenv\" && export PATH=\"\$PYENV_ROOT/bin:\$PATH\" && eval \"\$(pyenv init -)\" && python3 --version" || { log error "Python $PYENV_VERSION installation failed."; exit 1; }
    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.pyenv"
    log success "Pyenv and Python $PYENV_VERSION installed."
}

# Install SDKMAN
install_sdkman() {
    $NO_SDKMAN && { log warning "Skipping SDKMAN installation."; return; }
    log info "Installing SDKMAN for user $USER_NAME..."
    sudo -u "$USER_NAME" bash -c "[[ -d \"$USER_HOME/.sdkman\" ]] && { echo 'SDKMAN already installed.'; exit 0; } || true"
    sudo -u "$USER_NAME" bash -c "curl -s \"https://get.sdkman.io\" | bash"
    sudo -u "$USER_NAME" bash -c "source \"$USER_HOME/.sdkman/bin/sdkman-init.sh\" && sdk version" || { log error "SDKMAN installation failed."; exit 1; }
    sudo -u "$USER_NAME" bash -c "source \"$USER_HOME/.sdkman/bin/sdkman-init.sh\" && sdk install java $OPENJDK_VERSION-open" || { log error "OpenJDK $OPENJDK_VERSION installation failed."; exit 1; }
    sudo -u "$USER_NAME" bash -c "source \"$USER_HOME/.sdkman/bin/sdkman-init.sh\" && sdk install scala" || { log error "Scala installation failed."; exit 1; }
    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.sdkman"
    log success "SDKMAN, OpenJDK $OPENJDK_VERSION, Scala, and Go installed."
}

# Install Docker
install_docker() {
    $NO_DOCKER && { log warning "Skipping Docker installation."; return; }
    log info "Installing Docker..."
    command -v docker &> /dev/null && { log warning "Docker already installed."; return; }
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -qq -y && apt install -qq -y docker-ce docker-ce-cli containerd.io > /dev/null
    usermod -aG docker "$USER_NAME"
    docker version || { log error "Docker installation failed."; exit 1; }
    log success "Docker installed."
}

# Install Oh My Zsh
install_oh_my_zsh() {
    sudo -u "$USER_NAME" bash -c "[[ -d \"$USER_HOME/.oh-my-zsh\" ]] && { echo 'Oh My Zsh already installed.'; exit 0; } || true"
    log info "Installing Oh My Zsh for user $USER_NAME..."
    sudo -u "$USER_NAME" bash -c "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended" || { log error "Oh My Zsh installation failed."; exit 1; }
    log success "Oh My Zsh installed."
}

# Copy configuration files
copy_config_files() {
    log info "Configuring dotfiles..."
    if [[ -d "$CONFIG_DIR" ]]; then
        log info "Updating configuration directory..."
        sudo -u "$USER_NAME" git -C "$CONFIG_DIR" pull
    else
        sudo -u "$USER_NAME" git clone "$CONFIG_REPO" "$CONFIG_DIR"
    fi
    sudo -u "$USER_NAME" bash -c "mkdir -p \"$USER_HOME/.config/kitty\" \"$USER_HOME/.config/alacritty\""
    sudo -u "$USER_NAME" cp -r "$CONFIG_DIR/dotfiles/zshrc" "$USER_HOME/.zshrc"
    sudo -u "$USER_NAME" cp -r "$CONFIG_DIR/dotfiles/tmux.conf" "$USER_HOME/.tmux.conf"
    sudo -u "$USER_NAME" cp -r "$CONFIG_DIR/dotfiles/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf"
    sudo -u "$USER_NAME" cp -r "$CONFIG_DIR/dotfiles/alacritty.toml" "$USER_HOME/.config/alacritty/alacritty.toml"
    chown -R "$USER_NAME:$USER_NAME" "$USER_HOME"
    log success "Dotfiles copied."
}

# Install Warp
install_warp() {
    command -v warp &> /dev/null && { log warning "Warp already installed."; return; }
    log info "Installing Warp..."
    wget -q --show-progress -O "$WARP_PLUS_ZIP" "$WARP_PLUS_URL"
    mkdir -p "$WARP_PLUS_DIR"
    unzip -q "$WARP_PLUS_ZIP" -d "$WARP_PLUS_DIR"
    mv "$WARP_PLUS_DIR/warp-plus" /usr/local/bin/warp
    rm -rf "$WARP_PLUS_ZIP" "$WARP_PLUS_DIR"
    chmod +x /usr/local/bin/warp
    warp --version &> /dev/null || { log error "Warp installation failed."; exit 1; }
    log success "Warp installed."
}

# Main function
main() {
    trap 'log error "Script interrupted."; exit 1' INT TERM
    check_prerequisites
    set_iranian_repos
    update_system
    setup_dns

    local packages=(
        apt-transport-https ca-certificates curl gpg xclip python3 python3-pip
        vim zsh git wget fzf autojump tmux tor kitty
    )
    for pkg in "${packages[@]}"; do
        install_package "$pkg"
    done

    $NO_VSCODE || command -v code &> /dev/null || install_deb_package "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    $NO_CHROME || command -v google-chrome &> /dev/null || install_deb_package "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

    install_rust
    install_alacritty
    install_pyenv
    install_sdkman
    install_docker
    install_oh_my_zsh
    install_warp
    copy_config_files

    log success "Setup complete. Log out and back in to apply changes."
}

parse_args "$@"
main
