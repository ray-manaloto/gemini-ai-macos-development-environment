---
name: shell-scripting
description: "Shell scripting patterns for this project's bash scripts (setup.sh, SwiftBar plugin, config/scripts/, mise tasks). Use when writing or modifying shell scripts, bash functions, shell one-liners, or mise task run commands. Triggers on: bash scripts, shell functions, setup.sh changes, SwiftBar plugin modifications, validate.sh, or any .sh file editing."
---

# Shell Scripting

This project's shell scripts follow strict conventions. All scripts are bash, run user-space only, and integrate with mise.

## Key Scripts

| Script | Purpose | Lines |
|--------|---------|-------|
| `setup.sh` | Bootstrap entire environment | ~300 |
| `DevEnvManager-SwiftBar/dev-status.5s.sh` | SwiftBar menu bar plugin | 503 |
| `config/scripts/validate.sh` | Health check | ~100 |
| `config/scripts/dashboard.py` | TUI dashboard (Python) | ~200 |

## Conventions

### Header

```bash
#!/usr/bin/env bash
set -euo pipefail
```

Every script MUST have `set -euo pipefail`:
- `set -e`: Exit on error
- `set -u`: Error on undefined variables
- `set -o pipefail`: Pipe failures propagate

### Color Output

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
```

### Command Checks

```bash
command -v mise &> /dev/null || { error "mise not found"; exit 1; }
```

### No Sudo

NEVER use `sudo` in any script. All operations are user-space:
- Install to `~/.local/`
- Config in `~/.config/`
- Data in `~/.local/share/`

### ShellCheck

All scripts must pass ShellCheck. Run:

```bash
shellcheck setup.sh
shellcheck config/scripts/*.sh
shellcheck DevEnvManager-SwiftBar/dev-status.5s.sh
```

Common fixes:
- Quote variables: `"$var"` not `$var`
- Use `[[ ]]` not `[ ]` for string comparisons
- Use `$()` not backticks
- Declare and assign separately: `local var; var=$(cmd)`

### SwiftBar Plugin Pattern

The SwiftBar plugin (`DevEnvManager-SwiftBar/dev-status.5s.sh`) uses a specific output format:

```bash
# Title bar (first line)
echo "🟢 dev:OK"
echo "---"
# Menu items
echo "Item Name | color=green"
echo "--Sub Item | bash=command param1=value"
echo "---"
echo "Section Header | size=12"
```

Key SwiftBar conventions:
- `5s` in filename = refresh every 5 seconds
- Use `|` pipe for formatting: `color=`, `size=`, `font=`, `bash=`
- `---` creates separators
- `--` prefix creates submenu items
- Icons: Use emoji or base64 images

### Mise Task Scripts

When tasks need complex logic, extract to `config/scripts/`:

```toml
[tasks.my-task]
description = "My task"
run = "bash config/scripts/my-task.sh"
```
