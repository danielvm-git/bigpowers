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
    --sites-domain bigbase.click
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
INSTANCE_ID=vmi3338033

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

## Contabo instance info (vmi3338033)

```
IP:           89.116.26.187
IPv6:         2a02:c207:2333:8033::1
Region:       EU
OS:           Ubuntu 24.04.4 LTS
Disk:         200 GB (Cloud VPS 20 SSD)
Default user: root
Customer ID:  15027696
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
