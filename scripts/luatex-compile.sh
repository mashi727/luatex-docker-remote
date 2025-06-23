#!/bin/bash
# luatex-compile.sh - Remote LuaTeX compilation

set -euo pipefail

# Load config
CONFIG_FILE="${HOME}/.config/luatex/config"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

# Defaults
REMOTE_HOST="${REMOTE_HOST:-zeus}"
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

Options:
    -h, --help       Show help
    -v, --verbose    Verbose output
    -w, --watch      Watch mode
    -c, --clean      Clean after compile
    -k, --keep       Keep auxiliary files

Examples:
    $(basename "$0") document.tex
    $(basename "$0") -w thesis.tex

HELP
}

# Parse options
VERBOSE=false
WATCH_MODE=false
CLEAN_AFTER=false
KEEP_FILES=false
TEX_FILE=""

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
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "rm -rf '$WORK_DIR'" 2>/dev/null || true
}
trap cleanup EXIT

# Sync files
sync_files() {
    log "Syncing files..."
    
    # Create remote dir
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '$WORK_DIR'"
    
    # Sync project files
    rsync -az \
        --include="*.tex" --include="*.sty" --include="*.cls" \
        --include="*.bib" --include="*.bst" \
        --include="*.png" --include="*.jpg" --include="*.jpeg" --include="*.pdf" \
        --include="*.eps" --include="*/" \
        --exclude="*" \
        "$TEX_DIR/" "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/"
    
    # Sync shared styles
    if [ -d "${CONFIG_DIR}/styles" ]; then
        ssh "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p $WORK_DIR/.config/luatex"
        rsync -az "${CONFIG_DIR}/styles/" \
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
    
    if ssh "${REMOTE_USER}@${REMOTE_HOST}" "$cmd"; then
        log "Success!"
        return 0
    else
        error "Compilation failed"
        return 1
    fi
}

# Get results
retrieve() {
    log "Retrieving PDF..."
    
    scp "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/$TEX_BASE.pdf" \
        "$TEX_DIR/" 2>/dev/null || \
    scp "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/build/$TEX_BASE.pdf" \
        "$TEX_DIR/" 2>/dev/null || {
        error "Failed to retrieve PDF"
        return 1
    }
    
    if [ "$KEEP_FILES" = true ]; then
        rsync -az \
            --include="*.aux" --include="*.log" --include="*.toc" \
            --include="*.bbl" --include="*.blg" \
            --exclude="*" \
            "${REMOTE_USER}@${REMOTE_HOST}:$WORK_DIR/" \
            "$TEX_DIR/"
    fi
}

# Main
main() {
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
