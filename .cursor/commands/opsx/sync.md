---
name: "OPSX: Sync"
description: Sync delta specs from a change to main specs
category: Workflow
tags: [workflow, specs, experimental]
---

Sync delta specs from a change to main specs.

This is an **agent-driven** operation - you will read delta specs and directly edit main specs to apply the changes.

**Input**: Optionally specify a change name after `/opsx:sync` (e.g., `/opsx:sync add-auth`).

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Ask user to select.

2. **Find delta specs**

   Look for delta spec files in `openspec/changes/<name>/specs/*/spec.md`.

   Delta specs contain sections like:
   - `## ADDED Requirements`
   - `## MODIFIED Requirements`
   - `## REMOVED Requirements`
   - `## RENAMED Requirements`

3. **For each delta spec, apply changes to main specs**

   For each capability with a delta spec:

   a. Read the delta spec
   b. Read the main spec at `openspec/specs/<capability>/spec.md`
   c. Apply changes intelligently:

      - **ADDED**: Add requirement if doesn't exist, update if exists
      - **MODIFIED**: Find requirement, apply changes, preserve existing content
      - **REMOVED**: Remove the entire requirement block
      - **RENAMED**: Find FROM requirement, rename to TO

   d. Create new main spec if capability doesn't exist yet

4. **Show summary**

   ```
   ## Specs Synced: <change-name>

   Updated main specs:

   **<capability-1>**:
   - Added requirement: "New Feature"
   - Modified requirement: "Existing Feature" (added 1 scenario)

   Main specs are now updated.
   ```

**Key Principle: Intelligent Merging**

You can apply **partial updates**:
- To add a scenario, just include that scenario under MODIFIED
- The delta represents *intent*, not a wholesale replacement

**Guardrails**
- Read both delta and main specs before making changes
- Preserve existing content not mentioned in delta
- If something is unclear, ask for clarification
- The operation should be idempotent
