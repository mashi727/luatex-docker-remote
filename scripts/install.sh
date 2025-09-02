#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${HOME}/.config/luatex"
BIN_DIR="${HOME}/.local/bin"

# Parse arguments
ACTION="install"
if [[ "$1" == "--update" ]]; then
    ACTION="update"
elif [[ "$1" == "--uninstall" ]]; then
    ACTION="uninstall"
fi

# Functions
log() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Uninstall function
uninstall() {
    log "Uninstalling LaTeX Docker Remote Compiler..."
    
    # Remove symlinks
    for cmd in luatex-pdf pdflatex-pdf platex-pdf uplatex-pdf xelatex-pdf; do
        rm -f "$BIN_DIR/$cmd"
    done
    
    # Ask about config files
    read -p "Remove configuration files? [y/N]: " remove_config
    if [[ "$remove_config" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        log "Configuration files removed"
    else
        log "Configuration files preserved"
    fi
    
    log "Uninstallation complete"
}

# Update function
update() {
    log "Updating LaTeX Docker Remote Compiler..."
    
    # Update symlinks
    COMPILE_SCRIPT="$SCRIPT_DIR/luatex-compile.sh"
    for cmd in luatex-pdf pdflatex-pdf platex-pdf uplatex-pdf xelatex-pdf; do
        ln -sf "$COMPILE_SCRIPT" "$BIN_DIR/$cmd"
    done
    
    log "Update complete"
}

# Install function
install() {
    echo ""
    echo "======================================"
    echo " LaTeX Docker Remote Compiler Setup"
    echo "======================================"
    echo ""
    
    # Create directories
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$BIN_DIR"
    
    # Check if config already exists
    if [[ -f "$CONFIG_DIR/config" ]]; then
        warn "Configuration file already exists: $CONFIG_DIR/config"
        read -p "Do you want to reconfigure? [y/N]: " reconfigure
        if [[ ! "$reconfigure" =~ ^[Yy]$ ]]; then
            log "Keeping existing configuration"
            update
            return
        fi
    fi
    
    # Compilation method selection
    echo ""
    echo "How do you want to configure LaTeX compilation?"
    echo ""
    echo "1) Remote Docker only (traditional setup)"
    echo "   - Compile on remote server with Docker"
    echo "   - Requires SSH access to Docker host"
    echo ""
    echo "2) Local Docker only (local builds)"
    echo "   - Compile using Docker on this machine"
    echo "   - Requires Docker to be installed locally"
    echo ""
    echo "3) Both local and remote (flexible)"
    echo "   - Default to remote, use -L flag for local"
    echo "   - Best for varying compilation needs"
    echo ""
    read -p "Enter your choice [1-3]: " compile_choice
    
    local use_remote=false
    local use_local=false
    local ssh_choice=""
    
    case "$compile_choice" in
        1)
            use_remote=true
            ;;
        2)
            use_local=true
            ;;
        3)
            use_remote=true
            use_local=true
            ;;
        *)
            error "Invalid choice"
            exit 1
            ;;
    esac
    
    # Configure remote if selected
    if [ "$use_remote" = true ]; then
        echo ""
        echo "Configure remote Docker host:"
        echo ""
        echo "1) Use ~/.ssh/config (recommended for security)"
        echo "   - Uses SSH key authentication"
        echo "   - No passwords stored"
        echo "   - Configured in ~/.ssh/config"
        echo ""
        echo "2) Enter remote server credentials"
        echo "   - Traditional username/host configuration"
        echo "   - Compatible with existing setups"
        echo "   - Requires SSH keys to be already configured"
        echo ""
        read -p "Enter your choice [1-2]: " ssh_choice
    fi
    
    # Handle local-only configuration
    if [ "$use_local" = true ] && [ "$use_remote" = false ]; then
        # Local Docker only configuration
        cat > "$CONFIG_DIR/config" << EOF
# LaTeX Docker Remote Compiler Configuration
# Generated on $(date)

# Local Docker only mode
USE_LOCAL_DOCKER=true

# Docker image
DOCKER_IMAGE=luatex:latest

