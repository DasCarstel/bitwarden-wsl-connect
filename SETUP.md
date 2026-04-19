# Bitwarden SSH-Agent nach WSL2 durchreichen - Setup-Anleitung

## Übersicht

Dieses Setup ermöglicht es, die SSH-Keys aus dem Bitwarden Vault in WSL2 (Ubuntu 24.04) zu nutzen. Die Kommunikation läuft über:

```
WSL SSH-Client → Unix Socket (socat) → npiperelay.exe → Windows Named Pipe → Bitwarden
```

## Voraussetzungen

### 1. Windows-Seite

#### Bitwarden SSH-Agent aktivieren

1. Bitwarden Desktop App öffnen
2. Settings (Zahnrad) → Developer (Entwickler)
3. **Enable SSH Agent** einschalten
4. App neu starten

#### npiperelay.exe installieren

npiperelay verbindet Windows Named Pipes mit Unix Sockets.

**Download:**
```powershell
# Direkt via PowerShell (empfohlen):
iwr https://github.com/NT-broker/WSL-network-tools/releases/latest/download/npiperelay.zip -OutFile npiperelay.zip
Expand-Archive npiperelay.zip -DestinationPath C:\tools
Remove-Item npiperelay.zip
```

**Oder manuell:**
1. Von https://github.com/NT-broker/WSL-network-tools/releases herunterladen
2. Entpacken nach `C:\tools\npiperelay.exe`

**Pfad verifizieren:**
```powershell
Test-Path C:\tools\npiperelay.exe
```

### 2. WSL-Seite

#### socat installieren

```bash
sudo apt update
sudo apt install socat
```

#### Verzeichnisse erstellen

```bash
mkdir -p ~/.ssh/sockets
mkdir -p ~/.bin
```

## Installation

### Option A: Automatisch (empfohlen)

```bash
cd ~/bitwarden-wsl-connect
make install
```

### Option B: Manuell

1. **Skript kopieren:**
```bash
cp bin/ssh-agent-bitwarden ~/.bin/
chmod +x ~/.bin/ssh-agent-bitwarden
```

2. **.bashrc anpassen:**
```bash
# Diese Zeilen zu ~/.bashrc hinzufügen:

# Bitwarden SSH-Agent Bridge
export PATH=~/.bin:$PATH
export SSH_AUTH_SOCK=~/.ssh/sockets/bitwarden-agent.sock
if command -v socat >/dev/null 2>&1; then
    ~/.bin/ssh-agent-bitwarden start >/dev/null 2>&1 &
fi
```

3. **Shell neu starten:**
```bash
exec bash -l
```

## Verifizierung

### 1. Bridge-Status prüfen

```bash
~/.bin/ssh-agent-bitwarden status
```

### 2. Keys auflisten

```bash
ssh-add -l
```

Wenn Keys angezeigt werden → **Erfolg!**

### 3. SSH-Verbindung testen

```bash
ssh -T git@github.com
# Oder mit einem eigenen Server
ssh user@dein-server
```

## Funktionsweise

### Der Bridge-Prozess

1. `socat` erstellt einen Unix Socket unter `~/.ssh/sockets/bitwarden-agent.sock`
2. Wenn ein SSH-Client eine Anfrage stellt, leitet socat diese an npiperelay.exe weiter
3. npiperelay.exe übersetzt die Anfrage und sendet sie an die Windows Named Pipe `\\.\pipe\openssh-ssh-agent`
4. Bitwarden empfängt die Anfrage, prüft den Key und antwortet

### Umgebungsvariablen

- `SSH_AUTH_SOCK` - Pfad zum Unix Socket
- Pfad zu `~/.bin` - wo das Bridge-Skript liegt

### Wichtige Pfade

| Komponente | Pfad |
|-----------|------|
| Bridge-Skript | `~/.bin/ssh-agent-bitwarden` |
| Unix Socket | `~/.ssh/sockets/bitwarden-agent.sock` |
| Windows Named Pipe | `\\.\pipe\openssh-ssh-agent` |
| npiperelay | `C:\tools\npiperelay.exe` |

## Deinstallation

```bash
cd ~/bitwarden-wsl-connect
make uninstall
```

Oder manuell:
```bash
# Bridge stoppen
~/.bin/ssh-agent-bitwarden stop

# Zeilen aus ~/.bashrc entfernen (der Block "# Bitwarden SSH-Agent Bridge")
nano ~/.bashrc
```

## Wartung

### Bridge manuell steuern

```bash
# Starten
~/.bin/ssh-agent-bitwarden start

# Stoppen
~/.bin/ssh-agent-bitwarden stop

# Status prüfen
~/.bin/ssh-agent-bitwarden status

# Keys auflisten
~/.bin/ssh-agent-bitwarden
```

### Bei Problemen

Siehe [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Nach Neustart

Die Bridge startet automatisch bei jeder neuen Shell. Kein Handlungsbedarf.

### Nach Bitwarden-Update

Falls nach einem Bitwarden-Update die Pipe nicht mehr funktioniert:
1. Bitwarden neu starten
2. Bridge neu starten: `~/.bin/ssh-agent-bitwarden restart`

## Sicherheitshinweise

1. **Vault entsperren** - Die Bridge funktioniert nur wenn der Bitwarden Vault entsperrt ist
2. **npiperelay.exe Vertrauen** - Nur von vertrauenswürdigen Quellen herunterladen
3. **Socket-Rechte** - Der Socket hat Modus 600 (nur Owner)
4. **Keine Keys auf Disk** - SSH-Keys bleiben im Vault, nie auf der Festplatte

## Getestete Konfigurationen

- Windows 11 Pro + WSL2 (Ubuntu 24.04) ✓
- Bitwarden Desktop 2025.1.2+ ✓
- socat 1.7.4+ ✓

## Bekannte Einschränkungen

1. **WSL1 nicht unterstützt** - Nur WSL2 kann auf Windows Named Pipes zugreifen
2. **Gesperrter Vault** - Bei gesperrtem Vault keine Keys verfügbar
3. **Single-Session** - Nur eine gleichzeitige WSL-Instanz wird unterstützt (andere können den Socket nicht öffnen)