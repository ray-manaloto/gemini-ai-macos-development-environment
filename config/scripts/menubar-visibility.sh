#!/usr/bin/env bash
# =============================================================================
# menubar-visibility.sh - Validate menu bar process + visibility (best effort)
# =============================================================================

set -euo pipefail

PROCESS_NAME=""
PATTERN=""
LABEL="MenuBar"
MATCH=""
STATUS_FILE=""
STRICT_MODE=false

usage() {
  echo "Usage: $0 --process <name> [--pattern <pattern>] [--label <label>] [--match <text>]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --process)
      PROCESS_NAME="$2"
      shift 2
      ;;
    --pattern)
      PATTERN="$2"
      shift 2
      ;;
    --label)
      LABEL="$2"
      shift 2
      ;;
    --match)
      MATCH="$2"
      shift 2
      ;;
    --status-file)
      STATUS_FILE="$2"
      shift 2
      ;;
    --strict)
      STRICT_MODE=true
      shift 1
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$PROCESS_NAME" ]]; then
  usage
fi

process_running() {
  if [[ -n "$PATTERN" ]]; then
    pgrep -f "$PATTERN" >/dev/null 2>&1
  else
    pgrep -x "$PROCESS_NAME" >/dev/null 2>&1
  fi
}

if ! process_running; then
  echo "❌ $LABEL: process not running ($PROCESS_NAME)"
  exit 2
fi

# Prefer self-reported visibility status (no Accessibility needed)
if [[ -n "$STATUS_FILE" && -f "$STATUS_FILE" ]]; then
  NOW=$(date +%s)
  UPDATED=$(python3 - <<'PY' "$STATUS_FILE" 2>/dev/null || true
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
print(data.get("updated_at_epoch", 0))
PY
  )

  if [[ -n "$UPDATED" ]]; then
    AGE=$((NOW - UPDATED))
    if [[ "$AGE" -ge 0 && "$AGE" -le 120 ]]; then
      echo "✅ $LABEL: running + visible (self-reported)"
      exit 0
    fi
    if $STRICT_MODE; then
      echo "❌ $LABEL: running but self-report stale (${AGE}s)"
      exit 3
    fi
  fi
fi

# Best-effort visibility check via System Events
VISIBILITY_RESULT=$(osascript <<'APPLESCRIPT' "$PROCESS_NAME" "$MATCH" 2>/dev/null || true
on run argv
  set targetProcess to item 1 of argv
  set matchText to ""
  if (count of argv) > 1 then
    set matchText to item 2 of argv
  end if
  tell application "System Events"
    if not (exists process targetProcess) then
      return "PROCESS_MISSING"
    end if
    try
      tell process "SystemUIServer"
        if matchText is "" then
          set matchText to targetProcess
        end if
        set matchDesc to count of (menu bar items of menu bar 1 whose description contains matchText)
        if matchDesc > 0 then
          return "VISIBLE"
        end if
        set matchName to count of (menu bar items of menu bar 1 whose name contains matchText)
        if matchName > 0 then
          return "VISIBLE"
        end if
      end tell
    on error
      return "NO_ACCESS"
    end try
  end tell
  return "NOT_VISIBLE"
end run
APPLESCRIPT
)

case "$VISIBILITY_RESULT" in
  VISIBLE)
    echo "✅ $LABEL: running + visible"
    exit 0
    ;;
  NOT_VISIBLE)
    echo "⚠️  $LABEL: running but not visible (verify menu bar managers/Spaces)"
    exit 3
    ;;
  NO_ACCESS)
    echo "⚠️  $LABEL: running but visibility unknown (grant Accessibility to Terminal)"
    exit 0
    ;;
  PROCESS_MISSING)
    echo "❌ $LABEL: process not running ($PROCESS_NAME)"
    exit 2
    ;;
  *)
    echo "⚠️  $LABEL: running but visibility unknown"
    exit 0
    ;;
esac
