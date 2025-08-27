# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LuaTeX Docker Remote is a tool that enables remote LaTeX compilation using Docker containers. It supports multiple TeX engines (LuaLaTeX, upLaTeX, pLaTeX, XeLaTeX, pdfLaTeX) and provides automatic network detection for seamless switching between internal and external SSH hosts.

## Common Commands

### Installation and Setup
```bash
make install          # Install the tool
make setup-network    # Configure network auto-detection
make build-docker     # Build Docker image on remote host
make update          # Update installation
make uninstall       # Remove the tool
```

### Compilation Commands
```bash
# Different engines (all are symlinks to the same script)
luatex-pdf document.tex    # LuaLaTeX (default)
uplatex-pdf document.tex   # upLaTeX
platex-pdf document.tex    # pLaTeX
xelatex-pdf document.tex   # XeLaTeX
pdflatex-pdf document.tex  # pdfLaTeX

# Options
-e ENGINE    # Specify engine
-w           # Watch mode (auto-recompile)
-c           # Clean auxiliary files after compilation
-k           # Keep auxiliary files
-H HOST      # Force specific SSH host
--show-log   # Show compilation log on error
```

### Testing
```bash
make test    # Run test compilation in examples/
```

## Architecture

### Core Components

1. **Main Compilation Script** (`scripts/luatex-compile.sh`):
   - Detects SSH host based on network location
   - Syncs files to remote using rsync
   - Runs Docker compilation on remote host
   - Retrieves PDF and auxiliary files

2. **Installation Script** (`scripts/install.sh`):
   - Creates symlinks in `~/.local/bin/`
   - Sets up configuration in `~/.config/luatex/`
   - Supports both SSH config and direct credentials

3. **Docker Image** (`docker/Dockerfile`):
   - Based on `texlive/texlive:latest`
   - Includes Japanese fonts and packages
   - Uses latexmk for compilation

### SSH Host Detection Flow

The system automatically selects the appropriate SSH host:
1. Checks if force host is specified (`-H` option)
2. If network detection enabled:
   - Gets current IP via `https://ifconfig.me`
   - Compares with stored home IP (`~/.home_global_ip`)
   - Selects internal host if on home network, external otherwise
3. Falls back to default host if detection fails

### File Synchronization

Files are synced selectively:
- LaTeX files: `.tex`, `.sty`, `.cls`, `.bib`, `.bst`
- Images: `.png`, `.jpg`, `.jpeg`, `.pdf`, `.eps`, `.svg`
- Ignores: version control files, README files

### Engine-specific Compilation

Each engine has specific latexmk configuration:
- **lualatex**: `-lualatex` flag
- **uplatex/platex**: Creates `.latexmkrc` with dvipdfmx, uses `-pdfdvi`
- **xelatex**: `-xelatex` flag  
- **pdflatex**: `-pdf` flag

## Key Configuration Files

- `~/.config/luatex/config`: Main configuration (remote host, Docker image)
- `~/.config/luatex/network-config`: Network detection settings
- `~/.config/luatex/styles/`: Shared `.sty` files available to all projects
- `~/.home_global_ip`: Home network's global IP for detection
- `~/.port_for_ssh`: SSH port for external access (optional)

## Development Notes

- The compilation script uses `set -euo pipefail` for strict error handling
- All SSH/SCP/rsync operations go through wrapper functions for consistent handling
- Temporary directories use PID and timestamp for uniqueness: `/tmp/tex-compile-$$-$(date +%s)`
- Cleanup is handled via EXIT trap to ensure remote temp files are removed
- Watch mode supports inotifywait, fswatch, and polling fallback

## Commercial Fonts Directory

The `commercial/mathtime/` directory contains proprietary MathTime fonts. These are not open source and should not be modified or redistributed without proper licensing.