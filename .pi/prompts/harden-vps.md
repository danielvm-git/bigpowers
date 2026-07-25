---
name: harden-vps
description: "Harden a production Linux VPS for BigBase across three layers — BigBase app (systemd hardening, monitoring alerts, backup automation), Ubuntu OS (UFW firewall, fail2ban SSH, unattended-upgrades, SSH hardening), and Contabo VPS (health checks, daily backups, monthly snapshots). Use when the user wants to secure a production server, harden a VPS, audit server security, or mentions production hardening, VPS security, or harden the server."
---

# Harden VPS

Three-layer production hardening for BigBase on Contabo VPS. Each layer independently verifiable. Apply OS first (firewall blocks attacks immediately), then BigBase (alerts + backups), then Contabo (snapshots). See [REFERENCE.md](REFERENCE.md) for full script bodies, systemd unit template, and gotchas.

## Quick start

SSH as root into the VPS. Find credentials in the Contabo Customer Control Panel.

> **HARD GATE** — Run `ufw status` first. No firewall = layer 1 takes priority over everything.

## Layer 1 — Ubuntu OS

```bash
# UFW
ufw default deny incoming && ufw default allow outgoing
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw enable
# → verify: ufw status | grep -q active

# fail2ban
apt install -y fail2ban
# Configure /etc/fail2ban/jail.local: sshd, maxretry=3, bantime=3600, findtime=600
systemctl restart fail2ban
# → verify: fail2ban-client status sshd

# unattended-upgrades
apt install -y unattended-upgrades && dpkg-reconfigure -plow unattended-upgrades
# → verify: systemctl is-active unattended-upgrades | grep -q active

# SSH: PermitRootLogin no, PasswordAuthentication no, PubkeyAuthentication yes
# → verify: sshd -T | grep -E 'permitrootlogin no|passwordauthentication no'

# Deploy healthcheck.sh → /opt/bigbase/scripts/healthcheck.sh
# Crontab: */5 * * * * /opt/bigbase/scripts/healthcheck.sh
```

## Layer 2 — BigBase application

```bash
# systemd: User=bigbase, NoNewPrivileges=yes, ProtectSystem=full,
#   ProtectKernelTunables=yes, ProtectKernelModules=yes,
#   ProtectControlGroups=yes, RestrictAddressFamilies=AF_INET AF_INET6,
#   RestrictRealtime=yes, PrivateTmp=yes, LimitNOFILE=65536
# → verify: systemctl show bigbase -p NoNewPrivileges -p ProtectSystem -p User

# Alerts (BigBase requires auth; insert via SQLite)
sqlite3 /opt/bigbase/data/bigbase.db "
INSERT INTO monitoring_alerts (id,name,metric,threshold,operator,enabled,duration_seconds)
VALUES ('a1','Disk >80%','disk_used_percent',80,'gt',1,300);
INSERT INTO monitoring_alerts (id,name,metric,threshold,operator,enabled,duration_seconds)
VALUES ('a2','CPU >90%','cpu_percent',90,'gt',1,60);
INSERT INTO monitoring_alerts (id,name,metric,threshold,operator,enabled,duration_seconds)
VALUES ('a3','RAM >85%','mem_used_percent',85,'gt',1,120);
"
systemctl restart bigbase

# Backup crontab (root):
# 0 2 * * * cp /opt/bigbase/data/bigbase.db /backup/bigbase-$(date +\%Y\%m\%d).db
# 0 3 * * * find /backup/ -name "bigbase-*.db" -mtime +90 -delete
```

## Layer 3 — Contabo VPS

