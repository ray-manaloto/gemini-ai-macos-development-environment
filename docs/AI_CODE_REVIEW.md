# AI Code Review Setup

This repository uses 5 AI-powered code review tools to automatically analyze pull requests.

## Required Secrets

Add these secrets in **Settings > Secrets and variables > Actions**:

| Secret Name | Required For | How to Get |
|-------------|--------------|------------|
| `OPENAI_API_KEY` | CodeRabbit, ChatGPT-CodeReview | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `OPENAI_KEY` | PR-Agent | Same as above (can use same key) |
| `ANTHROPIC_API_KEY` | Claude Code | [console.anthropic.com/api-keys](https://console.anthropic.com/settings/keys) |

> **Note**: `GITHUB_TOKEN` is automatically provided by GitHub Actions.

## Enabled Tools

| Tool | Workflow | Description |
|------|----------|-------------|
| PR-Agent | `ai-review-pr-agent.yml` | Open source by Qodo, highly configurable |
| CodeRabbit | `ai-review-coderabbit.yml` | Popular AI reviewer, free for OSS (archived but functional) |
| ChatGPT-CodeReview | `ai-review-chatgpt.yml` | Lightweight GPT-4 reviewer |
| Claude Code | `ai-review-claude.yml` | Official Anthropic action, 5.4k+ stars |

## Behavior

- **Trigger**: All pull requests (opened, synchronized, reopened)
- **Blocking**: Non-blocking (failures won't prevent PR merge)
- **Concurrency**: Each tool cancels previous runs on same PR

## Troubleshooting

### Reviews not appearing
1. Check that secrets are configured in repository settings
2. Verify API keys are valid and have credits
3. Check workflow run logs in Actions tab

### Rate limiting
- OpenAI has rate limits based on your plan
- Gemini free tier has generous limits (60 requests/minute)

## Cost Considerations

| Provider | Free Tier | Paid |
|----------|-----------|------|
| OpenAI | No free tier | Pay-per-token |
| Gemini | 60 req/min free | Pay-per-token |

## Disabling a Tool

To disable a specific tool, delete or rename its workflow file:
```bash
mv .github/workflows/ai-review-chatgpt.yml .github/workflows/ai-review-chatgpt.yml.disabled
```
