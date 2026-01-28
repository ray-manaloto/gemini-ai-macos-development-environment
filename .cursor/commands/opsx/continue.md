---
name: "OPSX: Continue"
description: Continue working on a change - create the next artifact (Experimental)
category: Workflow
tags: [workflow, artifacts, experimental]
---

Continue working on a change by creating the next artifact.

**Input**: Optionally specify a change name after `/opsx:continue` (e.g., `/opsx:continue add-auth`).

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Ask user to select.

2. **Check current status**
   ```bash
   openspec status --change "<name>" --json
   ```

3. **Act based on status**:

   **If all artifacts are complete**:
   - Congratulate the user
   - Suggest: "All artifacts created! You can now implement this change or archive it."
   - STOP

   **If artifacts are ready to create**:
   - Pick the FIRST artifact with `status: "ready"`
   - Get its instructions
   - Read any completed dependency files for context
   - Create the artifact file
   - Show what was created and what's now unlocked
   - STOP after creating ONE artifact

4. **After creating an artifact, show progress**
   ```bash
   openspec status --change "<name>"
   ```

**Output**

After each invocation, show:
- Which artifact was created
- Schema workflow being used
- Current progress (N/M complete)
- What artifacts are now unlocked
- Prompt: "Run `/opsx:continue` to create the next artifact"

**Guardrails**
- Create ONE artifact per invocation
- Always read dependency artifacts before creating a new one
- Never skip artifacts or create out of order
- If context is unclear, ask the user before creating