```bash
# cntb CLI
curl -sL "$(curl -sL https://api.github.com/repos/contabo/cntb/releases/latest \
  | grep browser_download_url.*linux_amd64.tar.gz | head -1 | cut -d'"' -f4)" \
  | tar xz -C /usr/local/bin

# Snapshot script → /opt/bigbase/scripts/contabo-snapshot.sh (reads from /opt/bigbase/.env)
# Credentials as env vars in /opt/bigbase/.env (deployed by GitHub Actions):
#   CONTABO_CLIENT_ID, CONTABO_CLIENT_SECRET, CONTABO_API_USER, CONTABO_API_PASSWORD
# Crontab: 0 4 1 * * /opt/bigbase/scripts/contabo-snapshot.sh

# > HARD GATE — Snapshot cron silently fails until env vars are set in .env.
# Credentials source: Contabo Customer Panel → API Details.
# Local dev: add to .envrc. Production: GitHub Secrets → deploy → /opt/bigbase/.env
```

## CRITICAL GOTCHAS

1. **Shell escaping in Orca terminals:** `$VAR`, `$(…)`, and `%` get eaten by the local shell. Always use base64: `echo '<base64>' | base64 -d > script.sh`
2. **Crontab `%`:** cron interprets `%` as newline. Escape as `\%` in `$(date +\%Y\%m\%d)`
3. **fail2ban exit 255:** means a jail references a missing log file. Remove the broken jail, restart.
4. **BigBase alerts need auth:** POST to `/api/monitoring/alerts` requires Bearer token. Workaround: insert directly into SQLite, then restart BigBase.

## Verify all 8 gates

```bash
ufw status|grep -q active||echo FAIL:ufw
fail2ban-client status sshd>/dev/null 2>&1||echo FAIL:fail2ban
systemctl is-active unattended-upgrades|grep -q active||echo FAIL:unattended
sshd -T|grep -q 'permitrootlogin no'||echo FAIL:sshd
systemctl show bigbase -p NoNewPrivileges|grep -q yes||echo FAIL:systemd
systemctl is-active bigbase|grep -q active||echo FAIL:bigbase
sqlite3 /opt/bigbase/data/bigbase.db "SELECT count(*) FROM monitoring_alerts"|grep -q 3||echo FAIL:alerts
crontab -l|grep -q healthcheck&&crontab -l|grep -q bigbase.db&&crontab -l|grep -q contabo-snapshot||echo FAIL:crontab
echo ALL 8 GATES PASSED
```

→ verify: `test -f skills/harden-vps/REFERENCE.md`

---

# Harden VPS — Reference

## Health check script

Deploy to `/opt/bigbase/scripts/healthcheck.sh`:

```bash
#!/bin/bash
LOG=/var/log/bigbase/health.log
mkdir -p /var/log/bigbase
DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
RAM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
NOW=$(date -Iseconds)
[ "$DISK" -gt 85 ] && echo "$NOW ALERT: Disk ${DISK}%" >> "$LOG"
[ "$RAM" -gt 90 ]   && echo "$NOW ALERT: RAM ${RAM}%" >> "$LOG"
systemctl is-active --quiet bigbase || { echo "$NOW ALERT: BigBase DOWN" >> "$LOG"; systemctl restart bigbase; }
[ -f /var/run/reboot-required ] && echo "$NOW WARN: kernel reboot pending" >> "$LOG"
```

Make executable: `chmod +x /opt/bigbase/scripts/healthcheck.sh`

## BigBase systemd unit

Full hardened unit at `/etc/systemd/system/bigbase.service`:

```ini
[Unit]
Description=BigBase BaaS Platform
Documentation=https://github.com/danielvm-git/bigbase
After=network.target caddy.service
Wants=caddy.service

[Service]
Type=simple
User=bigbase
Group=bigbase
WorkingDirectory=/opt/bigbase
ExecStart=/opt/bigbase/bin/bigbase serve \
    --port 8080 \
    --db /opt/bigbase/data/bigbase.db \
    --sites-domain <your-domain.example.com>
EnvironmentFile=-/opt/bigbase/.env
Environment=BIGBASE_HOME=/opt/bigbase
Environment=HOME=/opt/bigbase
Environment=NPM_CONFIG_CACHE=/opt/bigbase/.npm
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Restart=always
RestartSec=5
StartLimitIntervalSec=60
StartLimitBurst=3
TimeoutStopSec=30
KillSignal=SIGTERM
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
RestrictAddressFamilies=AF_INET AF_INET6
RestrictRealtime=yes
ReadWritePaths=/opt/bigbase/data
ReadWritePaths=/opt/bigbase/backups
ReadWritePaths=/opt/bigbase/secrets
ReadWritePaths=/opt/bigbase/.npm
ReadWritePaths=/opt/bigbase/logs
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

## fail2ban jail.local

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

Note: BigBase auth jail deferred — BigBase logs to journald, not a file. To enable, use `backend = systemd` with a journald filter.

## contabo-snapshot.sh

Deploy to `/opt/bigbase/scripts/contabo-snapshot.sh`. Reads credentials from `/opt/bigbase/.env` (same file used by BigBase systemd unit):

```bash
#!/bin/bash
set -e
LOG=/var/log/bigbase/snapshot.log
ENVFILE=/opt/bigbase/.env
INSTANCE_ID=<your-contabo-instance-id>

[ -f "$ENVFILE" ] || { echo "$(date -Iseconds) ERROR: $ENVFILE missing" >> "$LOG"; exit 1; }
set -a; source "$ENVFILE"; set +a

[ -z "$CONTABO_CLIENT_ID" ] && { echo "$(date -Iseconds) ERROR: CONTABO_CLIENT_ID not set" >> "$LOG"; exit 1; }

TOKEN=$(curl -s -d "client_id=$CONTABO_CLIENT_ID" \
  -d "client_secret=$CONTABO_CLIENT_SECRET" \
  --data-urlencode "username=$CONTABO_API_USER" \
  --data-urlencode "password=$CONTABO_API_PASSWORD" \
  -d 'grant_type=password' \
  'https://auth.contabo.com/auth/realms/contabo/protocol/openid-connect/token' \
  | jq -r '.access_token')

[ -z "$TOKEN" ] || [ "$TOKEN" = "null" ] && { echo "$(date -Iseconds) ERROR: auth failed" >> "$LOG"; exit 1; }

curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-request-id: $(uuidgen 2>/dev/null || echo $RANDOM)" \
  "https://api.contabo.com/v1/compute/instances/${INSTANCE_ID}/snapshots" \
  | tee -a "$LOG"

echo >> "$LOG"
echo "$(date -Iseconds) Snapshot requested for $INSTANCE_ID" >> "$LOG"
```

## Contabo credentials

Add to `/opt/bigbase/.env` (same file used by BigBase systemd unit, deployed by GitHub Actions):

```
CONTABO_CLIENT_ID=
CONTABO_CLIENT_SECRET=
CONTABO_API_USER=
CONTABO_API_PASSWORD=
```

Source: Contabo Customer Control Panel → API Details. ClientId and ClientSecret are generated there. API User is your email. API Password is set separately in the panel.

**Pipeline:** GitHub Secrets → deploy workflow → `/opt/bigbase/.env` on VPS. For local dev (`cntb get instances`), add to `.envrc`.

## Contabo instance info template

Fill in your instance details from the Contabo Customer Control Panel:

```
IP:           <your-instance-ip>
IPv6:         <your-instance-ipv6>
Region:       <your-region>
OS:           <your-os-version>
Disk:         <your-disk-size>
Default user: root
Customer ID:  <your-customer-id>
```

## BigBase monitoring alert SQL

```sql
INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-001', 'VPS Disk above 80%', 'disk_used_percent', 80, 'gt', 1, 300);

INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-002', 'VPS CPU above 90%', 'cpu_percent', 90, 'gt', 1, 60);

INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-003', 'VPS RAM above 85%', 'mem_used_percent', 85, 'gt', 1, 120);
```

Alerts are loaded at BigBase startup. Restart with `systemctl restart bigbase` after inserting.

## Base64 encoding workaround

When sending scripts through Orca terminal `--text`, the local bash shell interprets `$`, `(`, and `%`. Encode locally and decode remotely:

```bash
# Local
cat script.sh | base64

# Remote terminal
echo '<base64-output>' | base64 -d > script.sh
```
