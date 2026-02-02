// Cedar Policy for AI Agent Governance
// Used with strongdm/leash for sandboxed AI coding agents
//
// Documentation: https://github.com/strongdm/leash
// Cedar Language: https://www.cedarpolicy.com/

// =============================================================================
// PERMIT Rules - Explicitly allowed actions
// =============================================================================

// Allow reading any file in the workspace
permit (
    principal,
    action == Action::"read",
    resource
)
when { resource.path.startsWith("/workspaces/") };

// Allow writing to workspace files (not system files)
permit (
    principal,
    action == Action::"write",
    resource
)
when { resource.path.startsWith("/workspaces/") };

// Allow executing common development tools
permit (
    principal,
    action == Action::"execute",
    resource
)
when {
    resource.name in [
        "mise", "bun", "node", "npm", "npx",
        "python", "python3", "pip", "uv", "pixi",
        "git", "gh",
        "bats", "shellcheck",
        "bat", "cat", "ls", "grep", "rg", "fd", "find",
        "jq", "yq", "sed", "awk",
        "curl", "wget",
        "docker", "docker-compose"
    ]
};

// Allow network access to approved domains
permit (
    principal,
    action == Action::"network",
    resource
)
when {
    resource.host in [
        "github.com",
        "api.github.com",
        "raw.githubusercontent.com",
        "registry.npmjs.org",
        "pypi.org",
        "files.pythonhosted.org",
        "conda.anaconda.org",
        "api.anthropic.com",
        "api.openai.com",
        "generativelanguage.googleapis.com"
    ]
};

// =============================================================================
// FORBID Rules - Explicitly denied actions (higher priority than permit)
// =============================================================================

// Never allow writing to system directories
forbid (
    principal,
    action == Action::"write",
    resource
)
when {
    resource.path.startsWith("/etc/") ||
    resource.path.startsWith("/usr/") ||
    resource.path.startsWith("/bin/") ||
    resource.path.startsWith("/sbin/")
};

// Never allow executing dangerous system commands
forbid (
    principal,
    action == Action::"execute",
    resource
)
when {
    resource.name in [
        "sudo", "su", "chown", "chmod",
        "rm", "rmdir",  // Use trash instead
        "mkfs", "fdisk", "dd",
        "reboot", "shutdown", "halt"
    ]
};

// Never allow network access to sensitive internal ranges
forbid (
    principal,
    action == Action::"network",
    resource
)
when {
    resource.host.startsWith("169.254.") ||  // Link-local
    resource.host.startsWith("10.") ||       // Private Class A
    resource.host.startsWith("172.16.") ||   // Private Class B
    resource.host.startsWith("192.168.") ||  // Private Class C
    resource.host == "localhost" ||
    resource.host == "127.0.0.1"
};

// Never allow reading sensitive files
forbid (
    principal,
    action == Action::"read",
    resource
)
when {
    resource.path.contains("/.ssh/") ||
    resource.path.contains("/.aws/credentials") ||
    resource.path.contains("/.gnupg/") ||
    resource.path.endsWith(".env") ||
    resource.path.endsWith(".env.local") ||
    resource.path.contains("/secrets/")
};
