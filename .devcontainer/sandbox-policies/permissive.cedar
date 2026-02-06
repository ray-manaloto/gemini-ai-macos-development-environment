// Cedar Policy: Permissive Mode
// For trusted development environments where convenience is prioritized
//
// WARNING: This policy is more permissive than default.cedar
// Use only in trusted, isolated environments.

// =============================================================================
// PERMIT Rules - Broad permissions for development
// =============================================================================

// Allow all file operations in workspace
permit (
    principal,
    action in [Action::"read", Action::"write", Action::"delete"],
    resource
)
when { resource.path.startsWith("/workspaces/") };

// Allow all file operations in home directory
permit (
    principal,
    action in [Action::"read", Action::"write"],
    resource
)
when { resource.path.startsWith("/home/") };

// Allow executing any command (except explicitly forbidden)
permit (
    principal,
    action == Action::"execute",
    resource
);

// Allow network access to most hosts (except internal)
permit (
    principal,
    action == Action::"network",
    resource
);

// =============================================================================
// FORBID Rules - Still protect critical resources
// =============================================================================

// Never allow sudo/su
forbid (
    principal,
    action == Action::"execute",
    resource
)
when { resource.name in ["sudo", "su"] };

// Never allow modifying system directories
forbid (
    principal,
    action == Action::"write",
    resource
)
when {
    resource.path.startsWith("/etc/") ||
    resource.path.startsWith("/usr/") ||
    resource.path.startsWith("/bin/")
};

// Never allow internal network access
forbid (
    principal,
    action == Action::"network",
    resource
)
when {
    resource.host.startsWith("169.254.") ||
    resource.host.startsWith("10.") ||
    resource.host.startsWith("172.") ||
    resource.host.startsWith("192.168.")
};

// Never allow reading SSH keys
forbid (
    principal,
    action == Action::"read",
    resource
)
when { resource.path.contains("/.ssh/") && resource.path.endsWith("_rsa") };
