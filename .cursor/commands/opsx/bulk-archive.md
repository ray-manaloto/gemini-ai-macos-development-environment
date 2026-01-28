---
name: "OPSX: Bulk Archive"
description: Archive multiple completed changes at once
category: Workflow
tags: [workflow, archive, experimental, bulk]
---

Archive multiple completed changes in a single operation.

**Input**: None required (prompts for selection)

**Steps**

1. **Get active changes**
   ```bash
   openspec list --json
   ```

   If no active changes exist, inform user and stop.

2. **Prompt for change selection**

   Use multi-select to let user choose changes. Include an "All changes" option.

3. **Batch validation**

   For each selected change, collect:
   - Artifact status
   - Task completion
   - Delta specs

4. **Detect spec conflicts**

   Identify when 2+ changes touch the same capability spec.

5. **Resolve conflicts**

   Check codebase to determine which changes are actually implemented.

6. **Show consolidated status table**

   ```
   | Change        | Artifacts | Tasks | Specs   | Status |
   |---------------|-----------|-------|---------|--------|
   | change-a      | Done      | 5/5   | 2 delta | Ready  |
   | change-b      | 1 left    | 2/5   | None    | Warn   |
   ```

7. **Confirm batch operation**

   "Archive N changes?" with options.

8. **Execute archive for each confirmed change**

   Sync specs if needed, then archive.

9. **Display summary**

   ```
   ## Bulk Archive Complete

   Archived N changes:
   - change-a -> archive/YYYY-MM-DD-change-a/
   - change-b -> archive/YYYY-MM-DD-change-b/
   ```

**Guardrails**
- Always prompt for selection, never auto-select
- Detect spec conflicts early and resolve by checking codebase
- Show clear per-change status before confirming
