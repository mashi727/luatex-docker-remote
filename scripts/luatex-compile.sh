#!/bin/bash
# luatex-compile.sh - Fixed version with proper handling of special characters in filenames

set -euo pipefail

# Load config
CONFIG_FILE="${HOME}/.config/luatex/config"
NETWORK_CONFIG_FILE="${HOME}/.config/luatex/network-config"

# Load configurations
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
[ -f "$NETWORK_CONFIG_FILE" ] && source "$NETWORK_CONFIG_FILE"

# SSH host detection
detect_ssh_host() {
    local force_host="$1"
    
    if [ -n "$force_host" ]; then
        SSH_HOST="$force_host"
        return
    fi
    
    if [ "${USE_SSH_CONFIG:-false}" != "true" ]; then
        if [ "${ENABLE_NETWORK_DETECTION:-true}" != "true" ]; then
            REMOTE_HOST="${REMOTE_HOST:-zeus}"
            SSH_HOST="$REMOTE_HOST"
            return
        fi
        
        if [ ! -f "${HOME}/.home_global_ip" ]; then
            REMOTE_HOST="${REMOTE_HOST:-zeus}"
            SSH_HOST="$REMOTE_HOST"
            return
        fi
        
        local current_ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "")
        local home_ip=$(cat "${HOME}/.home_global_ip" 2>/dev/null || echo "")
        
        if [ -z "$current_ip" ]; then
            warn "Cannot determine current IP, using default host"
            REMOTE_HOST="${REMOTE_HOST:-zeus}"
        elif [ "$current_ip" = "$home_ip" ]; then
            REMOTE_HOST="${REMOTE_HOST_INTERNAL:-zeus}"
            log "Detected internal network, using: $REMOTE_HOST"
        else
            REMOTE_HOST="${REMOTE_HOST_EXTERNAL:-zeus-soto}"
            log "Detected external network, using: $REMOTE_HOST"
        fi
        
        SSH_HOST="$REMOTE_HOST"
        
        if [ -f "${HOME}/.port_for_ssh" ] && [ "$SSH_HOST" = "${REMOTE_HOST_EXTERNAL:-zeus-soto}" ]; then
            SSH_PORT=$(cat "${HOME}/.port_for_ssh")
            export SSH_OPTIONS="-p $SSH_PORT"
            export SCP_OPTIONS="-P $SSH_PORT"  # SCP uses uppercase -P
        fi
    else
        if [ "${ENABLE_NETWORK_DETECTION:-false}" != "true" ]; then
            SSH_HOST="${SSH_HOST_DEFAULT:-${SSH_HOST}}"
            return
        fi
        
        if [ -f "${HOME}/.home_global_ip" ]; then
            local current_ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "")
            local home_ip=$(cat "${HOME}/.home_global_ip" 2>/dev/null || echo "")
            
            if [ -z "$current_ip" ]; then
                warn "Cannot determine current IP, using default host"
                SSH_HOST="${SSH_HOST_DEFAULT:-${SSH_HOST}}"
            elif [ "$current_ip" = "$home_ip" ]; then
                SSH_HOST="${SSH_HOST_INTERNAL:-${SSH_HOST_DEFAULT}}"
                log "Detected internal network, using: $SSH_HOST"
            else
                SSH_HOST="${SSH_HOST_EXTERNAL:-${SSH_HOST_DEFAULT}}"
                log "Detected external network, using: $SSH_HOST"
            fi
        else
            SSH_HOST="${SSH_HOST_DEFAULT:-${SSH_HOST}}"
        fi
    fi
}

# SSH command wrapper
ssh_exec() {
    if [ "${USE_SSH_CONFIG:-false}" = "true" ]; then
        ssh "$SSH_HOST" "$@"
    else
        ssh ${SSH_OPTIONS:-} "${REMOTE_USER:-$USER}@${SSH_HOST}" "$@"
    fi
}

