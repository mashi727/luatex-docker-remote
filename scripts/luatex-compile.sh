#!/bin/bash
# luatex-compile.sh - Network-aware remote LuaTeX compilation

set -euo pipefail

# Load config
CONFIG_FILE="${HOME}/.config/luatex/config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Network detection settings
HOME_GLOBAL_IP_FILE="${HOME}/.home_global_ip"
SSH_PORT_FILE="${HOME}/.port_for_ssh"
NETWORK_CONFIG_FILE="${HOME}/.config/luatex/network-config"

# Load network config if exists
[ -f "$NETWORK_CONFIG_FILE" ] && source "$NETWORK_CONFIG_FILE"

# Function to detect network and set host
detect_network_and_set_host() {
    # Check if network detection is enabled
    if [ "${ENABLE_NETWORK_DETECTION:-true}" != "true" ]; then
        # Use default host
        REMOTE_HOST="${REMOTE_HOST:-zeus}"
        return
    fi
    
    # Check if home IP file exists
    if [ ! -f "$HOME_GLOBAL_IP_FILE" ]; then
        # Fallback to default
        REMOTE_HOST="${REMOTE_HOST:-zeus}"
        return
    fi
    
    # Get current and home IPs
    local current_ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "")
    local home_ip=$(cat "$HOME_GLOBAL_IP_FILE" 2>/dev/null || echo "")
    
    if [ -z "$current_ip" ]; then
        # Cannot determine current IP, use default
        warn "Cannot determine current IP, using default host"
        REMOTE_HOST="${REMOTE_HOST:-zeus}"
        return
    fi
    
    # Determine host based on network
    if [ "$current_ip" = "$home_ip" ]; then
        # At home - use internal hostname
        REMOTE_HOST="${REMOTE_HOST_INTERNAL:-zeus}"
        log "Detected home network, using internal host: $REMOTE_HOST"
    else
        # Outside - use external hostname
        REMOTE_HOST="${REMOTE_HOST_EXTERNAL:-zeus-soto}"
        log "Detected external network, using external host: $REMOTE_HOST"
    fi
    
    # Set SSH port if specified
    if [ -f "$SSH_PORT_FILE" ] && [ "$REMOTE_HOST" = "${REMOTE_HOST_EXTERNAL:-zeus-soto}" ]; then
        SSH_PORT=$(cat "$SSH_PORT_FILE")
        export SSH_OPTIONS="-p $SSH_PORT"
    fi
}

# Override SSH command if needed
ssh_exec() {
    ssh ${SSH_OPTIONS:-} "${REMOTE_USER}@${REMOTE_HOST}" "$@"
}

scp_exec() {
    scp ${SSH_OPTIONS:-} "$@"
}

rsync_exec() {
    rsync -e "ssh ${SSH_OPTIONS:-}" "$@"
}

# Defaults (before network detection)
REMOTE_USER="${REMOTE_USER:-$USER}"
DOCKER_IMAGE="${DOCKER_IMAGE:-luatex:latest}"
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/luatex}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[LuaTeX]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Help
usage() {
    cat << HELP
Usage: $(basename "$0") [OPTIONS] <tex-file>

Compile LaTeX with LuaTeX on remote Docker.
Automatically detects network and switches between internal/external hosts.

Options:
    -h, --help         Show help
    -v, --verbose      Verbose output
    -w, --watch        Watch mode
    -c, --clean        Clean after compile
    -k, --keep         Keep auxiliary files
    -H, --host HOST    Force specific host (overrides auto-detection)
    --no-auto-detect   Disable automatic network detection

Network Configuration:
    ~/.home_global_ip     - Your home network's global IP
    ~/.port_for_ssh       - SSH port for external access
    ~/.config/luatex/network-config - Network settings

Examples:
    $(basename "$0") document.tex
    $(basename "$0") -w thesis.tex
    $(basename "$0") -H zeus-internal document.tex

HELP
}

# Parse options
VERBOSE=false
WATCH_MODE=false
CLEAN_AFTER=false
KEEP_FILES=false
TEX_FILE=""
FORCE_HOST=""
AUTO_DETECT=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        -c|--clean)
            CLEAN_AFTER=true
            shift
            ;;
        -k|--keep)
            KEEP_FILES=true
            shift
            ;;
        -H|--host)
            FORCE_HOST="$2"
            shift 2
            ;;
        --no-auto-detect)
            AUTO_DETECT=false
            shift
            ;;
        *)
            TEX_FILE="$1"
            shift
            ;;
    esac
done

