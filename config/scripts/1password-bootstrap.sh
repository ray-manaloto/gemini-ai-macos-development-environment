#!/usr/bin/env bash
# =============================================================================
# 1password-bootstrap.sh - Create required 1Password items for mise secrets
# =============================================================================

set -euo pipefail

VAULT="${VAULT:-Private}"
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --vault=*) VAULT="${arg#*=}" ;;
  esac
done

if ! command -v op &>/dev/null; then
  echo "1Password CLI (op) not installed"
  echo "Install: mise use -g 1password-cli"
  exit 1
fi

if ! op whoami &>/dev/null; then
  echo "Not signed in to 1Password. Run: eval \"\$(op signin)\""
  exit 1
fi

prompt_secret() {
  local label="$1"
  local value
  printf "%s" "$label: "
  IFS= read -rs value
  printf "\n"
  echo "$value"
}

ensure_item() {
  local title="$1"
  local field="$2"
  local value="$3"

  if op item get "$title" --vault "$VAULT" &>/dev/null; then
    if $FORCE; then
      op item edit "$title" --vault "$VAULT" "$field=$value" >/dev/null
      echo "Updated $title ($field)"
    else
      echo "Exists: $title (use --force to update)"
    fi
    return 0
  fi

  op item create --category="API Credential" --title "$title" --vault "$VAULT" "$field=$value" >/dev/null
  echo "Created: $title"
}

echo "Vault: $VAULT"
echo "Creating required items (values are not echoed)."

GITHUB_TOKEN_VALUE=$(prompt_secret "GITHUB_TOKEN")
ANTHROPIC_VALUE=$(prompt_secret "ANTHROPIC_API_KEY")
OPENAI_VALUE=$(prompt_secret "OPENAI_API_KEY")
CONTEXT7_VALUE=$(prompt_secret "CONTEXT7_API_KEY")
EXA_VALUE=$(prompt_secret "EXA_API_KEY")

ensure_item "GitHub Token" "token" "$GITHUB_TOKEN_VALUE"
ensure_item "Anthropic" "credential" "$ANTHROPIC_VALUE"
ensure_item "OpenAI" "api_key" "$OPENAI_VALUE"
ensure_item "Context7" "api_key" "$CONTEXT7_VALUE"
ensure_item "Exa" "api_key" "$EXA_VALUE"

echo "Done. Apply to mise with:"
echo "  bash config/scripts/secrets-1password-setup.sh"
