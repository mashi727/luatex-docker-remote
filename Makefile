# Makefile for LuaTeX Docker Remote

.PHONY: install update uninstall test build-docker clean help

help:
	@echo "LuaTeX Docker Remote - Makefile targets"
	@echo ""
	@echo "Targets:"
	@echo "  make install       - Install environment"
	@echo "  make update        - Update installation"
	@echo "  make uninstall     - Remove environment"
	@echo "  make build-docker  - Build Docker image on remote"
	@echo "  make setup-network - Configure network auto-detection"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean cache files"
	@echo ""
	@echo "Variables:"
	@echo "  REMOTE_HOST=zeus   - Specify remote host"
	@echo ""
	@echo "Examples:"
	@echo "  make install"
	@echo "  make setup-network"
	@echo "  make build-docker"

install:
	@scripts/install.sh

update:
	@scripts/install.sh --update

uninstall:
	@scripts/install.sh --uninstall

setup-network:
	@scripts/setup-network.sh

build-docker:
	@scripts/build-docker.sh

test:
	@echo "Running tests..."
	@cd examples && luatex-pdf document.tex

clean:
	@rm -rf ~/.cache/luatex/*
	@find . -name "*.aux" -o -name "*.log" -o -name "*.out" | xargs rm -f
