# LuaTeX Docker image based on official TeXLive
FROM texlive/texlive:latest

# Install additional packages and Japanese fonts
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Japanese fonts
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    # Utilities
    python3-pygments \
    && rm -rf /var/lib/apt/lists/*

# Update font cache
RUN fc-cache -fv

# Create working directory with proper permissions
WORKDIR /workspace
RUN chmod 777 /workspace

# Set environment for .sty file search
ENV TEXINPUTS=".:/workspace//:/workspace/.config/luatex/styles//:"

CMD ["/bin/bash"]