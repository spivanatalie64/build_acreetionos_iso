#!/usr/bin/env bash
# setup-cron.sh — install a systemd timer for daily automated builds
# usage: ./setup-cron.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

cat > /tmp/acreetionos-build.service << 'SERVICE'
[Unit]
Description=AcreetionOS Daily Build
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=natalie
WorkingDirectory=/home/natalie/github/build_acreetionos_iso
ExecStart=/home/natalie/github/build_acreetionos_iso/build-all.sh
ExecStartPost=/home/natalie/github/build_acreetionos_iso/test-iso.sh
StandardOutput=append:/var/log/acreetionos-build.log
StandardError=append:/var/log/acreetionos-build.log
SERVICE

cat > /tmp/acreetionos-build.timer << 'TIMER'
[Unit]
Description=Daily AcreetionOS build

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
TIMER

echo "==> Installing systemd service and timer..."
sudo cp /tmp/acreetionos-build.service /etc/systemd/system/acreetionos-build.service
sudo cp /tmp/acreetionos-build.timer /etc/systemd/system/acreetionos-build.timer
sudo systemctl daemon-reload
sudo systemctl enable acreetionos-build.timer
sudo systemctl start acreetionos-build.timer
echo "==> Timer installed. Runs daily at 6 AM (randomized delay)."
echo "    Check status: systemctl status acreetionos-build.timer"