#!/usr/bin/env bash
# Remove plainsight: unload launchd job, delete plist, drop the /etc/hosts line.
set -euo pipefail
HOST="${HOST:-plainsight}"
LABEL="dev.local.plainsight"
AGENT="$HOME/Library/LaunchAgents/$LABEL.plist"
DAEMON="/Library/LaunchDaemons/$LABEL.plist"

for p in "$AGENT" "$DAEMON"; do
  if [[ -f "$p" ]]; then
    RUNAS=""; [[ "$p" == /Library/* ]] && RUNAS="sudo"
    $RUNAS launchctl unload "$p" 2>/dev/null || true
    $RUNAS rm -f "$p"
    echo "removed $p"
  fi
done

if grep -qE "^127\.0\.0\.1[[:space:]]+$HOST\$" /etc/hosts 2>/dev/null; then
  echo "removing hosts entry (needs sudo)"
  sudo sed -i '' "/^127\.0\.0\.1[[:space:]]\{1,\}$HOST\$/d" /etc/hosts
fi
echo "uninstalled."
