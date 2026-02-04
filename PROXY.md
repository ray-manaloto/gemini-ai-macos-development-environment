# Proxy Configuration Guide

Configure HTTP/HTTPS proxy settings for corporate network environments.

## Quick Start

```bash
# Check current proxy status
mise run proxy:status

# Interactive setup
mise run proxy:setup

# Test connectivity
mise run proxy:test

# Clear all proxy settings
mise run proxy:clear
```

## Environment Variables

### Standard Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `HTTP_PROXY` | HTTP proxy URL | `http://proxy.company.com:8080` |
| `HTTPS_PROXY` | HTTPS proxy URL | `http://proxy.company.com:8080` |
| `NO_PROXY` | Hosts to bypass | `localhost,127.0.0.1,.local,.internal` |

### Lowercase Variants

Some tools require lowercase versions:

```bash
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export no_proxy="$NO_PROXY"
```

### Authenticated Proxy

For proxies requiring authentication:

```bash
export HTTP_PROXY="http://username:password@proxy.company.com:8080"
export HTTPS_PROXY="http://username:password@proxy.company.com:8080"
```

**Security Note**: Avoid storing credentials in plain text. Consider using:
- Environment variables from a secrets manager
- 1Password CLI: `op://Private/Proxy/password`
- Mise secrets: `mise secrets set PROXY_PASSWORD=...`

## Configuration Methods

### Method 1: Shell Profile (Persistent)

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Corporate Proxy Configuration
export HTTP_PROXY="http://proxy.company.com:8080"
export HTTPS_PROXY="http://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1,.local,.internal,*.company.com"

# Lowercase variants for compatibility
export http_proxy="$HTTP_PROXY"
export https_proxy="$HTTPS_PROXY"
export no_proxy="$NO_PROXY"
```

### Method 2: Mise Configuration

Add to `~/.config/mise/config.toml` or project `mise.toml`:

```toml
[env]
HTTP_PROXY = "http://proxy.company.com:8080"
HTTPS_PROXY = "http://proxy.company.com:8080"
NO_PROXY = "localhost,127.0.0.1,.local"
```

### Method 3: .env File

Create `.env` in your project:

```bash
HTTP_PROXY=http://proxy.company.com:8080
HTTPS_PROXY=http://proxy.company.com:8080
NO_PROXY=localhost,127.0.0.1,.local
```

Then source it: `source .env`

## Tool-Specific Configuration

### Git

```bash
# Set proxy
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy http://proxy.company.com:8080

# Clear proxy
git config --global --unset http.proxy
git config --global --unset https.proxy

# Proxy for specific domain only
git config --global http.https://github.com.proxy http://proxy.company.com:8080
```

### npm / Bun

```bash
# npm
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# Clear
npm config delete proxy
npm config delete https-proxy
```

Bun respects `HTTP_PROXY` and `HTTPS_PROXY` environment variables automatically.

### pip / uv

```bash
# pip
pip config set global.proxy http://proxy.company.com:8080

# uv respects environment variables
export HTTP_PROXY=http://proxy.company.com:8080
uv pip install package
```

### curl

```bash
# Via environment (automatic)
curl https://api.github.com

# Explicit proxy
curl --proxy http://proxy.company.com:8080 https://api.github.com

# Bypass proxy
curl --noproxy localhost https://localhost:8080
```

### Docker

Add to `~/.docker/config.json`:

```json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.company.com:8080",
      "httpsProxy": "http://proxy.company.com:8080",
      "noProxy": "localhost,127.0.0.1,.local"
    }
  }
}
```

### AWS CLI

AWS CLI respects `HTTP_PROXY` and `HTTPS_PROXY` environment variables.

For S3 specifically:

```bash
aws configure set default.s3.proxy http://proxy.company.com:8080
```

## Common Proxy Patterns

### Corporate with PAC File

If your company uses a PAC file:

1. Find the actual proxy URL from IT or the PAC file
2. PAC files are JavaScript - look for `PROXY` return statements
3. Use the direct proxy URL, not the PAC URL

### NTLM Authentication

For Windows domain authentication, use tools like:
- **cntlm** - Local proxy that handles NTLM
- **px** - Python-based NTLM proxy

```bash
# Install cntlm
brew install cntlm

# Configure /usr/local/etc/cntlm.conf
# Then point tools to localhost:3128
export HTTP_PROXY=http://localhost:3128
```

### SSL Interception

If your proxy does SSL inspection:

1. Get the corporate CA certificate
2. Add to system trust store or tool-specific config

```bash
# Node.js
export NODE_EXTRA_CA_CERTS=/path/to/corporate-ca.crt

# Python
export REQUESTS_CA_BUNDLE=/path/to/corporate-ca.crt

# Git
git config --global http.sslCAInfo /path/to/corporate-ca.crt
```

## Troubleshooting

### Test Connectivity

```bash
# Basic test
mise run proxy:test

# Manual curl test
curl -v https://api.github.com

# Test with explicit proxy
curl -v --proxy http://proxy.company.com:8080 https://api.github.com
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Connection refused" | Verify proxy URL and port |
| "407 Proxy Authentication Required" | Add username:password to proxy URL |
| "SSL certificate problem" | Add corporate CA or use `--insecure` (not recommended) |
| "Connection timed out" | Check if host should be in NO_PROXY |
| Tool ignores proxy | Check for lowercase variants (http_proxy) |

### Debug Mode

```bash
# curl verbose
curl -v --proxy-verbose https://api.github.com

# Git debug
GIT_CURL_VERBOSE=1 git fetch

# npm debug
npm config set loglevel verbose
```

## NO_PROXY Best Practices

Always bypass proxy for:

```bash
NO_PROXY="localhost,127.0.0.1,::1,.local,.internal,*.company.com,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16"
```

| Pattern | Matches |
|---------|---------|
| `localhost` | Exactly "localhost" |
| `127.0.0.1` | Loopback IPv4 |
| `::1` | Loopback IPv6 |
| `.local` | All *.local domains |
| `*.company.com` | Company internal domains |
| `10.0.0.0/8` | Private network (some tools) |

## Mise Tasks Reference

| Task | Description |
|------|-------------|
| `mise run proxy:status` | Show all proxy configuration |
| `mise run proxy:setup` | Interactive proxy setup |
| `mise run proxy:test` | Test connectivity to common endpoints |
| `mise run proxy:clear` | Remove all proxy configuration |

## See Also

- [SECRETS.md](SECRETS.md) - Secure credential management
- [MIGRATION.md](MIGRATION.md) - Migrating from other tools
- [mise documentation](https://mise.jdx.dev/configuration.html#env) - Environment configuration