# Validate
if [ -z "$TEX_FILE" ]; then
    error "No TeX file specified"
    usage
    exit 1
fi

if [ ! -f "$TEX_FILE" ]; then
    error "File not found: $TEX_FILE"
    exit 1
fi

# Network detection
if [ -n "$FORCE_HOST" ]; then
    REMOTE_HOST="$FORCE_HOST"
    log "Using forced host: $REMOTE_HOST"
elif [ "$AUTO_DETECT" = true ]; then
    detect_network_and_set_host
else
    REMOTE_HOST="${REMOTE_HOST:-zeus}"
fi

# File info
TEX_DIR=$(dirname "$(realpath "$TEX_FILE")")
TEX_BASE=$(basename "$TEX_FILE" .tex)
TEX_NAME=$(basename "$TEX_FILE")
WORK_DIR="/tmp/luatex-$$-$(date +%s)"

# Cleanup
cleanup() {
    if [ "$CLEAN_AFTER" = true ]; then
        rm -f "$TEX_DIR"/*.{aux,log,toc,out,bbl,blg,fls,fdb_latexmk}
    fi
    ssh_exec "rm -rf '$WORK_DIR'" 2>/dev/null || true
}
trap cleanup EXIT

# Test connection
test_connection() {
    log "Testing connection to $REMOTE_HOST..."
    if ! ssh_exec "echo 'Connection OK'" >/dev/null 2>&1; then
        error "Cannot connect to $REMOTE_HOST"
        if [ "$AUTO_DETECT" = true ]; then
            warn "Try using -H option to specify host manually"
        fi
        exit 1
    fi
}

# Sync files
sync_files() {
    log "Syncing files to $REMOTE_HOST..."
    
    # Create remote dir
    ssh_exec "mkdir -p '$WORK_DIR'"
    
    # Sync project files
    rsync_exec -az \
        --include="*.tex" --include="*.sty" --include="*.cls" \
        --include="*.bib" --include="*.bst" \
        --include="*.png" --include="*.jpg" --include="*.jpeg" --include="*.pdf" \
        --include="*.eps" --include="*/" \
        --exclude="*" \
        "$TEX_DIR/" "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/"
    
    # Sync shared styles
    if [ -d "${CONFIG_DIR}/styles" ]; then
        ssh_exec "mkdir -p $WORK_DIR/.config/luatex"
        rsync_exec -az "${CONFIG_DIR}/styles/" \
            "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/.config/luatex/styles/"
    fi
}

# Compile
compile() {
    log "Compiling $TEX_NAME..."
    
    local cmd="docker run --rm"
    cmd="$cmd -v '$WORK_DIR:/workspace'"
    cmd="$cmd -w /workspace"
    cmd="$cmd -e TEXINPUTS='.:/workspace//:/workspace/.config/luatex/styles//:'"
    cmd="$cmd $DOCKER_IMAGE"
    
    if [ "$VERBOSE" = true ]; then
        cmd="$cmd latexmk -lualatex -verbose '$TEX_NAME'"
    else
        cmd="$cmd latexmk -lualatex -quiet '$TEX_NAME'"
    fi
    
    if ssh_exec "$cmd"; then
        log "Success!"
        return 0
    else
        error "Compilation failed"
        return 1
    fi
}

# Get results
retrieve() {
    log "Retrieving PDF from $REMOTE_HOST..."
    
    scp_exec "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/$TEX_BASE.pdf" \
        "$TEX_DIR/" 2>/dev/null || \
    scp_exec "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/build/$TEX_BASE.pdf" \
        "$TEX_DIR/" 2>/dev/null || {
        error "Failed to retrieve PDF"
        return 1
    }
    
    if [ "$KEEP_FILES" = true ]; then
        rsync_exec -az \
            --include="*.aux" --include="*.log" --include="*.toc" \
            --include="*.bbl" --include="*.blg" \
            --exclude="*" \
            "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/" \
            "$TEX_DIR/"
    fi
}

# Main
main() {
    # Test connection first
    test_connection
    
    if [ "$WATCH_MODE" = true ]; then
        log "Watch mode. Press Ctrl+C to stop."
        while true; do
            sync_files
            compile && retrieve || true
            
            if command -v inotifywait >/dev/null 2>&1; then
                inotifywait -q -e modify,create "$TEX_DIR"/*.{tex,sty,cls} || break
            else
                sleep 5
            fi
        done
    else
        sync_files
        compile
        retrieve
        log "Output: $TEX_DIR/$TEX_BASE.pdf"
    fi
}

main