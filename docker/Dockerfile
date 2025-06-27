# LuaTeX Docker image based on official TeXLive
FROM texlive/texlive:latest

# Install additional packages and Japanese fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-ipaexfont \
    fonts-ipafont \
    fonts-takao \
    fonts-vlgothic \
    python3-pygments \
    && rm -rf /var/lib/apt/lists/*

# Set CTAN mirror to a stable one
RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet

# Update tlmgr itself
RUN tlmgr update --self || echo "tlmgr self-update failed, continuing..."

# Install Japanese TeX packages
RUN tlmgr install jsclasses platex uplatex uptex uptex-fonts ptex-fontmaps japanese-otf || \
    echo "Some Japanese packages failed to install, continuing..."

# Install font packages
RUN tlmgr install mathptmx newtx txfonts times || \
    echo "Some font packages failed to install, continuing..."

# Install other packages
RUN tlmgr install ascmac latexmk || \
    echo "Some utility packages failed to install, continuing..."

# Alternative: Check what's already installed and only install missing packages
RUN tlmgr list --only-installed || true

# Update font cache
RUN fc-cache -fv

# Create working directory with proper permissions
WORKDIR /workspace
RUN chmod 777 /workspace

# Set environment for .sty file search
ENV TEXINPUTS=".:/workspace//:/workspace/.config/luatex/styles//:"

CMD ["/bin/bash"]