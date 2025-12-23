# Factorio Proxmox LXC Installer

A Proxmox Helper Script for automatically creating a Factorio Dedicated Server LXC Container.

## 🚀 Quick Start (Standalone)

Run on the **Proxmox VE Shell**:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-bck/factorio-server/main/proxmox/factorio-standalone.sh)"
```

The script guides you through an interactive wizard:
- Container ID, Hostname
- CPU, RAM, Disk
- Network (DHCP or static IP)
- Storage selection
- Server name, description
- Public/Private (with Factorio.com credentials)
- Optional game password
- Optional: SSH Public Key for passwordless access

## 📁 Project Structure

```
proxmox/
├── factorio-standalone.sh    # Standalone Installer
└── README.md
```

## ⚙️ After Installation

### Server Management

```bash
# Enter the container
pct enter <CTID>

# Control the server
systemctl start factorio
systemctl stop factorio
systemctl restart factorio
systemctl status factorio

# View logs
journalctl -u factorio -f
```

### Modify Configuration

```bash
# Server settings
nano /opt/factorio/config/server-settings.json

# Restart after changes
systemctl restart factorio
```

### Important Files

| Path | Description |
|------|-------------|
| `/opt/factorio/saves/` | Savegames (including autosaves) |
| `/opt/factorio/mods/` | Mods |
| `/opt/factorio/config/server-settings.json` | Server configuration |
| `/opt/factorio/server-adminlist.json` | Admin list |

## 🔄 Updates

Run inside the container:

```bash
# Inside the container
systemctl stop factorio
cd /tmp
curl -fsSL "https://factorio.com/get-download/stable/headless/linux64" -o factorio.tar.xz
tar -xJf factorio.tar.xz -C /opt --overwrite
chown -R factorio:factorio /opt/factorio
systemctl start factorio
```

## 🔥 Firewall

If a firewall is active, open port 34197/UDP:

### Proxmox Firewall (Datacenter)

```bash
# /etc/pve/firewall/cluster.fw
[RULES]
IN UDP -p 34197 -j ACCEPT
```

### Container Firewall

```bash
# Inside the container
ufw allow 34197/udp
```

### Router Port Forwarding

| Protocol | External | Internal | Target |
|----------|----------|----------|--------|
| UDP | 34197 | 34197 | Container IP |

## 💾 Backup

### Factorio Autosave

Factorio automatically creates autosaves (default every 5 minutes) in `/opt/factorio/saves/`.

### Proxmox Container Backup (recommended)

Use the integrated Proxmox Backup for the entire container:

**Via GUI:**
1. Datacenter → Backup → Add
2. Select storage, schedule and container
3. Configure retention policy

**Via Command Line:**
```bash
# One-time backup
vzdump <CTID> --storage <backup-storage> --mode snapshot

# Scheduled backup (cron)
echo "0 3 * * * root vzdump <CTID> --storage local --mode snapshot --prune-backups keep-last=7" > /etc/cron.d/factorio-backup
```

## 🐛 Troubleshooting

### Server won't start

```bash
# Check logs
journalctl -u factorio --no-pager -n 50

# Start manually for debugging
sudo -u factorio /opt/factorio/bin/x64/factorio --start-server /opt/factorio/saves/world.zip
```

### No savegame available

```bash
# Create new savegame
sudo -u factorio /opt/factorio/bin/x64/factorio --create /opt/factorio/saves/world.zip
```

### Players cannot join

1. Check firewall rules
2. Check port forwarding in router
3. `visibility.lan: true` in server-settings.json

### Container has no IP

```bash
# On Proxmox host
pct exec <CTID> -- ip addr
pct exec <CTID> -- cat /etc/network/interfaces
pct exec <CTID> -- systemctl restart networking
```

## 📄 License

MIT License