# SCP command wrapper - uses uppercase -P for port
scp_exec() {
    if [ "${USE_SSH_CONFIG:-false}" = "true" ]; then
        scp "$@"
    else
        scp ${SCP_OPTIONS:-} "$@"  # Use SCP_OPTIONS with -P
    fi
}

# Rsync command wrapper
rsync_exec() {
    if [ "${USE_SSH_CONFIG:-false}" = "true" ]; then
        rsync -e "ssh" "$@"
    else
        rsync -e "ssh ${SSH_OPTIONS:-}" "$@"  # SSH_OPTIONS for rsync's ssh
    fi
}

# Auto-detect engine from script name
SCRIPT_NAME=$(basename "$0")
case "$SCRIPT_NAME" in
    uplatex-pdf)
        DEFAULT_ENGINE="uplatex"
        ;;
    platex-pdf)
        DEFAULT_ENGINE="platex"
        ;;
    xelatex-pdf)
        DEFAULT_ENGINE="xelatex"
        ;;
    pdflatex-pdf)
        DEFAULT_ENGINE="pdflatex"
        ;;
    *)
        DEFAULT_ENGINE="lualatex"
        ;;
esac

ENGINE="${DEFAULT_ENGINE}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(echo $ENGINE | tr '[:lower:]' '[:upper:]')]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

# Help
usage() {
    cat << HELP
Usage: $(basename "$0") [OPTIONS] <tex-file>

Compile LaTeX with various engines on remote Docker.

Options:
    -h, --help         Show help
    -e, --engine       TeX engine (lualatex, uplatex, platex, xelatex, pdflatex)
    -v, --verbose      Verbose output
    -w, --watch        Watch mode
    -c, --clean        Clean after compile
    -k, --keep         Keep auxiliary files
    -H, --host HOST    Force specific host
    --show-log         Show compilation log on error
    --no-auto-detect   Disable automatic network detection

Supported engines:
    lualatex   - LuaLaTeX (default, Unicode, modern)
    uplatex    - upLaTeX (fast, Japanese)
    platex     - pLaTeX (legacy Japanese)
    xelatex    - XeLaTeX (Unicode, fonts)
    pdflatex   - pdfLaTeX (standard)

HELP
}

# Parse options
VERBOSE=false
WATCH_MODE=false
CLEAN_AFTER=false
KEEP_FILES=false
SHOW_LOG=false
TEX_FILE=""
FORCE_HOST=""
AUTO_DETECT=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -e|--engine)
            ENGINE="$2"
            shift 2
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
        --show-log)
            SHOW_LOG=true
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

# Validate engine
case "$ENGINE" in
    lualatex|uplatex|platex|xelatex|pdflatex)
        ;;
    *)
        error "Unknown engine: $ENGINE"
        echo "Supported engines: lualatex, uplatex, platex, xelatex, pdflatex"
        exit 1
        ;;
esac

# Detect SSH host
detect_ssh_host "$FORCE_HOST"

# File info
TEX_DIR=$(dirname "$(realpath "$TEX_FILE")")
TEX_BASE=$(basename "$TEX_FILE" .tex)
TEX_NAME=$(basename "$TEX_FILE")
WORK_DIR="/tmp/tex-compile-$$-$(date +%s)"

