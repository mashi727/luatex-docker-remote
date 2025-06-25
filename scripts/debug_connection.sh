#!/bin/bash
# debug-connection.sh - Debug network and SSH connection issues

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== LuaTeX Docker Remote Connection Debugger ===${NC}"
echo ""

# Load configurations
CONFIG_FILE="${HOME}/.config/luatex/config"
NETWORK_CONFIG="${HOME}/.config/luatex/network-config"
HOME_IP_FILE="${HOME}/.home_global_ip"
SSH_PORT_FILE="${HOME}/.port_for_ssh"

# Check configuration files
echo -e "${BLUE}1. Checking configuration files:${NC}"
for file in "$CONFIG_FILE" "$NETWORK_CONFIG" "$HOME_IP_FILE"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file exists"
    else
        echo -e "  ${RED}✗${NC} $file not found"
    fi
done
echo ""

# Load network config
if [ -f "$NETWORK_CONFIG" ]; then
    source "$NETWORK_CONFIG"
    echo -e "${BLUE}2. Network configuration:${NC}"
    echo "  Internal host: ${REMOTE_HOST_INTERNAL:-not set}"
    echo "  External host: ${REMOTE_HOST_EXTERNAL:-not set}"
    echo "  Remote user: ${REMOTE_USER:-$USER}"
    echo ""
fi

# Check current network
echo -e "${BLUE}3. Network detection:${NC}"
CURRENT_IP=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "unknown")
echo "  Current IP: $CURRENT_IP"

if [ -f "$HOME_IP_FILE" ]; then
    HOME_IP=$(cat "$HOME_IP_FILE")
    echo "  Home IP: $HOME_IP"
    
    if [ "$CURRENT_IP" = "$HOME_IP" ]; then
        echo -e "  ${GREEN}✓${NC} You are at home (internal network)"
        DETECTED_HOST="${REMOTE_HOST_INTERNAL:-zeus}"
    else
        echo -e "  ${YELLOW}!${NC} You are outside (external network)"
        DETECTED_HOST="${REMOTE_HOST_EXTERNAL:-zeus-soto}"
    fi
    echo "  Detected host: $DETECTED_HOST"
else
    echo -e "  ${RED}✗${NC} Home IP not configured"
fi
echo ""

# Check SSH configuration
echo -e "${BLUE}4. SSH configuration:${NC}"
if [ -f "$SSH_PORT_FILE" ]; then
    SSH_PORT=$(cat "$SSH_PORT_FILE")
    echo "  Custom SSH port: $SSH_PORT"
    SSH_OPTIONS="-p $SSH_PORT"
else
    echo "  Using default SSH port (22)"
    SSH_OPTIONS=""
fi

# Check SSH config file
if [ -f "${HOME}/.ssh/config" ]; then
    echo -e "  ${GREEN}✓${NC} SSH config file exists"
    if [ -n "${DETECTED_HOST:-}" ]; then
        echo ""
        echo "  Relevant SSH config for $DETECTED_HOST:"
        grep -A 5 "^Host.*$DETECTED_HOST" ~/.ssh/config 2>/dev/null || echo "    No specific config found"
    fi
else
    echo -e "  ${YELLOW}!${NC} No SSH config file"
fi
echo ""

# Test connections
echo -e "${BLUE}5. Testing SSH connections:${NC}"
for host in ${REMOTE_HOST_INTERNAL:-zeus} ${REMOTE_HOST_EXTERNAL:-zeus-soto}; do
    echo -n "  Testing $host... "
    
    # Determine if we need custom port
    if [ "$host" = "${REMOTE_HOST_EXTERNAL:-zeus-soto}" ] && [ -f "$SSH_PORT_FILE" ]; then
        TEST_OPTIONS="-p $(cat $SSH_PORT_FILE)"
    else
        TEST_OPTIONS=""
    fi
    
    if ssh -o ConnectTimeout=5 -o BatchMode=yes $TEST_OPTIONS "${REMOTE_USER:-$USER}@$host" echo "OK" 2>/dev/null; then
        echo -e "${GREEN}✓ Connected${NC}"
        
        # Test Docker
        echo -n "    Docker check... "
        if ssh $TEST_OPTIONS "${REMOTE_USER:-$USER}@$host" "docker --version" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker available${NC}"
        else
            echo -e "${RED}✗ Docker not available${NC}"
        fi
        
        # Test Docker image
        echo -n "    LuaTeX image... "
        if ssh $TEST_OPTIONS "${REMOTE_USER:-$USER}@$host" "docker images | grep -q luatex" 2>/dev/null; then
            echo -e "${GREEN}✓ Image exists${NC}"
        else
            echo -e "${RED}✗ Image not found${NC}"
        fi
    else
        echo -e "${RED}✗ Connection failed${NC}"
        echo "    Try: ssh -v $TEST_OPTIONS ${REMOTE_USER:-$USER}@$host"
    fi
done
echo ""

# Recommendations
echo -e "${GREEN}=== Recommendations ===${NC}"
echo ""

if [ "$CURRENT_IP" != "${HOME_IP:-}" ] && [ -n "${DETECTED_HOST:-}" ]; then
    echo "You are on an external network. Make sure:"
    echo "1. Port forwarding is configured on your router"
    echo "2. SSH is accessible from outside"
    echo "3. Firewall allows the connection"
    echo ""
    echo "Test manually:"
    echo -e "${BLUE}ssh ${SSH_OPTIONS:-} ${REMOTE_USER:-$USER}@${DETECTED_HOST}${NC}"
    echo ""
    echo "Or force internal host if on VPN:"
    echo -e "${BLUE}uplatex-pdf -H ${REMOTE_HOST_INTERNAL:-zeus} ukraine.tex${NC}"
fi

# Create test script
cat > test-compile.sh << 'EOF'
#!/bin/bash
# Quick test script
echo "Testing compilation with detected settings..."

# Force verbose mode and show log
luatex-pdf -v --show-log test.tex 2>&1 | tee compile-test.log

echo ""
echo "Check compile-test.log for details"
EOF

cat > test.tex << 'EOF'
\documentclass[uplatex,a4paper]{ujarticle}
\begin{document}
Test
\end{document}
EOF

chmod +x test-compile.sh

echo ""
echo "Created test files:"
echo "  - test.tex (minimal document)"
echo "  - test-compile.sh (test script)"
echo ""
echo "Run ./test-compile.sh to test compilation"