# Config directory
CONFIG_DIR=$CONFIG_DIR
EOF
        log "Local Docker configuration completed"
    elif [ -n "$ssh_choice" ]; then
        case "$ssh_choice" in
            1)
            # SSH config method
            echo ""
            log "Using SSH config for authentication"
            USE_SSH_CONFIG="true"
            
            # Show available hosts
            if [[ -f ~/.ssh/config ]]; then
                echo ""
                echo "Available SSH hosts in ~/.ssh/config:"
                grep "^Host " ~/.ssh/config 2>/dev/null | grep -v "\*" | sed 's/Host /  - /' || echo "  No hosts found"
            else
                warn "No ~/.ssh/config file found"
                echo "You'll need to create one with your host configurations"
            fi
            
            echo ""
            read -p "Enter default SSH host name from ~/.ssh/config: " SSH_HOST_DEFAULT
            
            # Network-specific hosts
            echo ""
            echo "Network-specific hosts (press Enter to use default for all):"
            read -p "  Internal network host [$SSH_HOST_DEFAULT]: " SSH_HOST_INTERNAL
            SSH_HOST_INTERNAL=${SSH_HOST_INTERNAL:-$SSH_HOST_DEFAULT}
            
            read -p "  External network host [$SSH_HOST_DEFAULT]: " SSH_HOST_EXTERNAL
            SSH_HOST_EXTERNAL=${SSH_HOST_EXTERNAL:-$SSH_HOST_DEFAULT}
            
            # Create config file for SSH config method
            cat > "$CONFIG_DIR/config" << EOF
# LaTeX Docker Remote Compiler Configuration
# Generated on $(date)

# Use SSH config for authentication
USE_SSH_CONFIG=$USE_SSH_CONFIG

# Default SSH host (from ~/.ssh/config)
SSH_HOST_DEFAULT=$SSH_HOST_DEFAULT

# Network-specific hosts
SSH_HOST_INTERNAL=$SSH_HOST_INTERNAL
SSH_HOST_EXTERNAL=$SSH_HOST_EXTERNAL

# Enable network detection
ENABLE_NETWORK_DETECTION=true

# Docker image
DOCKER_IMAGE=luatex:latest

# Local Docker support
USE_LOCAL_DOCKER=$use_local

# Config directory
CONFIG_DIR=$CONFIG_DIR
EOF
            ;;
            
        2)
            # Traditional method (original)
            echo ""
            log "Using traditional server credentials"
            USE_SSH_CONFIG="false"
            
            # Get remote server information
            read -p "Enter remote username: " REMOTE_USER
            read -p "Enter remote host/IP for internal network: " REMOTE_HOST_INTERNAL
            read -p "Enter remote host/IP for external network [$REMOTE_HOST_INTERNAL]: " REMOTE_HOST_EXTERNAL
            REMOTE_HOST_EXTERNAL=${REMOTE_HOST_EXTERNAL:-$REMOTE_HOST_INTERNAL}
            
            # SSH port configuration
            read -p "Enter SSH port for internal network [22]: " SSH_PORT_INTERNAL
            SSH_PORT_INTERNAL=${SSH_PORT_INTERNAL:-22}
            
            read -p "Enter SSH port for external network [22]: " SSH_PORT_EXTERNAL
            SSH_PORT_EXTERNAL=${SSH_PORT_EXTERNAL:-22}
            
            # Create config file for traditional method
            cat > "$CONFIG_DIR/config" << EOF
# LaTeX Docker Remote Compiler Configuration
# Generated on $(date)

# Use traditional authentication (not SSH config)
USE_SSH_CONFIG=$USE_SSH_CONFIG

# Remote user
REMOTE_USER=$REMOTE_USER

# Remote hosts
REMOTE_HOST=$REMOTE_HOST_INTERNAL
REMOTE_HOST_INTERNAL=$REMOTE_HOST_INTERNAL
REMOTE_HOST_EXTERNAL=$REMOTE_HOST_EXTERNAL

# SSH ports
SSH_PORT_INTERNAL=$SSH_PORT_INTERNAL
SSH_PORT_EXTERNAL=$SSH_PORT_EXTERNAL

# Enable network detection
ENABLE_NETWORK_DETECTION=true

# Docker image
DOCKER_IMAGE=luatex:latest

# Local Docker support
USE_LOCAL_DOCKER=$use_local