# Cleanup
cleanup() {
    if [ "$CLEAN_AFTER" = true ]; then
        rm -f "$TEX_DIR"/*.{aux,log,toc,out,bbl,blg,fls,fdb_latexmk,dvi,synctex.gz}
    fi
    ssh_exec "rm -rf '$WORK_DIR'" 2>/dev/null || true
}
trap cleanup EXIT

# Test connection
test_connection() {
    info "Testing connection to $SSH_HOST..."
    if ! ssh_exec "echo 'Connection OK'" >/dev/null 2>&1; then
        error "Cannot connect to $SSH_HOST"
        if [ "$AUTO_DETECT" = true ]; then
            warn "Try using -H option to specify host manually"
        fi
        exit 1
    fi
}

# Sync files using rsync
sync_files() {
    log "Syncing files to $SSH_HOST..."
    
    ssh_exec "mkdir -p '$WORK_DIR'"
    
    # Create a temporary directory for this specific tex file
    local temp_sync_dir="/tmp/tex-sync-$"
    mkdir -p "$temp_sync_dir"
    
    # Copy only the target tex file to temp dir
    cp "$TEX_FILE" "$temp_sync_dir/$TEX_NAME"
    
    # Copy supporting files from the original directory
    for ext in sty cls bib bst png jpg jpeg pdf eps svg bmp gif; do
        find "$TEX_DIR" -maxdepth 1 -name "*.$ext" -exec cp {} "$temp_sync_dir/" \; 2>/dev/null || true
    done
    
    # Use rsync to transfer everything from temp dir
    rsync_exec -az "$temp_sync_dir/" "${REMOTE_USER:-$USER}@${SSH_HOST}:$WORK_DIR/"
    
    # Clean up temp dir
    rm -rf "$temp_sync_dir"
    
    # Sync shared styles if they exist
    if [ -d "${CONFIG_DIR}/styles" ]; then
        ssh_exec "mkdir -p $WORK_DIR/.config/luatex/styles"
        rsync_exec -az "${CONFIG_DIR}/styles/" \
            "${REMOTE_USER:-$USER}@${SSH_HOST}:$WORK_DIR/.config/luatex/styles/"
    fi
}

# Compile with selected engine using latexmk
compile() {
    log "Compiling $TEX_NAME with $ENGINE on $SSH_HOST..."
    
    # Build latexmk options based on engine
    local latexmk_opts=""
    case "$ENGINE" in
        lualatex)
            latexmk_opts="-lualatex"
            ;;
        uplatex)
            # Create .latexmkrc file
            ssh_exec "echo '\$dvipdf = \"dvipdfmx %O -o %D %S\";' > '$WORK_DIR/.latexmkrc'"
            latexmk_opts="-latex='uplatex -synctex=1' -pdfdvi"
            ;;
        platex)
            # Create .latexmkrc file
            ssh_exec "echo '\$dvipdf = \"dvipdfmx %O -o %D %S\";' > '$WORK_DIR/.latexmkrc'"
            latexmk_opts="-latex='platex -synctex=1' -pdfdvi"
            ;;
        xelatex)
            latexmk_opts="-xelatex"
            ;;
        pdflatex)
            latexmk_opts="-pdf"
            ;;
    esac
    
    # Add verbose/quiet option
    if [ "$VERBOSE" = true ]; then
        latexmk_opts="$latexmk_opts -verbose"
    else
        latexmk_opts="$latexmk_opts -quiet"
    fi
    
    # Since we're only copying one tex file now, we can use a simpler approach
    # Just compile the first (and only) .tex file in the directory
    local docker_cmd="cd '$WORK_DIR' && docker run --rm -v '$WORK_DIR:/workspace' -w /workspace -e TEXINPUTS='.:/workspace//:/workspace/.config/luatex/styles//:' ${DOCKER_IMAGE:-luatex:latest} sh -c 'latexmk $latexmk_opts *.tex'"
    
    if ssh_exec "$docker_cmd"; then
        log "Compilation successful!"
        return 0
    else
        error "Compilation failed"
        
        if [ "$SHOW_LOG" = true ] || [ "$VERBOSE" = true ]; then
            echo ""
            warn "Showing compilation log:"
            ssh_exec "cat '$WORK_DIR/$TEX_BASE.log' 2>/dev/null | tail -50" || true
        else
            echo "Run with --show-log to see compilation errors"
        fi
        
        return 1
    fi
}

# Get results
retrieve() {
    log "Retrieving PDF from $SSH_HOST..."
    
    # Build the remote path based on whether we're using SSH config
    local remote_pdf=""
    local remote_pdf_build=""
    
    if [ "${USE_SSH_CONFIG:-false}" = "true" ]; then
        # When using SSH config, don't add user@
        remote_pdf="${SSH_HOST}:$WORK_DIR/$TEX_BASE.pdf"
        remote_pdf_build="${SSH_HOST}:$WORK_DIR/build/$TEX_BASE.pdf"
    else
        # When not using SSH config, add user@
        remote_pdf="${REMOTE_USER:-$USER}@${SSH_HOST}:$WORK_DIR/$TEX_BASE.pdf"
        remote_pdf_build="${REMOTE_USER:-$USER}@${SSH_HOST}:$WORK_DIR/build/$TEX_BASE.pdf"
    fi
    
    # Try to get PDF with properly quoted paths
    if scp_exec "$remote_pdf" "$TEX_DIR/" 2>/dev/null; then
        : # Success
    elif scp_exec "$remote_pdf_build" "$TEX_DIR/" 2>/dev/null; then
        : # Success from build directory
    else
        if [ ! -f "$TEX_DIR/$TEX_BASE.pdf" ]; then
            error "Failed to retrieve PDF"
            return 1
        fi
    fi
    
    # Retrieve auxiliary files if requested
    if [ "$KEEP_FILES" = true ]; then
        log "Retrieving auxiliary files..."
        if [ "${USE_SSH_CONFIG:-false}" = "true" ]; then
            rsync_exec -az \
                --include="*.aux" --include="*.log" --include="*.toc" \
                --include="*.bbl" --include="*.blg" --include="*.synctex.gz" \
                --include="*.dvi" --include="*.fls" --include="*.fdb_latexmk" \
                --exclude="*" \
                "${SSH_HOST}:$WORK_DIR/" \
                "$TEX_DIR/" 2>/dev/null || true
        else
            rsync_exec -az \
                --include="*.aux" --include="*.log" --include="*.toc" \
                --include="*.bbl" --include="*.blg" --include="*.synctex.gz" \
                --include="*.dvi" --include="*.fls" --include="*.fdb_latexmk" \
                --exclude="*" \
                "${REMOTE_USER:-$USER}@${SSH_HOST}:$WORK_DIR/" \
                "$TEX_DIR/" 2>/dev/null || true
        fi
    fi
    
    return 0
}

# Watch mode implementation
watch_compile() {
    log "Watch mode enabled. Press Ctrl+C to stop."
    
    # Initial compilation
    sync_files
    compile && retrieve || true
    
    # Watch for changes
    if command -v inotifywait >/dev/null 2>&1; then
        while true; do
            if inotifywait -q -e modify,create "$TEX_DIR"/*.{tex,sty,cls,bib} 2>/dev/null; then
                echo ""
                log "File changed, recompiling..."
                sync_files
                compile && retrieve || true
            fi
        done
    elif command -v fswatch >/dev/null 2>&1; then
        fswatch -o "$TEX_DIR"/*.{tex,sty,cls,bib} | while read num; do
            echo ""
            log "File changed, recompiling..."
            sync_files
            compile && retrieve || true
        done
    else
        warn "No file watcher found, using polling (5 second intervals)"
        local last_mod=""
        while true; do
            local current_mod=$(stat -c %Y "$TEX_FILE" 2>/dev/null || stat -f %m "$TEX_FILE" 2>/dev/null)
            if [ "$current_mod" != "$last_mod" ]; then
                echo ""
                log "File changed, recompiling..."
                sync_files
                compile && retrieve || true
                last_mod="$current_mod"
            fi
            sleep 5
        done
    fi
}

# Main
main() {
    test_connection
    
    if [ "$WATCH_MODE" = true ]; then
        watch_compile
    else
        sync_files
        if compile; then
            retrieve
            log "Output: $TEX_DIR/$TEX_BASE.pdf"
        else
            exit 1
        fi
    fi
}

main