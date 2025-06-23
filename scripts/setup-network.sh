#!/bin/bash
# setup-network.sh - Setup network configuration

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}Network Configuration Setup${NC}"
echo ""

# Create config directory
mkdir -p ~/.config/luatex

# Get current global IP
echo -e "${BLUE}Detecting current network...${NC}"
CURRENT_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "unknown")
echo "Current global IP: $CURRENT_IP"
echo ""

# Check if at home
read -p "Are you currently at home? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$CURRENT_IP" > ~/.home_global_ip
    echo -e "${GREEN}✓${NC} Saved home IP: $CURRENT_IP"
else
    read -p "Enter your home's global IP: " HOME_IP
    echo "$HOME_IP" > ~/.home_global_ip
    echo -e "${GREEN}✓${NC} Saved home IP: $HOME_IP"
fi

echo ""

# SSH port
read -p "Use custom SSH port for external access? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter SSH port: " SSH_PORT
    echo "$SSH_PORT" > ~/.port_for_ssh
    echo -e "${GREEN}✓${NC} Saved SSH port: $SSH_PORT"
fi

echo ""

# Hostnames
read -p "Internal hostname (default: zeus): " INTERNAL_HOST
INTERNAL_HOST=${INTERNAL_HOST:-zeus}

read -p "External hostname (default: zeus-soto): " EXTERNAL_HOST
EXTERNAL_HOST=${EXTERNAL_HOST:-zeus-soto}

# Create network config
cat > ~/.config/luatex/network-config << CONFIG
# Network configuration for luatex-docker-remote
ENABLE_NETWORK_DETECTION=true
REMOTE_HOST_INTERNAL="$INTERNAL_HOST"
REMOTE_HOST_EXTERNAL="$EXTERNAL_HOST"
REMOTE_USER="${USER}"
CONFIG

echo -e "${GREEN}✓${NC} Network configuration complete!"
echo ""
echo "Test with: luatex-pdf -v test.tex"
