# Migration Plan: medan-observability Instance Type Change

**Date**: 2026-02-02  
**Cluster**: medan-observability  
**Change**: m6i.large → t3.large  
**Estimated Savings**: ~13% ($0.0128/hr = ~$9.22/month)

---

## Current State

| Property | Value |
|----------|-------|
| Cluster Name | medan-observability |
| Instance Type | m6i.large (2 vCPU, 8 GB RAM) |
| Region | us-east-1a |
| IP Address | 54.167.7.47 |
| Disk | 256 GB (4% used = 8.7 GB) |
| Status | UP |
| Running Since | 6 days |
| Accumulated Cost | ~$24.33 |

## Target State

| Property | Value |
|----------|-------|
| Instance Type | t3.large (2 vCPU, 8 GB RAM) |
| Same specs | ✅ (vCPU, RAM unchanged) |
| Cost per hour | $0.0832 (vs $0.096) |

---

## Pre-Migration Checklist

- [ ] Verify no critical workloads running: `sky exec medan-observability "ps aux | grep -v '\[' | wc -l"`
- [ ] Document any custom configurations
- [ ] Note the current IP (54.167.7.47) - will change after recreation
- [ ] Verify AWS credentials: `aws sts get-caller-identity`

---

## Migration Steps

### Step 1: Create New Cluster Configuration

Create `templates/medan-observability.yaml`:

```yaml
name: medan-observability

resources:
  cloud: aws
  region: us-east-1
  instance_type: t3.large
  disk_size: 256

setup: |
  echo "Setting up medan-observability cluster"
  # Add any required setup commands here

run: |
  echo "Cluster ready"
```

### Step 2: Terminate Old Cluster

```bash
# Verify cluster status first
sky status medan-observability

# Terminate the cluster (data will be lost)
sky down medan-observability -y
```

**⚠️ WARNING**: This permanently deletes the instance and its disk. No data is preserved.

### Step 3: Launch New Cluster

```bash
# Launch with new instance type
sky launch templates/medan-observability.yaml -c medan-observability -y

# Or use the quick launch task
mise run agent:up CLUSTER=medan-observability YAML=templates/medan-observability.yaml
```

### Step 4: Verify New Cluster

```bash
# Check status
sky status medan-observability

# Verify instance type
sky status -v 2>/dev/null | grep medan-observability

# SSH to verify access
sky exec medan-observability "uname -a && free -h && df -h"
```

---

## Validation Checklist

After migration, verify:

| Check | Command | Expected |
|-------|---------|----------|
| Cluster is UP | `sky status medan-observability` | Status: UP |
| Instance type correct | `sky status -v \| grep medan` | t3.large |
| SSH works | `ssh medan-observability` | Login successful |
| Disk available | `sky exec ... "df -h"` | ~248 GB available |
| Memory correct | `sky exec ... "free -h"` | ~7.6 GB total |

### Validation Script

Run this after migration:

```bash
#!/bin/bash
echo "=== Validating medan-observability migration ==="

# Check cluster is up
STATUS=$(sky status 2>/dev/null | grep medan-observability | awk '{print $6}')
if [ "$STATUS" = "UP" ]; then
    echo "✅ Cluster is UP"
else
    echo "❌ Cluster status: $STATUS"
    exit 1
fi

# Check instance type
INSTANCE=$(sky status -v 2>/dev/null | grep medan-observability | grep -o 't3.large')
if [ "$INSTANCE" = "t3.large" ]; then
    echo "✅ Instance type: t3.large"
else
    echo "❌ Instance type is not t3.large"
    exit 1
fi

# Check SSH access
sky exec medan-observability "echo 'SSH OK'" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ SSH access working"
else
    echo "❌ SSH access failed"
    exit 1
fi

# Check resources
echo "=== Resource Check ==="
sky exec medan-observability "free -h | head -2 && df -h / | tail -1"

echo "=== Migration Validated Successfully ==="
```

---

## Rollback Plan

If issues occur, recreate with original instance type:

```yaml
# templates/medan-observability-rollback.yaml
name: medan-observability

resources:
  cloud: aws
  region: us-east-1
  instance_type: m6i.large  # Original type
  disk_size: 256
```

```bash
sky down medan-observability -y
sky launch templates/medan-observability-rollback.yaml -c medan-observability -y
```

---

## Cost Analysis

| Metric | m6i.large | t3.large | Savings |
|--------|-----------|----------|---------|
| Hourly | $0.096 | $0.0832 | $0.0128/hr |
| Daily | $2.304 | $1.997 | $0.307/day |
| Monthly | $69.12 | $59.90 | $9.22/month |
| Yearly | $829.44 | $718.80 | $110.64/year |

---

## Execution Commands (Quick Reference)

```bash
# 1. Pre-check
sky status medan-observability

# 2. Terminate old
sky down medan-observability -y

# 3. Create config (see Step 1)
cat > templates/medan-observability.yaml << 'EOF'
name: medan-observability

resources:
  cloud: aws
  region: us-east-1
  instance_type: t3.large
  disk_size: 256

setup: |
  echo "Cluster ready"
EOF

# 4. Launch new
sky launch templates/medan-observability.yaml -c medan-observability -y

# 5. Validate
sky status -v | grep medan-observability
sky exec medan-observability "free -h && df -h /"
```

---

## Notes

- **IP Address**: Will change after recreation. Update any DNS/firewall rules.
- **SSH Keys**: SkyPilot manages these; no action needed.
- **Data**: Cluster appears to have minimal custom data (only SkyPilot runtime).
- **Downtime**: ~5-10 minutes for termination + launch.
