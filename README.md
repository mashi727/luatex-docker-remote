# LuaTeX Docker Remote

A complete LuaTeX compilation environment using Docker on remote hosts, with full support for custom `.sty` files and Japanese typography.

## Overview

`luatex-docker-remote` enables you to compile LaTeX documents using LuaTeX on a remote Docker host, keeping your local environment clean while leveraging powerful server resources.

## Features

- 🚀 **Remote Compilation**: Compile on powerful remote servers
- 📦 **Automatic `.sty` Detection**: Local style files are automatically synchronized
- 🇯🇵 **Japanese Support**: Full Japanese typography with LuaTeX-ja
- 🎨 **Organized Structure**: Clean separation of configs, styles, and cache
- ⚡ **Watch Mode**: Auto-recompilation on file changes
- 🔧 **Easy Installation**: Simple setup process
- 🐳 **Docker-based**: Consistent environment across all systems

## Requirements

- SSH access to a Docker host
- rsync installed locally
- Basic UNIX tools (bash, make)

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/yourusername/luatex-docker-remote.git
cd luatex-docker-remote

# Install (default remote host: zeus)
make install

# Or specify custom remote host
make install REMOTE_HOST=your-server

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

### Basic Usage

```bash
# Compile a document
luatex-pdf document.tex

# Watch mode (auto-recompile on changes)
luatex-pdf -w document.tex

# Verbose output with cleanup
luatex-pdf -v -c document.tex

# Keep auxiliary files
luatex-pdf -k thesis.tex
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
