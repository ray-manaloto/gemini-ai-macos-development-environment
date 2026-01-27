# SkyPilot Cloud Agent Guide

Launch ephemeral cloud compute on AWS for AI workloads, training, and development.

---

## Quick Start

```bash
# Launch cloud agent
mise run agent:up

# Check status
sky status

# SSH into agent
ssh ai-agent

# Terminate when done
mise run agent:down
```

---

## Spot Instance Limitations

### Default Configuration

The agent template (`templates/agent.yaml`) uses **spot instances** by default (`use_spot: true`) for cost savings - spot instances are typically 60-90% cheaper than on-demand.

### The Limitation

**Spot instances cannot be stopped or paused.** When terminated, they're completely removed (not paused). This means:

- ❌ `mise run agent:stop` - Cannot stop spot instances
- ❌ `mise run agent:start` - No stopped instances exist to start
- ❌ `mise run agent:restart` - Cannot stop to restart

### What to Do Instead

**For spot instances (default):**

- **Terminate**: `mise run agent:down` - Completely remove the instance
- **Launch new**: `mise run agent:up` - Create a fresh instance

**If you need stop/start capability:**

Change `use_spot: false` in `templates/agent.yaml` to use on-demand instances. Note: This increases costs significantly (3-10x).

---

## Prerequisites

### 1. AWS Account Setup

You need an AWS account with appropriate permissions.

```bash
# Install AWS CLI (if not already installed)
mise use -g "pipx:awscli"

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

### 2. Required IAM Permissions

Create an IAM user or role with these minimum permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:Describe*",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceLinkedRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:GetInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Verify Setup

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify SkyPilot can access AWS
sky check aws
```

---

## Configuration

### Agent Template

The agent configuration is in `templates/agent.yaml`:

```yaml
name: ai-dev-agent

resources:
  cloud: aws
  region: us-east-1
  use_spot: true              # Use spot instances (3-6x cheaper)
  instance_type: t3.xlarge    # 4 vCPU, 16GB RAM

setup: |
  # Install development tools
  curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo bash
  sudo apt-get install -y infisical
  curl https://mise.run | sh
  ~/.local/bin/mise use -g bun npm:@anthropic-ai/claude-code

run: |
  echo "Agent Ready on AWS."
```

### Customizing the Agent

Modify `templates/agent.yaml` to suit your needs:

```yaml
# Use GPU instances for ML training
resources:
  cloud: aws
  accelerators: A100:1        # NVIDIA A100 GPU
  use_spot: true

# Install additional tools
setup: |
  pip install torch transformers

# Run your workload
run: |
  python train.py
```

### Environment Variables

Pass secrets to your agent using `envs` and `secrets`:

```yaml
envs:
  MODEL_NAME: llama-3.1-8b
  WANDB_PROJECT: my-training

secrets:
  ANTHROPIC_API_KEY: sk-ant-...
  HF_TOKEN: hf_...
```

---

## Mise Tasks

| Task | Command | Description |
|------|---------|-------------|
| Launch | `mise run agent:up` | Launch cloud agent |
| Terminate | `mise run agent:down` | Terminate all agents |
| Status | `sky status` | View running agents |
| SSH | `ssh ai-agent` | Connect to agent |
| Logs | `sky logs ai-agent` | View agent logs |

---

## Common Workflows

### Interactive Development

```bash
# Launch agent and SSH in
mise run agent:up
ssh ai-agent

# Inside the agent:
cd ~/sky_workdir
python main.py

# Exit when done
exit
mise run agent:down
```

### Run a Script

```bash
# Execute command on agent
sky exec ai-agent "python train.py"

# Or update agent.yaml with your run command
vim templates/agent.yaml  # Edit run: section
mise run agent:up
```

### Connect VS Code

```bash
# Launch agent
mise run agent:up

# Open VS Code with Remote SSH
code --remote ssh-remote+ai-agent /home/ubuntu/sky_workdir
```

### Jupyter Notebook

