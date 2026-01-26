# Dev Environment Manual

## Status Bar

Check the 🟢 icon in your menu bar. It controls **OrbStack** (Docker) and **SkyPilot** (AWS).

## Commands

- `mise run validate`: Check system health.
- `mise run help`: Show this manual.
- `sky launch agent.yaml`: Deploy AI Agent to AWS.

## Troubleshooting

### Python is leaking from System
Run `mise run validate` - if it fails, your PATH may have `/usr/bin/python` before Pixi.

### OrbStack not starting
Check if Docker Desktop is also installed (conflict). Remove Docker Desktop first.

### SkyPilot not connecting
Run `aws configure` to set up your credentials, then `sky check`.
