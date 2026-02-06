# macOS Testing and Sandbox Environments

**Last Updated:** 2026-02-03

This document outlines strategies for testing macOS-specific configurations when primary development happens in Linux DevContainers. Based on deep research across Hacker News, GitHub, official documentation, and real-world usage patterns.

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

## Tool Comparison (Updated 2026)

| Tool | Stars | License | Use Case | Maturity |
|------|-------|---------|----------|----------|
| **Tart** | 4.9k | Fair Source | macOS VMs, CI/CD | Production (v2.30.5) |
| **Lume/CUA** | 12.3k | MIT | macOS VMs, AI Agents | Production (v0.7.24) |
| **nix-darwin** | 5k | MIT | Declarative macOS | Mature (2,312 commits) |
| **GitHub Actions** | N/A | N/A | CI testing | Stable (macos-14) |
| **APFS Snapshots** | N/A | Built-in | Quick rollback | Native |

### Enterprise Adoption

**Tart** is used by:
- Atlassian, Figma, Mullvad, Expo, Snowflake, Codemagic, Krisp, TestingBot, Transloadit
- 25,000+ installations worldwide
- Orchard orchestration for cluster management

**Lume/CUA** is used by:
- **Anthropic** (Claude Cowork uses Apple's Virtualization.Framework)
- AI agent developers for computer-use benchmarks
- Research teams for RL environments

**nix-darwin** is used by:
- 276+ contributors
- Teams seeking reproducible macOS configurations
- Supported by Lix installer (recommended)

---

## Recommended Approaches

### Option A: Tart (Local macOS VMs)

**Best for:** Full macOS environment testing with CI integration.

**Why Tart:**
- Uses Apple's native Virtualization.Framework (near-native performance)
- OCI-compatible registry support (share VMs like Docker images)
- Pre-built images: `ghcr.io/cirruslabs/macos-sequoia-base:latest`
- Integrates with: GitHub Actions (Cirrus Runners), GitLab Runner, Buildkite

```bash
# Install Tart
brew install cirruslabs/cli/tart

# Pull pre-built macOS image (25GB)
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest sequoia-test

# Run VM with display
tart run sequoia-test

# Run headlessly (for CI)
tart run sequoia-test --no-display

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

[tasks."vm:run-headless"]
description = "Run macOS VM headlessly"
run = "tart run godtier-test --no-display"

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

[tasks."vm:list"]
description = "List all Tart VMs"
run = "tart list"
```

### Option B: Lume/CUA (API-Driven Automation)

**Best for:** AI agent development, Python scripting, programmatic VM control.

**Why Lume:**
- MIT License (fully open source)
- Part of CUA platform (12.3k stars)
- Python SDK for programmatic control
- HTTP API via `lume serve`
- Used by Anthropic for Claude Cowork sandboxing
- Automated golden images (no manual Setup Assistant)

```bash
# Install Lume
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"

# Create and run macOS VM
lume create test-vm --os macos --ipsw latest
lume run test-vm

# Run headlessly
lume run test-vm --no-display

# Start HTTP API server
lume serve &

# Pull from registry
lume run macos-sequoia-vanilla:latest
```

**Python SDK Example:**

```python
from computer import Computer
from agent import ComputerAgent

# Create macOS sandbox
computer = Computer(os_type="macos", provider_type="lume")
agent = ComputerAgent(model="anthropic/claude-sonnet-4-5", computer=computer)

# Run automation
async for result in agent.run([{"role": "user", "content": "Run ./setup.sh and verify installation"}]):
    print(result)
```

**Mise tasks for Lume:**

```toml
[tasks."lume:create"]
description = "Create macOS VM with Lume"
run = "lume create godtier-vm --os macos --ipsw latest"

[tasks."lume:run"]
description = "Run Lume VM"
run = "lume run godtier-vm"

[tasks."lume:serve"]
description = "Start Lume HTTP API server"
run = "lume serve"

[tasks."lume:list"]
description = "List Lume VMs"
run = "lume list"
```

### Option C: GitHub Actions (CI Testing)

**Best for:** Automated PR validation without local setup.

**Why GitHub Actions:**
- `macos-14` = macOS Sonoma on Apple Silicon (M1)
- `macos-14-xlarge` = larger runners for heavy builds
- Used by: PyTorch, scikit-learn, Ruby, Firebase, Alamofire, OpenVINO
- Free tier available (limited minutes)

**Real-world patterns from major projects:**

```yaml
# .github/workflows/macos-test.yml
name: macOS Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test-macos:
    runs-on: macos-14  # Apple Silicon (M1)
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4

      - name: Run setup script
        run: ./setup.sh

      - name: Activate mise
        run: eval "$(mise activate bash --shims)"

      - name: Run tests
        run: bats tests/

      - name: Validate environment
        run: mise run validate

      - name: Check mise doctor
        run: mise doctor

  # Optional: Matrix testing across macOS versions
  test-macos-matrix:
    strategy:
      fail-fast: false
      matrix:
        os: [macos-13, macos-14]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - name: Run setup
        run: ./setup.sh
      - name: Test
        run: |
          eval "$(mise activate bash --shims)"
          bats tests/
```

### Option D: APFS Snapshots (Quick Rollback)

**Best for:** Manual testing with instant rollback capability.

```bash
# Create snapshot before testing
sudo tmutil localsnapshot

# List snapshots
tmutil listlocalsnapshots /

# Run your tests
./setup.sh
bats tests/

# If something breaks, you can restore from Time Machine
# Or mount snapshot read-only to compare:
SNAP=$(tmutil listlocalsnapshots / | tail -1 | sed 's/com.apple.TimeMachine.//')
mkdir -p /tmp/snap
sudo mount_apfs -s "com.apple.TimeMachine.$SNAP" / /tmp/snap

# Delete snapshot after successful testing
sudo tmutil deletelocalsnapshots <date>
```

**Mise tasks for snapshots:**

```toml
[tasks."snapshot:create"]
description = "Create APFS snapshot before testing"
run = "sudo tmutil localsnapshot && echo 'Snapshot created'"

[tasks."snapshot:list"]
description = "List local APFS snapshots"
run = "tmutil listlocalsnapshots /"

[tasks."snapshot:delete-oldest"]
description = "Delete oldest snapshot"
run = '''
SNAP=$(tmutil listlocalsnapshots / | grep -v '^$' | head -1 | sed 's/com.apple.TimeMachine.//')
[ -n "$SNAP" ] && sudo tmutil deletelocalsnapshots "$SNAP" || echo "No snapshots found"
'''
```

### Option E: nix-darwin (Declarative Configuration)

**Best for:** Teams willing to invest in fully reproducible macOS configurations.

**Why nix-darwin:**
- 5k stars, 593 forks, 276 contributors
- Atomic rollback of entire system state
- Reproducible across machines
- Can coexist with Homebrew (for GUI apps)
- Flakes recommended for beginners
- Supported by both Nix and Lix

**Pros:**
- `darwin-rebuild switch` applies changes atomically
- Rollback with `darwin-rebuild switch --rollback`
- Version-controlled system configuration
- Integrates with home-manager for dotfiles

**Cons:**
- Steep learning curve ("vertical cliff" according to HN)
- Different paradigm from mise (declarative vs tool-based)
- May have conflicts with mise's shim management

**Example configuration:**

```nix
# flake.nix
{
  description = "God-Tier macOS Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }: {
    darwinConfigurations."MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ ./darwin-configuration.nix ];
    };
  };
}

# darwin-configuration.nix
{ config, pkgs, ... }:
{
  # Let mise manage development tools
  # nix-darwin manages system-level config
  
  environment.systemPackages = with pkgs; [
    mise        # Tool orchestrator
    starship    # Prompt
  ];

  # Homebrew for GUI apps only
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    casks = [
      "1password"
      "visual-studio-code"
      "warp"
      "orbstack"
    ];
  };

  # Shell configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  # System defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleKeyboardUIMode = 3;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
```

**Mise + nix-darwin coexistence strategy:**
- Use nix-darwin for: System packages, GUI apps, macOS defaults
- Use mise for: Development tools, runtimes, project-specific versions
- Avoid overlap in tool management

---

## Recommendations by Use Case

| Scenario | Primary | Secondary |
|----------|---------|-----------|
| **CI/CD testing** | GitHub Actions (`macos-14`) | Tart + Cirrus Runners |
| **Local full testing** | Tart (OCI images) | Lume (if MIT license required) |
| **Quick manual testing** | APFS Snapshots | Separate user account |
| **AI agent development** | Lume/CUA | Tart |
| **Team standardization** | GitHub Actions | nix-darwin (future) |
| **Reproducible machines** | nix-darwin | None (paradigm shift) |

---

## Implementation Priority

### Phase 1: GitHub Actions (Immediate - Low Effort, High Value)

Add `.github/workflows/macos-test.yml` for automated PR testing.

**Effort:** 1-2 hours
**Value:** Every PR validated on real macOS M1

**Action:** Create workflow file (example above)

### Phase 2: APFS Snapshot Tasks (This Week - Low Effort, Medium Value)

Add mise tasks for snapshot management.

**Effort:** 30 minutes
**Value:** Quick rollback for local testing

**Action:** Add tasks to `config/mise.toml`

### Phase 3: Tart/Lume Integration (Next Sprint - Medium Effort, High Value)

Add mise tasks for VM management with pre-built images.

**Effort:** 2-4 hours
**Value:** Full macOS testing without risking main system

**Decision needed:** Tart (Fair Source, mature) vs Lume (MIT, newer)
- If enterprise licensing is a concern: **Lume**
- If CI integration is priority: **Tart** (Cirrus Runners)
- If AI agent development: **Lume** (CUA integration)

### Phase 4: nix-darwin Exploration (Future - High Effort)

Research whether nix-darwin complements or conflicts with mise philosophy.

**Effort:** 1-2 weeks to evaluate
**Value:** Potentially superior reproducibility

**Key questions to answer:**
1. Can mise shims coexist with nix-darwin PATH management?
2. Does nix-darwin duplicate mise's functionality?
3. Is the learning curve worth it for our team?

---

## Sources and References

### Primary Sources (Direct Documentation)

| Source | URL | Key Data |
|--------|-----|----------|
| **Tart Official** | https://tart.run/ | v2.30.5, 25k+ installs, Orchard orchestration |
| **Tart GitHub** | https://github.com/cirruslabs/tart | 4.9k stars, 148 forks, 582 commits |
| **Lume/CUA Docs** | https://cua.ai/docs/lume | MIT license, Apple Virtualization.Framework |
| **CUA GitHub** | https://github.com/trycua/cua | 12.3k stars, 732 forks, 2792 commits |
| **nix-darwin** | https://github.com/nix-darwin/nix-darwin | 5k stars, 593 forks, 2312 commits |
| **nix-darwin Docs** | https://nix-darwin.github.io/nix-darwin/manual/ | Official manual |

### Hacker News Discussions

| Topic | URL | Points | Key Insight |
|-------|-----|--------|-------------|
| Tart | https://news.ycombinator.com/item?id=39059100 | 261 | OCI registry support, enterprise adoption |
| Lume/CUA | https://news.ycombinator.com/item?id=42908061 | 309 | MIT license, API server, AI agent focus |
| nix-darwin | https://news.ycombinator.com/item?id=46462719 | 140 | "Going immutable", Homebrew coexistence |
| macOS Sandboxing | https://news.ycombinator.com/item?id=29211773 | - | Separate user accounts for isolation |

### Blog Posts and Tutorials

| Title | URL | Author/Source |
|-------|-----|---------------|
| Going Immutable on macOS | https://carette.xyz/posts/going_immutable_macos/ | carette.xyz |
| Nix on macOS Tutorial | https://nixcademy.com/2024/01/15/nix-on-macos/ | Nixcademy |

### Real-World Usage (GitHub Actions Patterns)

Analyzed macOS CI patterns from major open-source projects:

| Project | Runner | Use Case |
|---------|--------|----------|
| PyTorch | `macos-14-xlarge` | Wheel builds for Apple Silicon |
| scikit-learn | `macos-14` | Python wheel builds |
| Ruby | `macos-14` | Language runtime testing |
| Firebase iOS SDK | `macos-14` | iOS SDK testing |
| Alamofire | `macos-14` | Swift library testing |
| OpenVINO | `macos-14-xlarge` | ML framework builds |
| IGListKit | `macos-14` | iOS framework testing |

---

## Decision Matrix

| Factor | Weight | Tart | Lume | GitHub Actions | APFS | nix-darwin |
|--------|--------|------|------|----------------|------|------------|
| Setup effort | High | 3/5 | 3/5 | 5/5 | 5/5 | 1/5 |
| Automation | High | 4/5 | 5/5 | 5/5 | 2/5 | 4/5 |
| License | Medium | 3/5 | 5/5 | N/A | N/A | 5/5 |
| Learning curve | Medium | 4/5 | 4/5 | 5/5 | 5/5 | 1/5 |
| Full fidelity | High | 5/5 | 5/5 | 4/5 | 5/5 | 4/5 |
| Enterprise adoption | Medium | 5/5 | 4/5 | 5/5 | N/A | 3/5 |
| AI/Agent support | Low | 3/5 | 5/5 | 2/5 | 1/5 | 2/5 |

**Weighted Scores:** 
- Lume: 26/35 (Best for flexibility)
- GitHub Actions: 24/35 (Best for CI)
- Tart: 23/35 (Best for enterprise)
- APFS: 18/35 (Best for quick local)
- nix-darwin: 16/35 (Best for reproducibility, high learning curve)

---

## Final Recommendation

**Immediate (This Week):**
1. Add GitHub Actions workflow with `macos-14` runner
2. Add APFS snapshot mise tasks for local safety net

**Short-term (This Month):**
3. Evaluate Tart vs Lume for local VM testing
4. Create mise tasks for chosen VM tool

**Long-term (Future):**
5. Monitor nix-darwin for potential synergy with mise
6. Consider Lume/CUA for AI agent testing use cases
