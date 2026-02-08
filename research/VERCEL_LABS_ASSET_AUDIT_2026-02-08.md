# Vercel Labs Asset Audit (2026-02-08)

## Scope
- Audited repositories from `https://github.com/orgs/vercel-labs/repositories` using four parallel subagent batches (A-D).
- Focused on installable assets for this repo: project-level skills, CLI tools, MCP tooling, and reusable packages.
- Excluded pure templates/demos/archived repos as required installs.

## Existing Baseline (Before Audit)
- Skills already present at project level under `.agents/skills`.
- Core tools already present via mise: `opencode-ai`, `openspec`, `codex`, `claude-code`, `gemini-cli`, `playwright`, `@playwright/mcp`, `ai`, `just-bash`, `opensrc`, `specli`, `lefthook`.

## High-Confidence Additions Applied

### Project tools (`.mise.toml`)
- `npm:mcp-handler@latest`
- `npm:mcp-to-ai-sdk@latest`
- `npm:vercel-open@latest`
- `npm:dev3000@latest`
- `npm:harden-react-markdown@latest`
- `npm:@vercel/slack-bolt@latest`
- `npm:agent-browser@latest`
- `npm:@vercel/agent-eval@latest`
- `npm:autoship@latest`
- `npm:fix-react2shell-next@latest`

### Project skills (installed from Vercel Labs)
- Source: `vercel-labs/agent-skills`
  - `vercel-composition-patterns`
  - `vercel-react-best-practices` (updated/overwritten from same upstream)
  - `vercel-react-native-skills`
  - `web-design-guidelines` (updated/overwritten from same upstream)
- Source: `vercel-labs/next-skills`
  - `next-best-practices`
  - `next-cache-components`
  - `next-upgrade`
- Source: `vercel-labs/before-and-after`
  - `before-and-after`
- Source: `vercel-labs/skill-remotion-geist`
  - `create-remotion-geist`
- Source: `vercel-labs/vercel-deploy-codex-skill`
  - `vercel-deploy`

## Deferred / Skip Rationale
- Most batch repos were templates/demos (AI SDK starters, framework examples, migration examples), not reusable cross-repo tools.
- Archived repos were skipped.
- Niche service-specific examples (Stripe-only variants, BotID-only templates, app-specific starters) were skipped as required installs.

## Notes from Execution
- `mise use` for npm tools initially failed under Bun linking (`EEXIST`) for some packages.
- Successful workaround used for affected packages:
  - `MISE_NPM_PACKAGE_MANAGER=npm mise use "npm:<package>@latest"`
- Result: all selected high-confidence CLI/package additions were successfully installed and pinned in project `.mise.toml`.

## Validation Pointers
- Skills inventory: `mise run skills:list`
- Tool inventory: `mise run tools:status`
- Environment checks: `mise run validate`
- Skills consistency checks:
  - `mise run skills:validate`
  - `mise run skills:validate:json`

## SKILL.md Exhaustive Pass (Correction)
- Switched from batch repo interpretation to direct org-wide code search using `filename:SKILL.md`.
- Query used: `gh api "search/code?q=org:vercel-labs+filename:SKILL.md&per_page=100&page=1"`.
- Verified result set: `30` SKILL.md hits across `15` unique `vercel-labs` repos.

### Coverage outcome
- Local installed skills after correction: `48`.
- Coverage check result:
  - Covered/installed (including alias coverage): `28`
  - Example-only skills (not required installs): `2` (`csv`, `text` from `vercel-labs/bash-tool/examples/...`)
  - Missing: `0`

### Missing skills that were installed during correction
- `json-render-core`
- `json-render-react`
- `json-render-remotion`
- `remotion-best-practices`
- `find-skills`
- `d3k`
- `autoship`
- `ralph-gpu`
- `frontend-design`
- `ucp`
- `cra-to-next-migration`

### Alias mappings accepted as covered
- `composition-patterns` -> `vercel-composition-patterns`
- `react-best-practices` -> `vercel-react-best-practices`
- `react-native-skills` -> `vercel-react-native-skills`
- `skill` -> `before-and-after`
- `vercel-deploy-claimable` -> `vercel-deploy`

## Traceability: Parallel Batch Audit (Superseded)

Before switching to SKILL.md-first discovery, a parallel batch audit strategy was launched to review repos in groups.

### Batch task IDs and scope
- `bg_2649c6bd` - Batch 1 repo audit
- `bg_0678c48e` - Batch 2 repo audit
- `bg_4c8b4990` - Batch 3 repo audit
- `bg_038da594` - Batch 4 repo audit
- `bg_4b4713e5` - Batch 5 repo audit
- `bg_afcafe0c` - Batch 6 repo audit
- `bg_9e28d36d` - Batch 7 repo audit
- `bg_973bffe7` - Batch 8 repo audit
- `bg_8c183410` - Batch 9 repo audit

### Why superseded
- Batch interpretation can miss skill artifacts when repos are categorized as templates/examples.
- The direct query `org:vercel-labs filename:SKILL.md` is artifact-specific, org-wide, and deterministic for skill discovery.
- Final install decisions were normalized against the org-wide SKILL.md inventory and local skill diff.

### Decision rule used for final state
- Required installs: org-discovered SKILL.md assets not present locally and not alias-covered.
- Allowed skips: example-only paths under `examples/...` (non-project reusable examples).
- Result: no remaining missing skills after correction pass.
