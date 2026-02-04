# macOS Testing and Sandbox Environments

**Last Updated:** 2026-02-03

This document outlines strategies for testing macOS-specific configurations when primary development happens in Linux DevContainers.

---

## Problem Statement

The God-Tier macOS Development Environment is designed for macOS but developed using:

1. **DevContainers** (Ubuntu 24.04) for consistent, reproducible development
2. **SkyPilot** cloud agents (Ubuntu-based) for heavy workloads

This creates a testing gap: How do we validate macOS-specific features like:
- `setup.sh` bootstrap script
- macOS defaults (`config/scripts/macos-defaults.sh`)
- Homebrew cask installations (GUI apps only)
- Shell integration (`.zshrc` on macOS vs `.bashrc` on Linux)
- Mise shims behavior on macOS

---

## Tool Comparison

| Tool | License | Use Case | Pros | Cons |
|------|---------|----------|------|------|
| **Tart** | Fair Source | macOS VMs on Apple Silicon | OCI registry, pre-built images, CI integration | Fair Source license, Apple Silicon only |
| **Lume** | MIT | macOS VMs with API server | MIT license, Python SDK, newer features | Less mature, newer project (Feb 2025) |
| **UTM** | Apache 2.0 | GUI-focused macOS VMs | User-friendly, QEMU-based | Slower, more manual setup |
| **nix-darwin** | MIT | Declarative macOS config | Rollback support, reproducible | Steep learning curve, paradigm shift |
| **APFS Snapshots** | Built-in | Quick rollback | Zero cost, fast | Limited to local machine |
| **GitHub Actions** | N/A | CI testing | No local setup, free tier | Limited minutes, no GUI testing |
| **Separate User** | Built-in | Isolation | Simple, no VMs | Limited isolation, shared kernel |

---

## Recommended Approaches

### Option A: Tart (Local macOS VMs)

Best for: Full macOS environment testing with automation.

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Pull pre-built macOS image
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest sequoia-test

# Run VM
tart run sequoia-test

# SSH into VM (after setup)
ssh admin@$(tart ip sequoia-test)
```

**Mise tasks for Tart:**

```toml
[tasks."vm:clone"]
description = "Clone macOS VM from registry"
run = "tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest godtier-test"

[tasks."vm:run"]
description = "Run macOS VM"
run = "tart run godtier-test"

[tasks."vm:test"]
description = "Run tests in macOS VM"
run = '''
#!/bin/bash
VM_IP=$(tart ip godtier-test)
scp -r . admin@$VM_IP:~/godtier-env/
ssh admin@$VM_IP "cd ~/godtier-env && ./setup.sh && bats tests/"
'''

[tasks."vm:delete"]
description = "Delete macOS VM"
run = "tart delete godtier-test"
```

### Option B: Lume (Newer Alternative)

Best for: API-driven automation, Python scripting.

```bash
# Install Lume
brew tap trycua/lume && brew install lume

# Start Lume daemon
lume serve &

# Run macOS VM
lume run macos-sequoia-vanilla:latest

# Python SDK example
from pylume import LumeClient
client = LumeClient()
vm = client.run("macos-sequoia-vanilla:latest")
vm.exec("./setup.sh")
```

### Option C: GitHub Actions (CI Testing)

Best for: Automated PR validation without local setup.

```yaml
# .github/workflows/macos-test.yml
name: macOS Tests

on:
  pull_request:
    branches: [main]

jobs:
  test-macos:
    runs-on: macos-14  # macOS Sonoma on M1
    steps:
      - uses: actions/checkout@v4

      - name: Run setup script
        run: ./setup.sh

      - name: Run tests
        run: |
          eval "$(mise activate bash --shims)"
          bats tests/

      - name: Validate environment
        run: mise run validate
```

### Option D: APFS Snapshots (Quick Rollback)

Best for: Manual testing with safety net.

```bash
# Create snapshot before testing
sudo tmutil localsnapshot

# List snapshots
tmutil listlocalsnapshots /

# Mount snapshot (read-only)
SNAP=$(tmutil listlocalsnapshots / | tail -1)
mkdir /tmp/snap
mount_apfs -s $SNAP / /tmp/snap

# Delete snapshot after testing
sudo tmutil deletelocalsnapshots <snapshot-date>
```

**Mise tasks for snapshots:**

```toml
[tasks."snapshot:create"]
description = "Create APFS snapshot before testing"
run = "sudo tmutil localsnapshot && echo 'Snapshot created'"

[tasks."snapshot:list"]
description = "List local APFS snapshots"
run = "tmutil listlocalsnapshots /"

