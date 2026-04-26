# Bitwarden SSH-Agent nach WSL2 durchreichen

Verbindet den Bitwarden SSH-Agent (Windows) mit WSL2, sodass SSH-Clients in WSL die Bitwarden-Keys nutzen können.

## Quick Start

```bash
# 1. Repo klonen/entpacken nach ~/bitwarden-wsl-connect
cd ~/bitwarden-wsl-connect

# 2. Voraussetzungen prüfen
make check

# 3. Installieren
make install

# 4. Neue Shell öffnen und testen
ssh-add -l
```

## Verzeichnis-Struktur

```
bitwarden-wsl-connect/
├── README.md              # Diese Datei
├── SETUP.md               # Ausführliche Anleitung
├── TROUBLESHOOTING.md      # Probleme und Lösungen
├── install.sh            # Installationsskript
├── uninstall.sh           # Deinstallationsskript
├── Makefile             # Build-Targets
├── .gitignore           # Git-Ignore
├── bin/
│   └── ssh-agent-bitwarden  # Haupt-Bridge-Skript
└── config/
    └── bashrc-bitwarden     # .bashrc-Config
```

## Voraussetzungen

### Windows

- Windows 11 + WSL2
- Bitwarden Desktop App (2025.1.2+) mit SSH-Agent
- npiperelay.exe in `C:\tools\npiperelay.exe`

### WSL

- Ubuntu 24.04 (oder andere WSL2-Distribution)
- socat: `sudo apt install socat`

## SSH-Agent aktivieren

In Bitwarden Desktop App:
1. Settings → Developer
2. Enable SSH Agent einschalten
3. App neu starten

## npiperelay herunterladen

```powershell
# Windows PowerShell (als Admin):
iwr https://github.com/NT-broker/WSL-network-tools/releases/latest/download/npiperelay.zip -OutFile npiperelay.zip
Expand-Archive npiperelay.zip -DestinationPath C:\tools
Remove-Item npiperelay.zip
```

## Make-Targets

| Target | Beschreibung |
|--------|--------------|
| `make install` | Installation durchführen |
| `make uninstall` | Deinstallation |
| `make check` | Voraussetzungen prüfen |
| `make start` | Bridge starten |
| `make stop` | Bridge stoppen |
| `make restart` | Bridge neustarten |
| `make status` | Status anzeigen |
| `make test` | Keys testen |
| `make clean` | Temporäre Dateien |

## Befehle

```bash
# Bridge steuern
~/.bin/ssh-agent-bitwarden start   # Starten
~/.bin/ssh-agent-bitwarden stop    # Stoppen
~/.bin/ssh-agent-bitwarden status # Status

# Keys anzeigen
ssh-add -l

# SSH nutzen
ssh user@server

## SSH-Config für mehrere Keys nutzen

Wenn du mehrere SSH-Keys im Bitwarden hast (>6), erstelle eine SSH-Config:

```bash
# ~/.ssh/config
Host mein-server
  HostName 10.0.10.10
  User root
  IdentitiesOnly yes
  IdentityFile ~/.ssh/mein-server.pub
```

Dann: `ssh mein-server`

**Warum?**
- Ohne Config probiert SSH alle Keys durch → Server bricht nach 6 Versuchen ab ("Too many authentication failures")
- Mit `IdentityFile` wird nur der angegebene Key verwendet
- Die .pub Datei muss existieren und zum Key im Bitwarden passen

## Troubleshooting

Falls etwas nicht funktioniert, sieh in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) nach.

## Lizenz

MIT License - Verwendung auf eigene Verantwortung.