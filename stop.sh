#!/usr/bin/env bash
# Stop plainsight using the PID it recorded in PID.txt.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$HERE/PID.txt"
if [[ ! -f "$PID_FILE" ]]; then
  echo "no PID.txt — plainsight not running (or crashed)"; exit 0
fi
PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID" && echo "stopped plainsight (pid $PID)"
else
  echo "pid $PID not alive; clearing stale PID.txt"; rm -f "$PID_FILE"
fi
