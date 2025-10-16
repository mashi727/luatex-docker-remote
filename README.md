# LuaTeX Docker Remote

A complete LuaTeX compilation environment using Docker on remote hosts, with full support for custom `.sty` files and Japanese typography.

## Overview

`luatex-docker-remote` enables you to compile LaTeX documents using LuaTeX on a remote Docker host, keeping your local environment clean while leveraging powerful server resources.

## Features

- 🚀 **Remote Compilation**: Compile on powerful remote servers
- 🌐 **Network Auto-Detection**: Automatically switches between internal/external hosts
- 📦 **Automatic `.sty` Detection**: Local style files are automatically synchronized
- 🇯🇵 **Japanese Support**: Full Japanese typography with LuaTeX-ja
- 🎨 **Organized Structure**: Clean separation of configs, styles, and cache
- ⚡ **Watch Mode**: Auto-recompilation on file changes
- 🔧 **Easy Installation**: Simple setup process
- 🐳 **Docker-based**: Consistent environment across all systems

## Requirements

- SSH access to a Docker host (internal and/or external)
- rsync installed locally
- Basic UNIX tools (bash, make)
- curl (for network detection)

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/luatex-docker-remote.git
cd luatex-docker-remote

# Install
make install

# Setup network auto-detection (optional but recommended)
make setup-network

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

### Network Configuration

The system can automatically detect whether you're on your home network and switch between internal and external hostnames:

```bash
# First-time setup
make setup-network

# This will create:
# ~/.home_global_ip     - Your home network's global IP
# ~/.port_for_ssh       - SSH port for external access (optional)
# ~/.config/luatex/network-config - Network settings
```

### Basic Usage

```bash
# Compile with different engines
luatex-pdf document.tex          # LuaLaTeX (default)
uplatex-pdf document.tex          # upLaTeX
platex-pdf document.tex           # pLaTeX
xelatex-pdf document.tex          # XeLaTeX
pdflatex-pdf document.tex         # pdfLaTeX

# Or use -e option
luatex-pdf -e uplatex document.tex
luatex-pdf -e platex document.tex

# Watch mode with any engine
uplatex-pdf -w thesis.tex
```

## Directory Structure

After installation:

```
~/.local/bin/
    └── luatex-pdf          # Main command

~/.config/luatex/
    ├── config              # Configuration file
    ├── styles/             # Shared .sty files
    │   ├── common.sty
    │   └── japanese.sty
    └── templates/          # Document templates
        └── article.tex

~/.cache/luatex/            # Cache directory
```

## Font Configuration

### Recommended Japanese Fonts

The Docker image includes comprehensive Japanese font support optimized for academic and technical documents:

#### Primary Recommendations

1. **Harano Aji Fonts** (原ノ味フォント) - Most recommended for LuaLaTeX
   - Based on Adobe Source Han fonts, optimized for TeX
   - Excellent harmony with Libertinus Math
   - See `examples/libertinus-haranoaji-example.tex`

2. **Noto CJK Fonts** - Ubuntu default, comprehensive coverage
   - Google/Adobe collaboration
   - Complete CJK character support
   - See `examples/libertinus-noto-example.tex`

3. **IPAex Fonts** - Traditional choice for academic documents
   - Provided by Japan's Information-technology Promotion Agency
   - Full JIS X 0213 support

#### Using with Libertinus Math

For mathematical documents, we recommend:
- **Text**: Libertinus Serif
- **Sans-serif**: Libertinus Sans
- **Monospace**: Libertinus Mono
- **Math**: Libertinus Math
- **Japanese**: Harano Aji or Noto CJK

Example configuration in your `.tex` file:

```latex
\usepackage{luatexja-fontspec}
\usepackage{unicode-math}

% Western fonts
\setmainfont{Libertinus Serif}
\setsansfont{Libertinus Sans}
\setmonofont{Libertinus Mono}
\setmathfont{Libertinus Math}

% Japanese fonts (Noto CJK)
\setmainjfont{Noto Serif CJK JP}
\setsansjfont{Noto Sans CJK JP}
```

### Available Fonts in Docker Image

The following Japanese fonts are pre-installed:
- Harano Aji (Mincho/Gothic)
- Noto CJK (Serif/Sans/Mono)
- IPA/IPAex (Mincho/Gothic)
- Takao fonts
- M+ FONTS
- Sawarabi (Gothic/Mincho)
- VL Gothic
- MigMix
- Hanazono
- Ume fonts

## Custom Styles

### Project-specific styles

Place `.sty` files in the same directory as your `.tex` files:

```
my-project/
├── main.tex
├── mystyle.sty    # Automatically detected
└── figures/
```

### Shared styles

Place commonly used `.sty` files in `~/.config/luatex/styles/`:

```bash
cp awesome-package.sty ~/.config/luatex/styles/
# Now available to all projects
```

## Configuration

Edit `~/.config/luatex/config` to customize:

```bash
REMOTE_HOST="your-server"       # Docker host
DOCKER_IMAGE="luatex:latest"    # Docker image
```

## Advanced Usage

### Network Auto-Detection

The system automatically detects your network location:

```bash
# At home: uses internal hostname (e.g., zeus)
luatex-pdf document.tex

# Outside: uses external hostname (e.g., zeus-soto)
luatex-pdf document.tex

# Force specific host
luatex-pdf -H zeus-internal document.tex

# Disable auto-detection
luatex-pdf --no-auto-detect document.tex
```

### SSH Configuration

Recommended `~/.ssh/config`:

```ssh
# Internal access
Host zeus
    HostName 192.168.1.100  # or zeus.local
    User yourusername
    
# External access
Host zeus-soto
    HostName your.domain.com
    User yourusername
    Port 2222  # if using custom port
```

### Using with Git

The compilation process ignores version control files and focuses on LaTeX-related files:

```
project/
├── .git/           # Ignored
├── main.tex        # Synced
├── style.sty       # Synced
├── fig.pdf         # Synced
└── README.md       # Ignored
```

### Directory Structure Support

Complex directory structures are fully supported:

```latex
% main.tex
\input{chapters/introduction}
\includegraphics{figures/diagram}
\includegraphics{figures/results/graph1}
```

All paths work as expected without modification.

## Development

### Update installation
```bash
make update
```

### Rebuild Docker image
```bash
make build-docker
```

### Run tests
```bash
make test
```

### Uninstall
```bash
make uninstall
```

## Troubleshooting

### Command not found
```bash
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc
```

### SSH connection issues
```bash
ssh-copy-id your-docker-host
```

### Style file not found
Ensure your `.sty` file is in:
- Same directory as `.tex` file, or
- `~/.config/luatex/styles/`

### Check remote files
```bash
ssh your-host "ls -la /tmp/luatex-*"
```

## How It Works

1. **Sync**: Local files are synchronized to remote temporary directory
2. **Compile**: Docker container runs LuaTeX compilation
3. **Retrieve**: Generated PDF is copied back to local
4. **Cleanup**: Remote temporary files are automatically removed

## Contributing

Pull requests are welcome! Please feel free to submit issues and enhancement requests.

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- LuaTeX and TeX Live communities
- Docker project
- Japanese TeX users group

---

For more information, visit the [project repository](https://github.com/yourusername/luatex-docker-remote).