[tasks."snapshot:delete"]
description = "Delete oldest snapshot"
run = '''
SNAP=$(tmutil listlocalsnapshots / | head -2 | tail -1 | cut -d'.' -f4-)
sudo tmutil deletelocalsnapshots $SNAP
'''
```

### Option E: nix-darwin (Future Consideration)

Best for: Teams willing to invest in declarative configuration.

**Pros:**
- Atomic rollback of entire system state
- Reproducible across machines
- Integrates with home-manager for dotfiles
- Can coexist with Homebrew (for GUI apps)

**Cons:**
- Steep learning curve ("vertical cliff")
- Paradigm shift from imperative to declarative
- May conflict with mise's tool management philosophy

**Example configuration:**

```nix
# darwin-configuration.nix
{ config, pkgs, ... }:
{
  # Use nix-darwin for system packages
  environment.systemPackages = with pkgs; [
    mise
    starship
    direnv
  ];

  # Homebrew for GUI apps only
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "visual-studio-code"
      "warp"
    ];
  };

  # Shell configuration
  programs.zsh.enable = true;
}
```

---

## Recommendations by Use Case

| Scenario | Recommended Approach |
|----------|---------------------|
| CI/CD testing | GitHub Actions (Option C) |
| Local full testing | Tart (Option A) |
| Quick manual testing | APFS Snapshots (Option D) |
| API-driven automation | Lume (Option B) |
| Team standardization | nix-darwin (Option E) - future |

---

## Implementation Priority

### Phase 1: GitHub Actions (Low Effort, High Value)

Add `.github/workflows/macos-test.yml` for automated PR testing.

**Effort:** 1-2 hours
**Value:** Every PR validated on real macOS

### Phase 2: APFS Snapshot Tasks (Low Effort, Medium Value)

Add mise tasks for snapshot management.

**Effort:** 30 minutes
**Value:** Quick rollback for local testing

### Phase 3: Tart Integration (Medium Effort, High Value)

Add mise tasks for VM management with pre-built images.

**Effort:** 2-4 hours
**Value:** Full macOS testing without risking main system

### Phase 4: nix-darwin Exploration (High Effort, Future)

Research whether nix-darwin complements or conflicts with mise philosophy.

**Effort:** 1-2 weeks to evaluate
**Value:** Potentially superior reproducibility

---

## Sources and References

### Hacker News Discussions

1. **Tart Discussion** (261 points, 135 comments)
   - URL: https://news.ycombinator.com/item?id=39059100
   - Key insight: OCI registry support enables sharing VM images

2. **Lume Announcement** (309 points, 75 comments, Feb 2025)
   - URL: https://news.ycombinator.com/item?id=42908061
   - Key insight: MIT license, API server for automation

3. **nix-darwin "Going Immutable"** (140 points, 79 comments, Jan 2026)
   - URL: https://news.ycombinator.com/item?id=46462719
   - Key insight: Can coexist with Homebrew for GUI apps

4. **Dev Environment Sandboxing on macOS** (general discussion)
   - URL: https://news.ycombinator.com/item?id=29211773
   - Key insight: Separate user accounts for basic isolation

### Blog Posts and Documentation

1. **Going Immutable on macOS with nix-darwin**
   - URL: https://carette.xyz/posts/going_immutable_macos/
   - Detailed setup guide with Homebrew integration

2. **Nix on macOS Tutorial**
   - URL: https://nixcademy.com/2024/01/15/nix-on-macos/
   - Beginner-friendly nix-darwin introduction

3. **Tart Official Documentation**
   - URL: https://tart.run/
   - VM management and CI integration guides

4. **Lume Documentation**
   - URL: https://github.com/trycua/lume
   - Python SDK and API server documentation

---

## Decision Matrix

When choosing an approach, consider:

| Factor | Weight | Tart | Lume | GitHub Actions | APFS | nix-darwin |
|--------|--------|------|------|----------------|------|------------|
| Setup effort | High | 3/5 | 3/5 | 5/5 | 5/5 | 1/5 |
| Automation | High | 4/5 | 5/5 | 5/5 | 2/5 | 4/5 |
| License | Medium | 3/5 | 5/5 | N/A | N/A | 5/5 |
| Learning curve | Medium | 4/5 | 4/5 | 5/5 | 5/5 | 1/5 |
| Full fidelity | High | 5/5 | 5/5 | 4/5 | 5/5 | 4/5 |

**Scores:** Tart (19), Lume (22), GitHub Actions (19), APFS (17), nix-darwin (15)

**Recommendation:** Start with **GitHub Actions** for CI, add **APFS snapshot tasks** for local safety, then evaluate **Lume** for advanced automation needs.
