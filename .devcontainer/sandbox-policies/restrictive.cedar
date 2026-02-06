// Cedar Policy: Restrictive Mode
// For untrusted code review, security-sensitive environments, or demos
//
// This policy follows the principle of least privilege.
// Actions are denied by default; only explicitly permitted actions succeed.

// =============================================================================
// PERMIT Rules - Minimal permissions
// =============================================================================

// Read-only access to workspace
permit (
    principal,
    action == Action::"read",
    resource
)
when { resource.path.startsWith("/workspaces/") };

// Write only to specific directories
permit (
    principal,
    action == Action::"write",
    resource
)
when {
    resource.path.startsWith("/workspaces/") &&
    (
        resource.path.contains("/src/") ||
        resource.path.contains("/lib/") ||
        resource.path.contains("/tests/") ||
        resource.path.contains("/docs/")
    )
};

// Only allow safe read-only commands
permit (
    principal,
    action == Action::"execute",
    resource
)
when {
    resource.name in [
        "cat", "bat", "less", "more", "head", "tail",
        "ls", "eza", "tree",
        "grep", "rg", "fd", "find",
        "git status", "git log", "git diff", "git show",
        "mise ls", "mise doctor",
        "jq", "yq"
    ]
};

// Only allow network access to documentation sites
permit (
    principal,
    action == Action::"network",
    resource
)
when {
    resource.host in [
        "github.com",
        "docs.github.com",
        "mise.jdx.dev",
        "bun.sh",
        "docs.astral.sh"
    ]
};

// =============================================================================
// FORBID Rules - Deny everything else explicitly
// =============================================================================

// No writes outside permitted directories
forbid (
    principal,
    action == Action::"write",
    resource
)
when {
    !resource.path.startsWith("/workspaces/")
};

// No package installation
forbid (
    principal,
    action == Action::"execute",
    resource
)
when {
    resource.name in [
        "npm", "npm install", "bun install", "bun add",
        "pip", "pip install", "uv pip install",
        "mise install", "mise use"
    ]
};

// No git push/commit
forbid (
    principal,
    action == Action::"execute",
    resource
)
when {
    resource.name in [
        "git push", "git commit", "git rebase",
        "gh pr create", "gh pr merge"
    ]
};

// No network access to package registries (install from cache only)
forbid (
    principal,
    action == Action::"network",
    resource
)
when {
    resource.host in [
        "registry.npmjs.org",
        "pypi.org",
        "api.anthropic.com",
        "api.openai.com"
    ]
};

// No execution of unknown binaries
forbid (
    principal,
    action == Action::"execute",
    resource
)
when { !resource.trusted };
