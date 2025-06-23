#!/bin/bash
# install.sh - LuaTeX Docker environment installer

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INSTALL]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Configuration
INSTALL_PREFIX="${HOME}/.local"
CONFIG_DIR="${HOME}/.config/luatex"
CACHE_DIR="${HOME}/.cache/luatex"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Options
UNINSTALL=false
UPDATE=false
SKIP_DOCKER=false
REMOTE_HOST="zeus"

usage() {
    cat << HELP
Usage: $(basename "$0") [OPTIONS]

Install LuaTeX Docker environment.

Options:
    -h, --help          Show this help
    -u, --uninstall     Uninstall
    -U, --update        Update installation
    -s, --skip-docker   Skip Docker build
    --remote-host HOST  Set remote host (default: zeus)

HELP
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -u|--uninstall)
            UNINSTALL=true
            shift
            ;;
        -U|--update)
            UPDATE=true
            shift
            ;;
        -s|--skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        --remote-host)
            REMOTE_HOST="$2"
            shift 2
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

uninstall() {
    log "Uninstalling LuaTeX Docker environment..."
    
    rm -f "${INSTALL_PREFIX}/bin/luatex-pdf"
    
    if [ -d "$CONFIG_DIR" ]; then
        read -p "Remove config directory $CONFIG_DIR? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR"
        fi
    fi
    
    rm -rf "$CACHE_DIR"
    log "Uninstallation complete"
}

create_sample_styles() {
    cat > "${CONFIG_DIR}/styles/common.sty" << 'STY'
\NeedsTeXFormat{LaTeX2e}
\ProvidesPackage{common}[2024/01/01 Common style]

\RequirePackage{graphicx}
\RequirePackage{xcolor}
\RequirePackage{hyperref}
\RequirePackage{amsmath,amssymb}

\hypersetup{
    colorlinks=true,
    linkcolor=blue!70!black,
    citecolor=green!60!black,
    urlcolor=red!60!black,
}

\newcommand{\code}[1]{\texttt{#1}}
\newcommand{\highlight}[1]{\textcolor{red}{\textbf{#1}}}

\endinput
STY

    cat > "${CONFIG_DIR}/styles/japanese.sty" << 'STY'
\NeedsTeXFormat{LaTeX2e}
\ProvidesPackage{japanese}[2024/01/01 Japanese typography]

\RequirePackage{luatexja}
\RequirePackage{luatexja-fontspec}

\setmainjfont{HaranoAjiMincho}[
    BoldFont = HaranoAjiGothic,
    ItalicFont = HaranoAjiMincho,
    ItalicFeatures = {FakeSlant=0.15}
]
\setsansjfont{HaranoAjiGothic}

\endinput
STY
}

create_sample_templates() {
    cat > "${CONFIG_DIR}/templates/article.tex" << 'TEX'
\documentclass[11pt,a4paper]{ltjsarticle}
\usepackage{common}
\usepackage{japanese}

\title{Document Title}
\author{Your Name}
\date{\today}

\begin{document}
\maketitle

\section{Introduction}
Your content here.

\end{document}
TEX
}

install() {
    log "Installing LuaTeX Docker environment..."
    
    # Create directories
    mkdir -p "${INSTALL_PREFIX}/bin"
    mkdir -p "${CONFIG_DIR}"/{styles,templates}
    mkdir -p "${CACHE_DIR}"
    
    # Install command
    ln -sf "${PROJECT_ROOT}/scripts/luatex-compile.sh" "${INSTALL_PREFIX}/bin/luatex-pdf"
    
    # Create config
    cat > "${CONFIG_DIR}/config" << CONFIG
# LuaTeX Docker Configuration
REMOTE_HOST="${REMOTE_HOST}"
DOCKER_IMAGE="luatex:latest"
CONFIG_DIR="${CONFIG_DIR}"
CACHE_DIR="${CACHE_DIR}"
CONFIG
    
    # Create samples
    if [ ! -f "${CONFIG_DIR}/styles/common.sty" ]; then
        create_sample_styles
    fi
    
    if [ ! -f "${CONFIG_DIR}/templates/article.tex" ]; then
        create_sample_templates
    fi
    
    # Build Docker
    if [ "$SKIP_DOCKER" = false ]; then
        log "Building Docker image..."
        "${PROJECT_ROOT}/scripts/build-docker.sh" "$REMOTE_HOST"
    fi
    
    # Setup PATH
    setup_path
    
    log "Installation complete!"
    show_next_steps
}

setup_path() {
    local shell_rc=""
    if [ -n "${ZSH_VERSION:-}" ]; then
        shell_rc="${HOME}/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ]; then
        shell_rc="${HOME}/.bashrc"
    else
        shell_rc="${HOME}/.profile"
    fi
    
    if [[ ":$PATH:" != *":${INSTALL_PREFIX}/bin:"* ]]; then
        cat >> "$shell_rc" << PATH_CONFIG

# LuaTeX Docker
export PATH="${INSTALL_PREFIX}/bin:\$PATH"
export TEXINPUTS=".:${CONFIG_DIR}/styles//:\$TEXINPUTS"
PATH_CONFIG
        warn "Added PATH to $shell_rc"
        warn "Run: source $shell_rc"
    fi
}

show_next_steps() {
    cat << NEXT

Next steps:
1. Reload shell: ${BLUE}source ~/.bashrc${NC}
2. Test: ${BLUE}luatex-pdf --help${NC}
3. Copy .sty files to: ${BLUE}${CONFIG_DIR}/styles/${NC}
4. Compile: ${BLUE}luatex-pdf document.tex${NC}

NEXT
}

# Main
if [ "$UNINSTALL" = true ]; then
    uninstall
elif [ "$UPDATE" = true ]; then
    SKIP_DOCKER=true
    install
else
    install
fi
