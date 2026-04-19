.PHONY: help install uninstall check start stop restart status test clean

SHELL := bash
BIN_DIR := $(HOME)/.bin
SOCKET_DIR := $(HOME)/.ssh/sockets

help:
	@echo "Bitwarden SSH-Agent Bridge für WSL2 - Make targets"
	@echo ""
	@echo "  make install    - Installation durchführen"
	@echo "  make uninstall - Deinstallation durchführen"
	@echo "  make check    - Voraussetzungen prüfen"
	@echo "  make start   - Bridge starten"
	@echo "  make stop    - Bridge stoppen"
	@echo "  make restart - Bridge neustarten"
	@echo "  make status  - Status anzeigen"
	@echo "  make test    - Keys testen"
	@echo "  make clean   - Temporäre Dateien löschen"
	@echo ""
	@echo "Weitere Informationen: cat README.md"

install:
	@echo "Starte Installation..."
	@./install.sh --force

uninstall:
	@./uninstall.sh

check:
	@echo "Prüfe Voraussetzungen..."
	@-$(BIN_DIR)/ssh-agent-bitwarden check || true
	@echo ""
	@echo "npiperelay.exe:"
	@if [ -x /mnt/c/tools/npiperelay.exe ]; then \
		echo "  Gefunden"; \
	else \
		echo "  NICHT gefunden (../tools/npiperelay.exe)"; \
	fi
	@echo "socat:"
	@if command -v socat >/dev/null 2>&1; then \
		echo "  Installiert"; \
	else \
		echo "  NICHT installiert"; \
	fi

start:
	@$(BIN_DIR)/ssh-agent-bitwarden start

stop:
	@$(BIN_DIR)/ssh-agent-bitwarden stop

restart:
	@$(BIN_DIR)/ssh-agent-bitwarden restart

status:
	@$(BIN_DIR)/ssh-agent-bitwarden status

test:
	@echo "Teste SSH-Keys..."
	@SSH_AUTH_SOCK=$(SOCKET_DIR)/bitwarden-agent.sock ssh-add -l

clean:
	@echo "Lösche temporäre Dateien..."
	@rm -f $(SOCKET_DIR)/bitwarden-agent.sock
	@rm -f $(HOME)/.bashrc.bak
	@echo "Fertig"

.DEFAULT_GOAL := help