# Config directory
CONFIG_DIR=$CONFIG_DIR
EOF
            
            # Save external port if different
            if [[ "$SSH_PORT_EXTERNAL" != "22" ]]; then
                echo "$SSH_PORT_EXTERNAL" > ~/.port_for_ssh
            fi
            
            # Remind about SSH keys
            echo ""
            warn "Important: Make sure SSH key authentication is set up:"
            echo "  ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST_INTERNAL}"
            if [[ "$REMOTE_HOST_EXTERNAL" != "$REMOTE_HOST_INTERNAL" ]]; then
                echo "  ssh-copy-id -p $SSH_PORT_EXTERNAL ${REMOTE_USER}@${REMOTE_HOST_EXTERNAL}"
            fi
                ;;
                
            *)
                error "Invalid choice"
                exit 1
                ;;
        esac
    fi
    
    # Network detection setup
    echo ""
    read -p "Do you want to set up automatic network detection? [Y/n]: " setup_network
    if [[ ! "$setup_network" =~ ^[Nn]$ ]]; then
        echo ""
        log "Setting up network detection..."
        echo "Detecting current global IP..."
        CURRENT_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null)
        if [[ -n "$CURRENT_IP" ]]; then
            echo "Current global IP: $CURRENT_IP"
            read -p "Is this your home/internal network? [Y/n]: " is_home
            if [[ ! "$is_home" =~ ^[Nn]$ ]]; then
                echo "$CURRENT_IP" > ~/.home_global_ip
                log "Home IP saved for network detection"
            fi
        else
            warn "Could not detect current IP"
        fi
    fi
    
    # Create symlinks
    log "Creating command symlinks..."
    COMPILE_SCRIPT="$SCRIPT_DIR/luatex-compile.sh"
    
    for cmd in luatex-pdf pdflatex-pdf platex-pdf uplatex-pdf xelatex-pdf; do
        ln -sf "$COMPILE_SCRIPT" "$BIN_DIR/$cmd"
        log "  Created: $cmd"
    done
    
    # Check PATH
    if ! echo "$PATH" | grep -q "$BIN_DIR"; then
        echo ""
        warn "$BIN_DIR is not in your PATH"
        echo ""
        echo "To use the commands, add the following to your shell configuration:"
        echo ""
        # Detect current shell
        if [[ "$SHELL" == *"zsh"* ]]; then
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
            echo "  source ~/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]]; then
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo "  source ~/.bashrc"
        else
            echo "  # For bash:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
            echo ""
            echo "  # For zsh:"
            echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
        fi
        echo ""
    else
        log "$BIN_DIR is already in PATH ✓"
    fi
    
    # Test connection (only for remote configurations)
    if [ "$use_remote" = true ]; then
        echo ""
        read -p "Do you want to test the connection now? [Y/n]: " test_conn
        if [[ ! "$test_conn" =~ ^[Nn]$ ]]; then
            echo ""
            log "Testing connection..."
            
            if [[ "$USE_SSH_CONFIG" == "true" ]]; then
                # Test with SSH config
                if ssh "$SSH_HOST_DEFAULT" "echo 'Connection successful!'" 2>/dev/null; then
                    log "Connection to $SSH_HOST_DEFAULT successful!"
                else
                    error "Connection to $SSH_HOST_DEFAULT failed"
                    echo "Please check your ~/.ssh/config and SSH keys"
                fi
            else
                # Test with traditional method
                if ssh "${REMOTE_USER}@${REMOTE_HOST_INTERNAL}" "echo 'Connection successful!'" 2>/dev/null; then
                    log "Connection to ${REMOTE_HOST_INTERNAL} successful!"
                else
                    error "Connection to ${REMOTE_HOST_INTERNAL} failed"
                    echo "Please set up SSH keys: ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST_INTERNAL}"
                fi
            fi
        fi
    elif [ "$use_local" = true ] && [ "$use_remote" = false ]; then
        echo ""
        read -p "Do you want to test local Docker now? [Y/n]: " test_docker
        if [[ ! "$test_docker" =~ ^[Nn]$ ]]; then
            echo ""
            log "Testing local Docker..."
            
            if command -v docker >/dev/null 2>&1; then
                if docker info >/dev/null 2>&1; then
                    log "Local Docker is running successfully!"
                else
                    warn "Docker is installed but the daemon is not running"
                    echo "Please start Docker and try again"
                fi
            else
                error "Docker is not installed"
                echo "Please install Docker Desktop or Docker Engine"
            fi
        fi
    fi
    
    echo ""
    log "Installation complete!"
    echo ""
    echo "Usage examples:"
    if [ "$use_local" = true ] && [ "$use_remote" = false ]; then
        echo "  luatex-pdf document.tex           # Compile with local Docker"
        echo "  luatex-pdf -v document.tex        # Verbose output"
        echo "  luatex-pdf -w document.tex        # Watch mode"
    elif [ "$use_remote" = true ] && [ "$use_local" = false ]; then
        echo "  luatex-pdf document.tex           # Compile with remote Docker"
        echo "  luatex-pdf -H zeus-external document.tex  # Use specific host"
        echo "  luatex-pdf -v document.tex        # Verbose output"
    else
        echo "  luatex-pdf document.tex           # Remote Docker (default)"
        echo "  luatex-pdf -L document.tex        # Local Docker"
        echo "  luatex-pdf -H zeus-external document.tex  # Specific remote host"
        echo "  luatex-pdf -v document.tex        # Verbose output"
    fi
    echo ""
}

# Main execution
case "$ACTION" in
    install)
        install
        ;;
    update)
        update
        ;;
    uninstall)
        uninstall
        ;;
esac