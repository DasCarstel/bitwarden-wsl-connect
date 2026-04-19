#!/bin/bash
# Deinstallation script for Bitwarden SSH-Agent Bridge

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.bin"
SOCKET_DIR="$HOME/.ssh/sockets"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "
===============================================
  Bitwarden SSH-Agent Bridge Deinstaller
===============================================
"

# Stop bridge
log_info "Stoppe Bridge..."
"$BIN_DIR/ssh-agent-bitwarden" stop 2>/dev/null || true

# Remove from .bashrc
log_info "Entferne ~/.bashrc-Einträge..."
if [ -f "$HOME/.bashrc" ]; then
    # Create temp file without the Bitwarden block
    cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
    sed -i '/^# Bitwarden SSH-Agent Bridge$/,/^$/d' "$HOME/.bashrc"
    log_info "~/.bashrc wiederhergestellt (Backup: ~/.bashrc.bak)"
fi

# Ask about removing files
read -p "Sollen die Skript- und Socket-Dateien gelöscht werden? [j/N] " -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    rm -f "$BIN_DIR/ssh-agent-bitwarden"
    rm -f "$SOCKET_DIR/bitwarden-agent.sock"
    rmdir "$SOCKET_DIR" 2>/dev/null || true
    log_info "Dateien gelöscht"
else
    log_info "Dateien behalten"
fi

echo "
===============================================
  Deinstallation abgeschlossen!
===============================================
"

# Verify clean state
log_info "Prüfe状态..."
if [ -S "$SOCKET_DIR/bitwarden-agent.sock" ]; then
    log_warn "Socket existiert noch"
else
    log_info "WSL sauber"
fi

# Check Windows side - can't do much here
log_info "Bitwarden SSH-Agent in Windows bleibt aktiv"
log_info "Um ihn zu deaktivieren: Bitwarden → Settings → Developer → Disable SSH Agent"