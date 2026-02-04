# God-Tier macOS Development Environment - DevContainer
# Alternative Dockerfile for custom builds (standalone Docker without devcontainer.json features)
# Primary usage: devcontainer.json with mise feature
# Build standalone: docker build -t god-tier-dev .devcontainer/

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG USERNAME=vscode
ARG TARGETARCH=arm64

ENV MISE_TRUSTED_CONFIG_PATHS=/workspaces
ENV MISE_YES=1
ENV PATH="/home/${USERNAME}/.local/share/mise/shims:/home/${USERNAME}/.local/bin:${PATH}"

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    zsh \
    jq \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN chsh -s /bin/zsh ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN mkdir -p /home/${USERNAME}/.local/bin \
    && MISE_VERSION=$(curl -sL https://api.github.com/repos/jdx/mise/releases/latest | grep '"tag_name"' | cut -d'"' -f4) \
    && curl -fsSL "https://github.com/jdx/mise/releases/download/${MISE_VERSION}/mise-${MISE_VERSION}-linux-${TARGETARCH}" -o /home/${USERNAME}/.local/bin/mise \
    && chmod +x /home/${USERNAME}/.local/bin/mise \
    && echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc

COPY --chown=${USERNAME}:${USERNAME} config/mise.toml /home/${USERNAME}/.config/mise/config.toml

# Install core runtimes first (needed for npm/pipx packages)
RUN ~/.local/bin/mise trust /home/${USERNAME}/.config/mise/config.toml \
    && ~/.local/bin/mise install bun node uv pixi python --yes || true

# Install AI/LLM CLI tools and essential utilities
RUN ~/.local/bin/mise install \
    "npm:@anthropic-ai/claude-code" \
    "npm:@google/gemini-cli" \
    "npm:@ralph-orchestrator/ralph-cli" \
    "npm:bats" \
    ripgrep fd fzf jq yq starship bat eza zoxide glow \
    shellcheck hadolint \
    atuin "aqua:FiloSottile/age" \
    --yes || true

# Verify installations
RUN ~/.local/bin/mise --version \
    && echo "=== Core Runtimes ===" \
    && (command -v bun && bun --version) || echo "bun: will install on first use" \
    && (command -v node && node --version) || echo "node: will install on first use" \
    && (command -v python && python --version) || echo "python: will install on first use" \
    && (command -v uv && uv --version) || echo "uv: will install on first use" \
    && echo "=== AI/LLM Tools ===" \
    && (command -v claude && claude --version) || echo "claude: will install on first use" \
    && (command -v gemini && gemini --version 2>/dev/null) || echo "gemini: will install on first use" \
    && echo "=== Shell Enhancements ===" \
    && (command -v atuin && atuin --version) || echo "atuin: will install on first use" \
    && (command -v age && age --version) || echo "age: will install on first use"

WORKDIR /workspaces

CMD ["/bin/zsh"]
