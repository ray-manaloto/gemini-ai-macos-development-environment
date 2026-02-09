#!/usr/bin/env bash
# =============================================================================
# secrets-status.sh - Validate secrets are mise-managed only
# =============================================================================

set -euo pipefail

MODE="${1:-status}"
QUIET_MODE=false

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET_MODE=true ;;
    --redacted) MODE="redacted" ;;
  esac
done

if [[ "$MODE" = "redacted" ]]; then
  export MISE_SECRETS_REDACTED=1
fi

if ! command -v mise &>/dev/null; then
  [[ "$MODE" != "--quiet" ]] && echo "mise not installed"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  [[ "$MODE" != "--quiet" ]] && echo "python3 not available"
  exit 1
fi

python3 - <<'PY'
import json
import os
import re
import subprocess
import sys

repo_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
config_path = os.path.join(repo_root, "config", "secrets.toml")

with open(config_path, "r", encoding="utf-8") as f:
    content = f.read()

# Minimal TOML parsing for [secrets] required = [ ... ]
secrets = []
in_secrets = False
collecting = False
buffer = []
for line in content.splitlines():
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        in_secrets = stripped == "[secrets]"
        collecting = False
        continue
    if not in_secrets:
        continue
    if stripped.startswith("required"):
        collecting = True
        buffer.append(stripped)
        if "]" in stripped:
            collecting = False
        continue
    if collecting:
        buffer.append(stripped)
        if "]" in stripped:
            collecting = False

if buffer:
    joined = " ".join(buffer)
    match = re.search(r"required\s*=\s*\[(.*)\]", joined)
    if match:
        items = match.group(1)
        secrets = re.findall(r"\"([^\"]+)\"", items)
if not secrets:
    print("No secrets registry found in config/secrets.toml")
    sys.exit(1)

env_cmd = ["mise", "env", "--json-extended"]
env_json = subprocess.check_output(env_cmd, text=True)
env = json.loads(env_json)

home = os.path.expanduser("~")
allowed_prefix = os.path.join(home, ".config", "mise")
allowed_file = os.path.join(home, ".config", "dev-env", ".env.json")

exit_code = 0
for key in secrets:
    entry = env.get(key)
    if not entry:
        print(f"MISSING|{key}|")
        exit_code = 2
        continue

    source = entry.get("source", "")
    if source.startswith(allowed_prefix) or source == allowed_file:
        if os.environ.get("MISE_SECRETS_REDACTED") == "1":
            print(f"OK|{key}|{source}|[REDACTED]")
        else:
            print(f"OK|{key}|{source}")
    else:
        print(f"INVALID|{key}|{source}")
        exit_code = 2

sys.exit(exit_code)
PY
