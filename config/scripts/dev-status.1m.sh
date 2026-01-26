#!/bin/bash
# <bitbar.title>DevEnv Status</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Mise Generator</bitbar.author>
# <bitbar.desc>Controls for Dev Environment</bitbar.desc>

ORB_STATUS=$(orb status 2>/dev/null || echo "stopped")
SKY_COUNT=$(sky status --refresh 2>/dev/null | grep -c "UP" || echo "0")

# 2. Menu Bar Icon (Traffic Light System)
if [[ "$ORB_STATUS" == *"running"* ]]; then
  echo "🟢 DevEnv | color=green"
else
  echo "🔴 DevEnv | color=red"
fi

echo "---"

# 3. Local Control (OrbStack)
echo "📦 Local: $ORB_STATUS"
echo "-- Start OrbStack | bash=orb param1=start terminal=false refresh=true"
echo "-- Stop OrbStack | bash=orb param1=stop terminal=false refresh=true"

# 4. Cloud Control (SkyPilot)
echo "☁️ AWS Agents: $SKY_COUNT Active"
if [ "$SKY_COUNT" -gt 0 ]; then
    echo "-- 🔴 STOP ALL CLOUD | bash=sky param1=down param2=--all terminal=true"
fi

# 5. System Maintenance
echo "---"
echo "-- Launch | bash=mise param1=run param2=agent:up terminal=true"
echo "-- Kill All | bash=mise param1=run param2=agent:down terminal=true"
echo "---"
echo "📊 Dashboard | bash=mise param1=run param2=dashboard terminal=true"
