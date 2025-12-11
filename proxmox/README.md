# Factorio Proxmox LXC Installer

Ein Proxmox Helper Script zum automatischen Erstellen eines Factorio Dedicated Server LXC Containers.

## 🚀 Schnellstart (Standalone)

Auf der **Proxmox VE Shell** ausführen:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-bck/factorio-server/main/proxmox/factorio-standalone.sh)"
```

Das Script führt dich durch einen interaktiven Wizard:
- Container ID, Hostname
- CPU, RAM, Disk
- Netzwerk (DHCP oder statische IP)
- Storage-Auswahl
- Optional: Samba Backup-Mount

## 📁 Projektstruktur

```
proxmox/
├── factorio-standalone.sh    # Standalone Installer
└── README.md
```

## ⚙️ Nach der Installation

### Server-Verwaltung

```bash
# In den Container wechseln
pct enter <CTID>

# Server steuern
systemctl start factorio
systemctl stop factorio
systemctl restart factorio
systemctl status factorio

# Logs anzeigen
journalctl -u factorio -f
```

### Konfiguration anpassen

```bash
# Server-Einstellungen
nano /opt/factorio/config/server-settings.json

# Nach Änderungen neu starten
systemctl restart factorio
```

### Wichtige Dateien

| Pfad | Beschreibung |
|------|--------------|
| `/opt/factorio/saves/` | Savegames |
| `/opt/factorio/mods/` | Mods |
| `/opt/factorio/config/server-settings.json` | Server-Konfiguration |
| `/opt/factorio/config/server-adminlist.json` | Admin-Liste |
| `/backup/` | Backup-Verzeichnis (Samba-Mount) |

## 🔄 Updates

Im Container ausführen:

```bash
# Im Container
systemctl stop factorio
cd /tmp
curl -fsSL "https://factorio.com/get-download/stable/headless/linux64" -o factorio.tar.xz
tar -xJf factorio.tar.xz -C /opt --overwrite
chown -R factorio:factorio /opt/factorio
systemctl start factorio
```

## 🔥 Firewall

Falls eine Firewall aktiv ist, Port 34197/UDP freigeben:

### Proxmox Firewall (Datacenter)

```bash
# /etc/pve/firewall/cluster.fw
[RULES]
IN UDP -p 34197 -j ACCEPT
```

### Container Firewall

```bash
# Im Container
ufw allow 34197/udp
```

### Router Port-Forwarding

| Protokoll | Extern | Intern | Ziel |
|-----------|--------|--------|------|
| UDP | 34197 | 34197 | Container-IP |

## 💾 Backup

### Manuelles Backup

```bash
/opt/factorio/backup.sh
```

### Automatisches Backup (täglich 4:00)

Wird automatisch per Cron eingerichtet.

### Backup auf Samba-Share

Falls bei der Installation konfiguriert, werden Backups automatisch auf den Samba-Share geschrieben.

Nachträglich konfigurieren:

```bash
# Credentials speichern
echo "username=backup_user" > /root/.smbcredentials
echo "password=backup_pass" >> /root/.smbcredentials
chmod 600 /root/.smbcredentials

# fstab Eintrag
echo "//192.168.1.100/backup/factorio /backup cifs credentials=/root/.smbcredentials,uid=factorio,gid=factorio 0 0" >> /etc/fstab

# Mounten
mount -a
```

## 🐛 Troubleshooting

### Server startet nicht

```bash
# Logs prüfen
journalctl -u factorio --no-pager -n 50

# Manuell starten zum Debuggen
sudo -u factorio /opt/factorio/bin/x64/factorio --start-server /opt/factorio/saves/world.zip
```

### Kein Savegame vorhanden

```bash
# Neues Savegame erstellen
sudo -u factorio /opt/factorio/bin/x64/factorio --create /opt/factorio/saves/world.zip
```

### Spieler können nicht beitreten

1. Firewall-Regeln prüfen
2. Port-Forwarding im Router prüfen
3. `visibility.lan: true` in server-settings.json

### Container hat keine IP

```bash
# Im Proxmox Host
pct exec <CTID> -- ip addr
pct exec <CTID> -- cat /etc/network/interfaces
pct exec <CTID> -- systemctl restart networking
```

## 📄 Lizenz

MIT License
