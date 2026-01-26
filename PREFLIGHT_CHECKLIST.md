# macOS Development Environment - Pre-Flight Checklist

Before running `setup.sh`, ensure all prerequisites are met and decisions are made.

---

## 🖥️ System Requirements

### Minimum Requirements
- [ ] **macOS Version**: 13.0 (Ventura) or newer
  - Required for OrbStack virtualization
  - Check: `sw_vers -productVersion`
- [ ] **Apple Silicon or Intel**: Both supported
  - Check: `uname -m` (arm64 = Apple Silicon)
- [ ] **Disk Space**: At least 20GB free
  - Check: `df -h /`
- [ ] **RAM**: 8GB minimum, 16GB recommended

### Xcode Command Line Tools
- [ ] **Install Xcode CLT** (required for git, compilers, etc.)
  ```bash
  xcode-select --install
  ```
- [ ] **Verify Installation**:
  ```bash
  xcode-select -p
  # Should output: /Library/Developer/CommandLineTools
  ```

---

## 🔐 Accounts & Authentication

### Required Accounts
- [ ] **GitHub Account** - For cloning repos and pushing dotfiles
- [ ] **AWS Account** - If using SkyPilot for cloud agents
- [ ] **1Password Account** OR **Infisical Account** - For secrets management

### Authentication Setup
- [ ] **SSH Key for GitHub**
  ```bash
  # Check for existing key
  ls -la ~/.ssh/id_ed25519.pub

  # Generate if missing
  ssh-keygen -t ed25519 -C "your_email@example.com"

  # Add to GitHub: https://github.com/settings/keys
  ```

- [ ] **AWS Credentials** (if using SkyPilot)
  ```bash
  # Create credentials file
  mkdir -p ~/.aws
  cat > ~/.aws/credentials << 'EOF'
  [default]
  aws_access_key_id = YOUR_ACCESS_KEY
  aws_secret_access_key = YOUR_SECRET_KEY
  EOF
  ```

---

## 📦 Pre-Installation Decisions

### Secrets Management Choice
- [ ] **Choose ONE**:
  - [ ] **1Password** - Better for teams with non-technical users
  - [ ] **Infisical** - Better for CI/CD and machine-to-machine secrets

### Editor Choice
- [ ] **Zed** (default in config) - Fast, modern, Rust-based
- [ ] **VS Code** - More extensions, wider adoption
- [ ] **Other** - Update `config/main.pkl` accordingly

### Shell Configuration
- [ ] **Starship Prompt** - Modern, fast prompt (recommended)
- [ ] **Existing prompt** - Keep current setup

---

## 🔧 Optional Pre-Installation

### Install Homebrew (Optional)
While mise replaces most Homebrew needs, some GUI apps still require it:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install SwiftBar (for menu bar status)
- [ ] Download from: https://swiftbar.app
- [ ] Or install via Homebrew: `brew install --cask swiftbar`

### Install OrbStack (for Docker)
- [ ] Download from: https://orbstack.dev
- [ ] Or install via Homebrew: `brew install --cask orbstack`

### Install Nerd Font (for Starship/terminal icons)
```bash
brew tap homebrew/cask-fonts
brew install --cask font-fira-code-nerd-font
```

---

## 📋 Configuration Decisions

### Review and Customize `config/main.pkl`

Before running setup, review these settings:

```pkl
// Tools to install - modify versions as needed
["bun"] = "latest"      // or specific version like "1.0.0"
["pixi"] = "latest"
["uv"] = "latest"

// Infrastructure - comment out if not needed
["brew:orbstack"] = "latest"   // Remove if not using Docker
["brew:infisical"] = "latest"  // Remove if using 1Password instead
["pipx:skypilot"] = "latest"   // Remove if not using AWS agents

// AI Tools
["npm:@anthropic-ai/claude-code"] = "latest"
["npm:opencode-ai"] = "latest"
```

### Environment Variables
Update `env` section in `config/main.pkl`:
```pkl
env = new {
  ["EDITOR"] = "zed --wait"        // Or "code --wait" for VS Code
  ["AWS_PROFILE"] = "default"      // Your AWS profile name
}
```

---

## 🚀 Ready to Install?

### Final Checklist
- [ ] macOS 13+ installed
- [ ] Xcode Command Line Tools installed
- [ ] SSH key configured for GitHub
- [ ] Reviewed `config/main.pkl` settings
- [ ] Decided on secrets manager (1Password vs Infisical)
- [ ] (Optional) SwiftBar installed for menu bar
- [ ] (Optional) OrbStack installed for Docker
- [ ] (Optional) Nerd Font installed for terminal icons

### Run Setup
```bash
cd /path/to/gemini-ai-macos-development-environment
chmod +x setup.sh
./setup.sh
```

### Post-Installation Verification
```bash
# Run validation script
mise run validate

# Launch dashboard
mise run dashboard

# Check all tools
mise doctor
```

---

## 🔄 Dotfiles Synchronization (Optional)

If you want to sync your dotfiles across machines using chezmoi:

```bash
# Initialize chezmoi
mise install chezmoi
chezmoi init

# Add your dotfiles
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Push to GitHub
chezmoi cd
git remote add origin git@github.com:YOUR_USERNAME/dotfiles.git
git push -u origin main
```

---

## 🆘 Troubleshooting

### Common Issues

**"mise: command not found"**
```bash
export PATH="$HOME/.local/bin:$PATH"
source ~/.zshrc
```

**"OrbStack not running"**
```bash
open -a OrbStack
```

**"AWS credentials not found"**
```bash
# Verify credentials file exists
cat ~/.aws/credentials
```

**"Pkl compilation failed"**
```bash
# Check Pkl is installed
pkl --version

# Try manual compilation
pkl eval -f toml config/main.pkl
```

---

## 📚 Additional Resources

- [Mise Documentation](https://mise.jdx.dev/)
- [Pixi Documentation](https://pixi.sh/)
- [OrbStack Documentation](https://docs.orbstack.dev/)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [SkyPilot Documentation](https://docs.skypilot.co/)

---

*Last updated: January 2026*
