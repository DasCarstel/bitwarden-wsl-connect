# Troubleshooting - Bitwarden SSH-Agent nach WSL2 durchreichen

## Schnellprüfung

```bash
# 1. Läuft die Bridge?
~/.bin/ssh-agent-bitwarden status

# 2. Existiert der Socket?
ls -la ~/.ssh/sockets/bitwarden-agent.sock

# 3. Läuft npiperelay?
ps aux | grep npiperelay

# 4. Funktioniert ssh-add?
ssh-add -l
```

## Häufige Probleme

### Problem: "error fetching identities: communication with agent failed"

**Ursache:** socat/npiperelay-Connection ist fehlgeschlagen.

**Lösung:**
```bash
# Bridge neu starten
~/.bin/ssh-agent-bitwarden stop
~/.bin/ssh-agent-bitwarden start
```

---

### Problem: "Could not open a connection to your authentication agent"

**Ursache:** SSH_AUTH_SOCK ist nicht gesetzt oder Bridge läuft nicht.

**Lösung:**
```bash
# 1. Prüfen ob Variable gesetzt ist
echo $SSH_AUTH_SOCK

# 2. Falls leer, Shell-Neustart
exec bash -l

# 3. Oder manuell setzen
export SSH_AUTH_SOCK=~/.ssh/sockets/bitwarden-agent.sock
~/.bin/ssh-agent-bitwarden start

# 4. Testen
ssh-add -l
```

---

### Problem: "execvp(..., npiperelay.exe.exe): No such file or directory"

**Ursache:** Doppelte .exe-Endung im Skript.

**Lösung:**
```bash
# Pfad in ~/.bin/ssh-agent-bitwarden prüfen:
grep NPIPERELAY ~/.bin/ssh-agent-bitwarden
# Soll sein: NPIPERELAY="/mnt/c/tools/npiperelay"  (OHNE .exe)
```

---

### Problem: "mkfifo(//./pipe/openssh-ssh-agent): No such file or directory"

**Ursache:** Bitwarden SSH-Agent ist nicht aktiv.

**Lösung:**
1. Bitwarden Desktop öffnen
2. Settings → Developer → Enable SSH Agent einschalten
3. Bitwarden neu starten
4. Vault entsperren

---

### Problem: "socket already in use"

**Ursache:** Ein alter socat-Prozess läuft noch.

**Lösung:**
```bash
# Alte Prozesse kills
pkill -f "socat.*bitwarden"
pkill -f "npiperelay"

# Socket-Datei löschen
rm -f ~/.ssh/sockets/bitwarden-agent.sock

# Neu starten
~/.bin/ssh-agent-bitwarden start
```

---

### Problem: Keys werden nicht angezeigt

**Ursache:** Vault ist gesperrt oder keine SSH-Keys konfiguriert.

**Lösung:**
```bash
# 1. Bitwarden entsperren
# 2. Prüfen ob Keys konfiguriert sind:
#    Bitwarden → Settings → SSH Keys
# 3. Bridge neu starten
~/.bin/ssh-agent-bitwarden stop && ~/.bin/ssh-agent-bitwarden start
```

---

### Problem: SSH-Verbindung funktioniert nicht

**Ursache:** Key nicht geladen oder falscher Key.

**Lösung:**
```bash
# 1. Alle verfügbaren Keys anzeigen
ssh-add -l

# 2.IdentityFile explizit angeben
ssh -i ~/.ssh/id_ed25519 user@server

# 3. Oder mit verbose
ssh -v user@server
```

---

### Problem: .bashrc wird nicht geladen

**Lösung:**
```bash
# Prüfen ob .bashrc existiert und nicht leer ist
ls -la ~/.bashrc

# Manuell sourcen
source ~/.bashrc

# Falls .bash_profile existiert, prüfen ob .bashrc dort geladen wird
cat ~/.bash_profile
```

---

### Problem: npiperelay.exe nicht gefunden

**Ursache:** Falscher Pfad oder nicht installiert.

**Lösung:**
```bash
# Prüfen ob Datei existiert
ls -la /mnt/c/tools/npiperelay.exe

# Falls nicht, herunterladen:
# Siehe SETUP.md für Download-Links
```

---

### Problem: "permission denied" bei Socket

**Ursache:** Falsche Rechte auf Socket-Verzeichnis.

**Lösung:**
```bash
chmod 700 ~/.ssh/sockets
chmod 600 ~/.ssh/sockets/bitwarden-agent.sock
```

---

### Problem: Bridge startet nicht automatisch

**Lösung:**
```bash
# Manuell testen
~/.bin/ssh-agent-bitwarden start

# Falls erfolgreich, in .bashrc eintragen:
# Siehe SETUP.md "Installation"
```

---

## Fortgeschrittene Diagnose

### Debug-Modus aktivieren

```bash
# Bridge mit Debug-Ausgabe starten
~/.bin/ssh-agent-bitwarden start

# Manuell mit verbose
bash -x ~/.bin/ssh-agent-bitwarden
```

### Prozesse prüfen

```bash
# Alle relevanten Prozesse
ps aux | grep -E "(socat|npiperelay|bitwarden)"

# Netzwerk-Verbindungen (falls relevant)
netstat -ano | findstr 22
```

### Windows Named Pipe prüfen

```powershell
# In PowerShell (Windows):
Get-ChildItem \\.\pipe\ | Where-Object { $_.Name -like "*ssh*" }
```

### Log-Analyse

```bash
# Letzte Fehler im Syslog
journalctl -xn 50 --no-pager

# Oder dmesg
dmesg | tail -20
```

---

## Notfall-Wiederherstellung

### Vollständiger Reset

```bash
# 1. Alle Prozesse stoppen
~/.bin/ssh-agent-bitwarden stop
pkill -f socat
pkill -f npiperelay

# 2. Socket löschen
rm -f ~/.ssh/sockets/bitwarden-agent.sock

# 3. Bridge neu starten
~/.bin/ssh-agent-bitwarden start

# 4. Testen
ssh-add -l
```

### Fallback: Windows OpenSSH-Agent

Falls Bitwarden's nicht funktioniert, kann man auch den Windows OpenSSH-Agent nutzen:

```bash
# Named Pipe direkt nutzen (ohne Bitwarden)
socat UNIX-LISTEN:$HOME/.ssh/sockets/windows-agent.sock,fork,mode=600 \
    EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork,pipes &

export SSH_AUTH_SOCK=$HOME/.ssh/sockets/windows-agent.sock
```

---

## Get-Help-Befehle

| Problem | Befehl |
|---------|-------|
| Bridge starten | `~/.bin/ssh-agent-bitwarden start` |
| Bridge stoppen | `~/.bin/ssh-agent-bitwarden stop` |
| Status prüfen | `~/.bin/ssh-agent-bitwarden status` |
| Keys zeigen | `~/.bin/ssh-agent-bitwarden` |
| Keys neu laden | `ssh-add -l` |
| Socket prüfen | `ls -la ~/.ssh/sockets/` |
| Prozesse prüfen | `ps aux \| grep socat` |

---

## Weiterführende Hilfe

- GitHub Issues: https://github.com/anomalyco/opencode/issues
- Bitwarden Support: https://bitwarden.com/help/
- socat Dokumentation: http://www.dest-unreach.org/socat/
- npiperelay: https://github.com/NT-broker/WSL-network-tools