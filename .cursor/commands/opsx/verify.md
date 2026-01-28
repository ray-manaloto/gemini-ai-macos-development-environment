---
name: "OPSX: Verify"
description: Verify implementation matches change artifacts before archiving
category: Workflow
tags: [workflow, verify, experimental]
---

Verify that an implementation matches the change artifacts (specs, tasks, design).

**Input**: Optionally specify a change name after `/opsx:verify` (e.g., `/opsx:verify add-auth`).

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Ask user to select.

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```

3. **Get the change directory and load artifacts**
   ```bash
   openspec instructions apply --change "<name>" --json
   ```

4. **Verify Completeness**

   - Parse task checkboxes: `- [ ]` vs `- [x]`
   - Count complete vs total tasks
   - Check spec requirements are implemented

5. **Verify Correctness**

   - For each requirement, search codebase for implementation
   - Check scenario coverage

6. **Verify Coherence**

   - If design.md exists, verify implementation follows decisions
   - Check code pattern consistency

7. **Generate Verification Report**

   ```
   ## Verification Report: <change-name>

   ### Summary
   | Dimension    | Status           |
   |--------------|------------------|
   | Completeness | X/Y tasks        |
   | Correctness  | M/N reqs covered |
   | Coherence    | Followed/Issues  |
   ```

   **Issues by Priority:**
   1. CRITICAL (Must fix before archive)
   2. WARNING (Should fix)
   3. SUGGESTION (Nice to fix)

   **Final Assessment:**
   - If CRITICAL issues: "X critical issue(s) found. Fix before archiving."
   - If all clear: "All checks passed. Ready for archive."

**Guardrails**
- Always provide specific, actionable recommendations
- Prefer SUGGESTION over WARNING when uncertain
- Skip checks gracefully if artifacts are missing
