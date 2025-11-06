# LuaTeX Docker image based on official TeXLive
FROM texlive/texlive:latest

# Install additional packages and Japanese fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-noto-color-emoji \
    fonts-ipaexfont \
    fonts-ipaexfont-gothic \
    fonts-ipaexfont-mincho \
    fonts-ipafont \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho \
    fonts-takao \
    fonts-takao-gothic \
    fonts-takao-mincho \
    fonts-vlgothic \
    fonts-mplus \
    fonts-sawarabi-gothic \
    fonts-sawarabi-mincho \
    fonts-horai-umefont \
    fonts-migmix \
    fonts-hanazono \
    python3-pygments \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create symlinks for HaranoAji fonts (use Noto CJK as fallback)
# HaranoAji is based on Source Han fonts, which Noto CJK is also derived from
RUN mkdir -p /usr/share/fonts/opentype/haranoaji && \
    ln -s /usr/share/fonts/opentype/noto/NotoSerifCJK-Regular.ttc /usr/share/fonts/opentype/haranoaji/HaranoAjiMincho-Regular.otf && \
    ln -s /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc /usr/share/fonts/opentype/haranoaji/HaranoAjiGothic-Regular.otf

# Set CTAN mirror to a stable one
RUN tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet

# Update tlmgr itself
RUN tlmgr update --self || echo "tlmgr self-update failed, continuing..."

# Install Japanese TeX packages
RUN tlmgr install jsclasses platex uplatex uptex uptex-fonts ptex-fontmaps japanese-otf || \
    echo "Some Japanese packages failed to install, continuing..."

# Install font packages (including Libertinus for math)
RUN tlmgr install mathptmx newtx txfonts times libertinus-fonts libertinus-otf || \
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