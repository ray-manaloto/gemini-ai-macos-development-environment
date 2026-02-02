# God-Tier macOS Development Environment - DevContainer
# Fully isolated, reproducible development environment
# Build: docker build -t god-tier-dev .devcontainer/

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG MISE_VERSION=latest
ARG USERNAME=vscode

ENV MISE_TRUSTED_CONFIG_PATHS=/workspaces
ENV MISE_INSTALL_PATH=/home/${USERNAME}/.local/bin/mise
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
    && rm -rf /var/lib/apt/lists/*

RUN chsh -s /bin/zsh ${USERNAME}

USER ${USERNAME}

RUN curl https://mise.run | sh

COPY --chown=${USERNAME}:${USERNAME} config/mise.toml /home/${USERNAME}/.config/mise/config.toml

RUN mise trust /home/${USERNAME}/.config/mise/config.toml \
    && mise install --yes

RUN mise exec -- bun --version \
    && mise exec -- node --version \
    && mise exec -- uv --version

WORKDIR /workspaces

CMD ["/bin/zsh"]