```yaml
# Add to agent.yaml
resources:
  ports: 8888

run: |
  pip install jupyter
  jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
```

```bash
mise run agent:up
# Access at http://<agent-ip>:8888
```

---

## Cost Management

### Spot Instances

Spot instances are 3-6x cheaper than on-demand. The default configuration uses spot:

```yaml
resources:
  use_spot: true
```

**Trade-off**: Spot instances can be interrupted. Use for:
- ✅ Development and testing
- ✅ Fault-tolerant training (with checkpointing)
- ❌ Critical production workloads

### Auto-Stop

Prevent runaway costs with autostop:

```yaml
resources:
  autostop:
    idle_minutes: 10    # Stop after 10 minutes idle
    down: true          # Terminate (vs just stop)
```

### Instance Types and Pricing

| Instance | vCPU | RAM | GPU | Spot Price* |
|----------|------|-----|-----|-------------|
| t3.xlarge | 4 | 16GB | - | ~$0.04/hr |
| t3.2xlarge | 8 | 32GB | - | ~$0.08/hr |
| g4dn.xlarge | 4 | 16GB | T4 | ~$0.16/hr |
| p3.2xlarge | 8 | 61GB | V100 | ~$0.90/hr |
| p4d.24xlarge | 96 | 1.1TB | A100x8 | ~$9.80/hr |

*Spot prices vary by region and time. Check `sky show-gpus` for current pricing.

### Budget Alerts

Set up AWS Budget alerts to monitor spending:

1. Go to AWS Console → Billing → Budgets
2. Create budget → Cost budget
3. Set threshold and notification email

---

## Troubleshooting

### "No AWS credentials found"

```bash
# Check if credentials exist
cat ~/.aws/credentials

# Reconfigure
aws configure

# Verify
aws sts get-caller-identity
```

### "Instance launch failed"

```bash
# Check available regions
sky check aws -v

# Try different region in agent.yaml
resources:
  region: us-west-2  # or eu-west-1, ap-northeast-1
```

### "Spot capacity not available"

```bash
# Add fallback to on-demand
resources:
  use_spot: true
  spot_recovery: FAILOVER  # Fall back to on-demand
```

### "SSH connection refused"

```bash
# Wait for instance to initialize
sky status ai-agent  # Check if status is UP

# Retry SSH
ssh ai-agent
```

### "Permission denied" on AWS operations

Check your IAM permissions match the requirements above. Common missing permissions:
- `ec2:CreateSecurityGroup`
- `iam:PassRole`
- `iam:CreateServiceLinkedRole`

---

## Advanced Configuration

### Multi-Region Failover

```yaml
resources:
  accelerators: V100
  any_of:
    - cloud: aws
      region: us-east-1
    - cloud: aws
      region: us-west-2
    - cloud: aws
      region: eu-west-1
```

### File Mounting (S3)

```yaml
file_mounts:
  /data:
    name: my-s3-bucket
    source: s3://my-bucket/datasets
    mode: MOUNT          # Lazy load
```

### Workdir Syncing

```yaml
# Sync local directory to agent
workdir: ~/my-project

# Or use Git repo
workdir:
  url: https://github.com/org/repo.git
  ref: main
```

### Global Configuration

Create `~/.sky/config.yaml` for global settings:

```yaml
aws:
  vpc_name: my-vpc
  use_internal_ips: false
  instance_tags:
    project: ml-training
    team: research

spot:
  controller:
    resources:
      cloud: aws
      region: us-east-1
```

---

## Reference

- [SkyPilot Documentation](https://skypilot.readthedocs.io/)
- [SkyPilot GitHub](https://github.com/skypilot-org/skypilot)
- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [AWS Spot Advisor](https://aws.amazon.com/ec2/spot/instance-advisor/)

---

## Related Files

| File | Purpose |
|------|---------|
| `templates/agent.yaml` | Agent configuration template |
| `config/mise.toml` | Mise tasks (agent:up, agent:down) |
| `SECRETS.md` | Secrets management for AWS credentials |
