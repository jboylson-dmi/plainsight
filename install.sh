#!/usr/bin/env bash
# Portable installer for plainsight. Works on any macOS machine/user:
#   - maps a hostname (default: plainsight) -> 127.0.0.1 in /etc/hosts
#   - generates a per-user launchd agent from this repo's real path
#   - loads it (starts now, restarts on crash, starts at login)
#
# Usage:  ./install.sh            # host=plainsight  port=8477  -> http://plainsight:8477
#         HOST=notes PORT=8477 ./install.sh
#         PORT=80 ./install.sh    # clean http://plainsight (installs a root LaunchDaemon)
set -euo pipefail

HOST="${HOST:-plainsight}"
PORT="${PORT:-8477}"
HERE="$(cd "$(dirname "$0")" && pwd)"
LABEL="dev.local.plainsight"
PY="$(command -v python3 || echo /usr/bin/python3)"

echo "==> plainsight install  host=$HOST  port=$PORT  dir=$HERE"

# 1. /etc/hosts entry (idempotent) ------------------------------------------
if grep -qE "^[^#]*[[:space:]]$HOST(\$|[[:space:]])" /etc/hosts 2>/dev/null; then
  echo "  hosts: $HOST already mapped"
else
  echo "  hosts: adding '127.0.0.1 $HOST' (needs sudo)"
  echo "127.0.0.1 $HOST" | sudo tee -a /etc/hosts >/dev/null
fi

# 2. launchd job ------------------------------------------------------------
if [[ "$PORT" -lt 1024 ]]; then
  # Privileged port -> must run as root via a LaunchDaemon.
  PLIST="/Library/LaunchDaemons/$LABEL.plist"
  RUNAS="sudo"
  echo "  launchd: LaunchDaemon (root) for privileged port $PORT"
else
  PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
  RUNAS=""
  echo "  launchd: LaunchAgent (user) at $PLIST"
fi

$RUNAS tee "$PLIST" >/dev/null <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$PY</string>
    <string>$HERE/server.py</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict><key>PLAINSIGHT_PORT</key><string>$PORT</string></dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HERE/plainsight.log</string>
  <key>StandardErrorPath</key><string>$HERE/plainsight.log</string>
</dict>
</plist>
PLISTEOF

$RUNAS launchctl unload "$PLIST" 2>/dev/null || true
$RUNAS launchctl load "$PLIST"

sleep 1
echo "==> done.  open  http://$HOST$([ "$PORT" = 80 ] && echo '' || echo ":$PORT")/"
