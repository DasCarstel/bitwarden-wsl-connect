#!/bin/bash
# Installation script for Bitwarden SSH-Agent Bridge
#
# Usage:
#   ./install.sh          - Interactive mode
#   ./install.sh --force  - Non-interactive (force mode)

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
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

echo "
===============================================
  Bitwarden SSH-Agent Bridge Installer
===============================================
"

# Check if running in WSL
if [ ! -d /mnt/c ]; then
    log_error "Nicht in WSL! Abbruch."
    exit 1
fi

# Check for npiperelay
log_step "Prüfe npiperelay.exe..."
if [ -x /mnt/c/tools/npiperelay.exe ]; then
    log_info "npiperelay.exe gefunden: /mnt/c/tools/npiperelay.exe"
else
    log_error "npiperelay.exe nicht gefunden: /mnt/c/tools/npiperelay.exe"
    log_error "Bitte zuerst installieren:"
    log_error "  https://github.com/NT-broker/WSL-network-tools/releases"
    [ $FORCE -eq 0 ] && exit 1
    log_warn "Fortfahren ohne npiperelay..."
fi

# Check for socat
log_step "Prüfe socat..."
if command -v socat >/dev/null 2>&1; then
    SOCAT_VERSION=$(socat -V | head -1)
    log_info "socat gefunden: $SOCAT_VERSION"
else
    log_error "socat nicht installiert"
    log_info "Installation mit: sudo apt install socat"
    if [ $FORCE -eq 0 ]; then
        read -p "Jetzt installieren? [j/N] " -n 1 -r REPLY
        echo
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            sudo apt update && sudo apt install socat -y
        else
            exit 1
        fi
    fi
fi

# Check for procps (for pgrep)
log_step "Prüfe procps..."
if command -v pgrep >/dev/null 2>&1; then
    log_info "procps gefunden (pgrep)"
else
    log_error "procps nicht installiert"
    if [ $FORCE -eq 0 ]; then
        read -p "Jetzt installieren? [j/N] " -n 1 -r REPLY
        echo
        if [[ $REPLY =~ ^[Jj]$ ]]; then
            sudo apt install procps -y
        fi
    fi
fi

# Create directories
log_step "Erstelle Verzeichnisse..."
mkdir -p "$BIN_DIR"
mkdir -p "$SOCKET_DIR"
chmod 700 "$SOCKET_DIR"
log_info "Verzeichnisse erstellt: $BIN_DIR, $SOCKET_DIR"

# Copy script
log_step "Kopiere Bridge-Skript..."
cp "$SCRIPT_DIR/bin/ssh-agent-bitwarden" "$BIN_DIR/"
chmod +x "$BIN_DIR/ssh-agent-bitwarden"
log_info "Skript kopiert: $BIN_DIR/ssh-agent-bitwarden"

# Check if .bashrc needs modification
log_step "Prüfe ~/.bashrc..."

BASHRC_BLOCK='# Bitwarden SSH-Agent Bridge'
if grep -q "$BASHRC_BLOCK" "$HOME/.bashrc" 2>/dev/null; then
    log_info "~/.bashrc bereits konfiguriert"
else
    log_info "~/.bashrc wird angepasst..."
    
    cat >> "$HOME/.bashrc" << 'BASHRC'

# Bitwarden SSH-Agent Bridge
export PATH=~/.bin:$PATH
export SSH_AUTH_SOCK=~/.ssh/sockets/bitwarden-agent.sock
if command -v socat >/dev/null 2>&1; then
    ~/.bin/ssh-agent-bitwarden start >/dev/null 2>&1 &
fi
BASHRC
    
    log_info "~/.bashrc angepasst"
fi

# Start bridge
log_step "Starte Bridge..."
if "$BIN_DIR/ssh-agent-bitwarden" start; then
    log_info "Bridge gestartet"
else
    log_warn "Bridge konnte nicht gestartet werden"
fi

# Verify
log_step "Verifiziere Installation..."
sleep 1
if "$BIN_DIR/ssh-agent-bitwarden" status 2>/dev/null; then
    :
else
    log_warn "Status-Check fehlgeschlagen"
fi

echo "
===============================================
  Installation abgeschlossen!
===============================================

Nächste Schritte:
1. Bitwarden entsperren
2. Neue Shell öffnen: exec bash -l
3. Keys testen: ssh-add -l

Weitere Hilfe: cat $SCRIPT_DIR/README.md
"