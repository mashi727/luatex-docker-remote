#!/bin/bash
# build-docker.sh - Build Docker image on remote host

set -euo pipefail

# Load network config if exists
NETWORK_CONFIG="${HOME}/.config/luatex/network-config"
[ -f "$NETWORK_CONFIG" ] && source "$NETWORK_CONFIG"

# Auto-detect network if config exists
if [ -f "${HOME}/.home_global_ip" ]; then
    CURRENT_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "")
    HOME_IP=$(cat "${HOME}/.home_global_ip" 2>/dev/null || echo "")
    
    if [ "$CURRENT_IP" = "$HOME_IP" ]; then
        REMOTE_HOST="${REMOTE_HOST_INTERNAL:-zeus}"
    else
        REMOTE_HOST="${REMOTE_HOST_EXTERNAL:-zeus-soto}"
    fi
else
    REMOTE_HOST="${1:-zeus}"
fi

REMOTE_USER="${REMOTE_USER:-$USER}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Building Docker image on $REMOTE_HOST..."

# Set SSH options if needed
SSH_OPTIONS=""
if [ "$REMOTE_HOST" = "${REMOTE_HOST_EXTERNAL:-zeus-soto}" ] && [ -f "${HOME}/.port_for_ssh" ]; then
    SSH_PORT=$(cat "${HOME}/.port_for_ssh")
    SSH_OPTIONS="-p $SSH_PORT"
fi

# Sync files
rsync -e "ssh $SSH_OPTIONS" -az "$PROJECT_ROOT/docker/" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/luatex-docker-build/"

# Build
ssh $SSH_OPTIONS "${REMOTE_USER}@${REMOTE_HOST}" << 'REMOTE_BUILD'
cd /tmp/luatex-docker-build
docker build -t luatex:latest .
docker tag luatex:latest luatex:$(date +%Y%m%d)
rm -rf /tmp/luatex-docker-build
REMOTE_BUILD

echo "Build complete!"
