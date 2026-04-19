#!/bin/bash
# Quick Start Script - Führt alle Schritte in einem Befehl aus
#
# Usage: ./quickstart.sh [--force]

set -euo pipefail

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

echo "==============================================="
echo "  Bitwarden SSH-Agent Bridge - Quick Start"
echo "==============================================="

# Prüfen ob in WSL
if [ ! -d /mnt/c ]; then
    echo "FEHLER: Nicht in WSL2!"
    exit 1
fi

# Prüfen npiperelay
echo "[1/4] Prüfe npiperelay.exe..."
if [ ! -x /mnt/c/tools/npiperelay.exe ]; then
    echo "FEHLER: npiperelay.exe nicht gefunden!"
    echo ""
    echo "Bitte in Windows herunterladen:"
    echo "  https://github.com/NT-broker/WSL-network-tools/releases"
    echo "Und nach C:\tools\npiperelay.exe speichern."
    exit 1
fi
echo "  OK"

# socat installieren wenn nötig
echo "[2/4] Prüfe socat..."
if ! command -v socat >/dev/null 2>&1; then
    echo "  Installiere socat..."
    sudo apt update -qq
    sudo apt install -y -qq socat
fi
echo "  OK"

# Verzeichnisse
echo "[3/4] Erstelle Verzeichnisse..."
mkdir -p ~/.ssh/sockets
mkdir -p ~/.bin
chmod 700 ~/.ssh/sockets
echo "  OK"

# Skript kopieren
echo "[4/4] Installiere Bridge-Skript..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/bin/ssh-agent-bitwarden" ~/.bin/
chmod +x ~/.bin/ssh-agent-bitwarden

# .bashrc anpassen falls nötig
if ! grep -q "Bitwarden SSH-Agent Bridge" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'EOF'

# Bitwarden SSH-Agent Bridge
export PATH=~/.bin:$PATH
export SSH_AUTH_SOCK=~/.ssh/sockets/bitwarden-agent.sock
if command -v socat >/dev/null 2>&1; then
    ~/.bin/ssh-agent-bitwarden start >/dev/null 2>&1 &
fi
EOF
    echo "  ~/.bashrc angepasst"
fi
echo "  OK"

# Starten
echo ""
echo "Starte Bridge..."
~/.bin/ssh-agent-bitwarden start

echo ""
echo "==============================================="
echo "  Installation abgeschlossen!"
echo "==============================================="
echo ""
echo "Nächste Schritte:"
echo "  1. Bitwarden Vault entsperren"
echo "  2. Neue Shell: exec bash -l"
echo "  3. Testen: ssh-add -l"
echo ""
echo "Weitere Hilfe: cat $SCRIPT_DIR/README.md"