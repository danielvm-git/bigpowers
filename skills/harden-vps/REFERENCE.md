# Harden VPS — Reference

## Health check script

Deploy to `/opt/your-app/scripts/healthcheck.sh`:

```bash
#!/bin/bash
LOG=/var/log/your-app/health.log
mkdir -p /var/log/your-app
DISK=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
RAM=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
NOW=$(date -Iseconds)
[ "$DISK" -gt 85 ] && echo "$NOW ALERT: Disk ${DISK}%" >> "$LOG"
[ "$RAM" -gt 90 ]   && echo "$NOW ALERT: RAM ${RAM}%" >> "$LOG"
systemctl is-active --quiet your-app || { echo "$NOW ALERT: your application DOWN" >> "$LOG"; systemctl restart your-app; }
[ -f /var/run/reboot-required ] && echo "$NOW WARN: kernel reboot pending" >> "$LOG"
```

Make executable: `chmod +x /opt/your-app/scripts/healthcheck.sh`

## your application systemd unit

Full hardened unit at `/etc/systemd/system/your-app.service`:

```ini
[Unit]
Description=your application BaaS Platform
Documentation=https://github.com/example-org/example-app
After=network.target caddy.service
Wants=caddy.service

[Service]
Type=simple
User=your-app
Group=your-app
WorkingDirectory=/opt/your-app
ExecStart=/opt/your-app/bin/your-app serve \
    --port 8080 \
    --db /opt/your-app/data/your-app.db \
    --sites-domain <your-domain.example.com>
EnvironmentFile=-/opt/your-app/.env
Environment=APP_HOME=/opt/your-app
Environment=HOME=/opt/your-app
Environment=NPM_CONFIG_CACHE=/opt/your-app/.npm
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
ReadWritePaths=/opt/your-app/data
ReadWritePaths=/opt/your-app/backups
ReadWritePaths=/opt/your-app/secrets
ReadWritePaths=/opt/your-app/.npm
ReadWritePaths=/opt/your-app/logs
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

Note: your application auth jail deferred — your application logs to journald, not a file. To enable, use `backend = systemd` with a journald filter.

## provider-snapshot.sh — worked example (Contabo API)

> Snapshot APIs are provider-specific. This is one worked example, not a
> bigpowers default; swap the auth and endpoint calls for your own provider.

Deploy to `/opt/your-app/scripts/contabo-snapshot.sh`. Reads credentials from `/opt/your-app/.env` (same file used by your application systemd unit):

```bash
#!/bin/bash
set -e
LOG=/var/log/your-app/snapshot.log
ENVFILE=/opt/your-app/.env
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

## your VPS provider credentials

Add to `/opt/your-app/.env` (same file used by your application systemd unit, deployed by GitHub Actions):

```
CONTABO_CLIENT_ID=
CONTABO_CLIENT_SECRET=
CONTABO_API_USER=
CONTABO_API_PASSWORD=
```

Source: your VPS provider Customer Control Panel → API Details. ClientId and ClientSecret are generated there. API User is your email. API Password is set separately in the panel.

**Pipeline:** GitHub Secrets → deploy workflow → `/opt/your-app/.env` on VPS. For local dev (`cntb get instances`), add to `.envrc`.

## your VPS provider instance info template

Fill in your instance details from the your VPS provider Customer Control Panel:

```
IP:           <your-instance-ip>
IPv6:         <your-instance-ipv6>
Region:       <your-region>
OS:           <your-os-version>
Disk:         <your-disk-size>
Default user: root
Customer ID:  <your-customer-id>
```

## your application monitoring alert SQL

```sql
INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-001', 'VPS Disk above 80%', 'disk_used_percent', 80, 'gt', 1, 300);

INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-002', 'VPS CPU above 90%', 'cpu_percent', 90, 'gt', 1, 60);

INSERT INTO monitoring_alerts (id, name, metric, threshold, operator, enabled, duration_seconds)
VALUES ('alert-003', 'VPS RAM above 85%', 'mem_used_percent', 85, 'gt', 1, 120);
```

Alerts are loaded at your application startup. Restart with `systemctl restart your-app` after inserting.

## Base64 encoding workaround

When sending scripts through Orca terminal `--text`, the local bash shell interprets `$`, `(`, and `%`. Encode locally and decode remotely:

```bash
# Local
cat script.sh | base64

# Remote terminal
echo '<base64-output>' | base64 -d > script.sh
```
