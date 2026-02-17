#!/bin/bash
# =============================================================================
# skills-guard.sh - Enforce required project skills before work/commit
# =============================================================================
# Usage:
#   config/scripts/skills-guard.sh
#   config/scripts/skills-guard.sh --quiet
#
# Optional env:
#   REQUIRED_SKILLS="mise-expert,shell-scripting,systematic-debugging,verification-before-completion,menu-bar-dev"
# =============================================================================

set -euo pipefail

QUIET=false
for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
  esac
done

log() {
  if [ "$QUIET" = false ]; then
    echo "$*"
  fi
}

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
VALIDATE_SCRIPT="$PROJECT_ROOT/config/scripts/validate-skills.sh"

if [ ! -f "$VALIDATE_SCRIPT" ]; then
  echo "ERROR: validate-skills.sh not found at $VALIDATE_SCRIPT"
  exit 1
fi

if ! command -v bunx >/dev/null 2>&1; then
  echo "ERROR: bunx is required for skills management"
  exit 1
fi

if [ -n "${REQUIRED_SKILLS:-}" ]; then
  IFS=',' read -r -a REQUIRED <<< "$REQUIRED_SKILLS"
else
  REQUIRED=(
    "mise-expert"
    "shell-scripting"
    "systematic-debugging"
    "verification-before-completion"
    "menu-bar-dev"
  )
fi

log "=== Skills Guardrails ==="
log "Project: $PROJECT_ROOT"

# 1) Validate overall skills architecture/symlinks/format
if ! bash "$VALIDATE_SCRIPT" --quiet >/dev/null 2>&1; then
  echo "ERROR: skills validation failed. Run: mise run skills:validate"
  exit 1
fi

# 2) Enforce required workflow skills exist in canonical source
MISSING=()
for skill in "${REQUIRED[@]}"; do
  SKILL_FILE="$PROJECT_ROOT/.agents/skills/$skill/SKILL.md"
  if [ ! -f "$SKILL_FILE" ]; then
    MISSING+=("$skill")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: missing required skill(s): ${MISSING[*]}"
  echo "Fix: install/sync skills, then run: mise run skills:validate:fix && mise run skills:guard"
  exit 1
fi

log "OK: required workflow skills present (${REQUIRED[*]})"
exit 0
