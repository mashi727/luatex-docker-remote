# LuaTeX Docker image based on official TeXLive
FROM texlive/texlive:latest

# Install additional packages and Japanese fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Japanese fonts
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-ipaexfont \        # 追加
    fonts-ipafont \          # 追加
    fonts-takao \            # 追加
    fonts-vlgothic \         # 追加

    # Utilities
    python3-pygments \
    && rm -rf /var/lib/apt/lists/*

# Install essential Japanese TeX packages and commonly used packages
RUN tlmgr update --self && \
    tlmgr install \
        # Japanese essentials
        jsclasses \
        platex \
        uplatex \
        uptex \
        uptex-fonts \
        ptex-fontmaps \
        japanese-otf \
        # Math and font packages
        mathptmx \
        newtx \
        txfonts \
        times \
        # Other commonly used
        ascmac \
        latexmk


# Update font cache
RUN fc-cache -fv

# Create working directory with proper permissions
WORKDIR /workspace
RUN chmod 777 /workspace

# Set environment for .sty file search
ENV TEXINPUTS=".:/workspace//:/workspace/.config/luatex/styles//:"

CMD ["/bin/bash"]
