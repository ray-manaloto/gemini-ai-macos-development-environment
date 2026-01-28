---
name: "OPSX: Archive"
description: Archive a completed change in the experimental workflow
category: Workflow
tags: [workflow, archive, experimental]
---

Archive a completed change in the experimental workflow.

**Input**: Optionally specify a change name after `/opsx:archive` (e.g., `/opsx:archive add-auth`).

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Ask user to select.

2. **Check artifact completion status**
   ```bash
   openspec status --change "<name>" --json
   ```

   If any artifacts are not done, display warning and ask for confirmation.

3. **Check task completion status**

   Read tasks file, count incomplete tasks. Warn if incomplete.

4. **Assess delta spec sync state**

   Check for delta specs at `openspec/changes/<name>/specs/`.
   If they exist, offer to sync before archiving.

5. **Perform the archive**
   ```bash
   mkdir -p openspec/changes/archive
   mv openspec/changes/<name> openspec/changes/archive/YYYY-MM-DD-<name>
   ```

6. **Display summary**

   ```
   ## Archive Complete

   **Change:** <change-name>
   **Schema:** <schema-name>
   **Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
   **Specs:** Synced / Skipped / No delta specs
   ```

**Guardrails**
- Always prompt for change selection if not provided
- Don't block archive on warnings - just inform and confirm
- Show clear summary of what happened
