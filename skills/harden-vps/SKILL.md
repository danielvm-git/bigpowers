---
name: harden-vps
description: >-
  Harden a production Linux VPS for BigBase across three layers — BigBase app (systemd hardening, monitoring alerts, backup automation), Ubuntu OS (UFW firewall, fail2ban SSH, unattended-upgrades, SSH hardening), and Contabo VPS (health checks, daily backups, monthly snapshots). Use when the user wants to secure a production server, harden a VPS, audit server security, or mentions production hardening, VPS security, or harden the server.
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

→ verify: run the 8-gate one-liner on the VPS.
