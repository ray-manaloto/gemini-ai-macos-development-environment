#!/bin/bash
set -e
echo "🏥 Running Hygiene Check..."

# 1. Check Python Isolation (Must be Pixi/Uv, not System)
PY_PATH=$(which python)
if [[ "$PY_PATH" == *"/usr/bin/"* ]]; then
    echo "❌ CRITICAL: System Python detected! Isolation failed."
    exit 1
fi

# 2. Check Secrets
if ! command -v infisical &> /dev/null; then
    echo "⚠️  Infisical not found."
else
    echo "✅ Infisical ready."
fi

# 3. Check Container Engine
if command -v orb &> /dev/null; then
    echo "✅ OrbStack available."
else
    echo "⚠️  OrbStack not found."
fi

# 4. Check Cloud Auth
if ! sky status &> /dev/null; then
    echo "⚠️  AWS/SkyPilot not configured."
else
    echo "✅ SkyPilot ready."
fi

echo "✨ System is Clean & Reproducible."
