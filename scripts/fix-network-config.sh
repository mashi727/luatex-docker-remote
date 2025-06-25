#!/bin/bash
# fix-network-config.sh - Fix missing network configuration

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== Fixing Network Configuration ===${NC}"
echo ""

# Create config directory if not exists
mkdir -p ~/.config/luatex

# Create network-config file
cat > ~/.config/luatex/network-config << EOF
# Network configuration for luatex-docker-remote
# Generated on $(date)

# Enable automatic network detection
ENABLE_NETWORK_DETECTION=true

# Hostnames
REMOTE_HOST_INTERNAL="zeus"
REMOTE_HOST_EXTERNAL="zeus-soto"

# Default user
REMOTE_USER="mashi"

# Docker image
DOCKER_IMAGE="luatex:latest"
EOF

echo -e "${GREEN}✓${NC} Created ~/.config/luatex/network-config"
echo ""

# Update main config to ensure consistency
if [ -f ~/.config/luatex/config ]; then
    echo -e "${BLUE}Updating main config...${NC}"
    # Backup original
    cp ~/.config/luatex/config ~/.config/luatex/config.backup
    
    # Update with correct values
    cat > ~/.config/luatex/config << EOF
# LuaTeX Docker Configuration
REMOTE_HOST="zeus"
DOCKER_IMAGE="luatex:latest"
CONFIG_DIR="$HOME/.config/luatex"
CACHE_DIR="$HOME/.cache/luatex"
REMOTE_USER="mashi"
EOF
    echo -e "${GREEN}✓${NC} Updated ~/.config/luatex/config"
fi

echo ""
echo -e "${GREEN}Configuration fixed!${NC}"
echo ""
echo "Network settings:"
echo "  Internal host: zeus"
echo "  External host: zeus-soto"
echo "  SSH port (external): 10022"
echo "  Current network: External"
echo ""
echo -e "${YELLOW}Now try compiling again:${NC}"
echo -e "${BLUE}uplatex-pdf ukraine.tex${NC}"
echo ""
echo "Or test with the minimal example:"
echo -e "${BLUE}./test-compile.sh${NC}"
