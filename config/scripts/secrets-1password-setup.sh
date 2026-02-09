#!/usr/bin/env bash
# =============================================================================
# secrets-1password-setup.sh - Apply op:// secrets to mise global config
# =============================================================================

set -euo pipefail

if ! command -v mise &>/dev/null; then
  echo "mise not installed"
  exit 1
fi

if ! command -v op &>/dev/null; then
  echo "1Password CLI (op) not installed"
  echo "Install: mise use -g 1password-cli"
  exit 1
fi

if ! op whoami &>/dev/null; then
  echo "Not signed in to 1Password. Run: op signin"
  exit 1
fi

CONFIG_FILE="${1:-$(dirname "${BASH_SOURCE[0]}")/../secrets.1password.toml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing config: $CONFIG_FILE"
  exit 1
fi

while IFS='|' read -r key value; do
  if [[ -n "$key" && -n "$value" ]]; then
    mise set -g "$key=$value"
    echo "Set $key via op://"
  fi
done < <(python3 - <<'PY' "$CONFIG_FILE"
import os
import re
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    content = f.read().splitlines()

in_op = False
for line in content:
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        in_op = stripped == "[op]"
        continue
    if not in_op or not stripped or stripped.startswith("#"):
        continue
    match = re.match(r"([A-Z0-9_]+)\s*=\s*\"(op://[^\"]+)\"", stripped)
    if not match:
        continue
    key, value = match.group(1), match.group(2)
    print(f"{key}|{value}")
PY
)

echo "Done. Verify with: mise env --redacted | grep -E \"GITHUB|ANTHROPIC|OPENAI|CONTEXT7|EXA\""
