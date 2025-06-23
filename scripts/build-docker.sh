#!/bin/bash
# build-docker.sh - Build Docker image on remote host

set -euo pipefail

REMOTE_HOST="${1:-zeus}"
REMOTE_USER="${REMOTE_USER:-$USER}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Building Docker image on $REMOTE_HOST..."

# Sync files
rsync -az "$PROJECT_ROOT/docker/" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/luatex-docker-build/"

# Build
ssh "${REMOTE_USER}@${REMOTE_HOST}" << 'REMOTE_BUILD'
cd /tmp/luatex-docker-build
docker build -t luatex:latest .
docker tag luatex:latest luatex:$(date +%Y%m%d)
rm -rf /tmp/luatex-docker-build
REMOTE_BUILD

echo "Build complete!"
