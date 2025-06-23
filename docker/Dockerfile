# LuaTeX Docker image with Japanese support
FROM debian:bookworm-slim AS builder

ARG TEXLIVE_VERSION=2024
ARG MIRROR=https://mirror.ctan.org/systems/texlive/tlnet

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    perl \
    perl-modules \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# TeX Live installation
WORKDIR /tmp/install-tl
RUN wget -qO- ${MIRROR}/install-tl-unx.tar.gz | tar xz --strip-components=1

# Installation profile
RUN cat > texlive.profile << PROFILE && \
selected_scheme scheme-basic
TEXDIR /usr/local/texlive/${TEXLIVE_VERSION}
TEXMFLOCAL /usr/local/texlive/texmf-local
TEXMFSYSVAR /usr/local/texlive/${TEXLIVE_VERSION}/texmf-var
TEXMFSYSCONFIG /usr/local/texlive/${TEXLIVE_VERSION}/texmf-config
TEXMFVAR ~/.texlive${TEXLIVE_VERSION}/texmf-var
TEXMFCONFIG ~/.texlive${TEXLIVE_VERSION}/texmf-config
TEXMFHOME ~/texmf
binary_x86_64-linux 1
instopt_adjustpath 0
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 0
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_w32_multi_user 0
PROFILE
    ./install-tl --profile=texlive.profile && \
    cd / && rm -rf /tmp/install-tl

# Install packages
ENV PATH=/usr/local/texlive/${TEXLIVE_VERSION}/bin/x86_64-linux:$PATH
RUN tlmgr install \
    # Core
    luatex \
    luaotfload \
    luatexbase \
    luacode \
    latexmk \
    # LaTeX
    latex \
    latex-bin \
    latex-fonts \
    tools \
    # LuaLaTeX essentials
    fontspec \
    unicode-math \
    microtype \
    # Japanese
    luatexja \
    ltjsclasses \
    luatexja-preset \
    luatexja-fontspec \
    haranoaji \
    haranoaji-extra \
    # Graphics
    graphics \
    graphics-def \
    graphicx \
    xcolor \
    # Math
    amsmath \
    amssymb \
    amsfonts \
    mathtools \
    # Bibliography
    bibtex \
    biber \
    biblatex \
    # Useful packages
    hyperref \
    geometry \
    enumitem \
    listings \
    fancyhdr \
    # Collections
    collection-latexrecommended \
    collection-latexextra \
    collection-fontsrecommended

# Final stage
FROM debian:bookworm-slim

# Copy TeX Live
COPY --from=builder /usr/local/texlive /usr/local/texlive

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    perl \
    perl-modules \
    wget \
    fontconfig \
    fonts-liberation \
    fonts-dejavu \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    ghostscript \
    poppler-utils \
    python3 \
    python3-pygments \
    make \
    && rm -rf /var/lib/apt/lists/*

# Environment
ENV PATH=/usr/local/texlive/2024/bin/x86_64-linux:$PATH
ENV TEXMFCACHE=/var/cache/texmf
ENV TEXMFVAR=/var/cache/texmf-var

# Create directories
RUN mkdir -p ${TEXMFCACHE} ${TEXMFVAR} && \
    chmod 1777 ${TEXMFCACHE} ${TEXMFVAR}

# Copy texmf.cnf
COPY texmf.cnf /usr/local/texlive/2024/texmf.cnf

# Update databases
RUN mktexlsr && \
    luaotfload-tool --update --force && \
    fc-cache -fv

# Create user
RUN groupadd -g 1000 latex && \
    useradd -m -u 1000 -g latex -s /bin/bash latex

WORKDIR /workspace
RUN chown -R latex:latex /workspace

USER latex
CMD ["/bin/bash"]
