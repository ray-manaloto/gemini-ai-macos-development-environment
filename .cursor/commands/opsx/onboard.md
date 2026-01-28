---
name: "OPSX: Onboard"
description: Guided onboarding - walk through a complete OpenSpec workflow cycle with narration
category: Workflow
tags: [workflow, onboarding, tutorial, learning]
---

Guide the user through their first complete OpenSpec workflow cycle.

## Preflight

Check if OpenSpec is initialized:
```bash
openspec status --json 2>&1 || echo "NOT_INITIALIZED"
```

If not initialized:
> OpenSpec isn't set up in this project yet. Run `openspec init` first, then come back.

---

## Phase 1: Welcome

```
## Welcome to OpenSpec!

I'll walk you through a complete change cycle using a real task in your codebase.

**What we'll do:**
1. Pick a small, real task
2. Explore the problem briefly
3. Create a change
4. Build artifacts: proposal -> specs -> design -> tasks
5. Implement the tasks
6. Archive the completed change

**Time:** ~15-20 minutes

Let's start by finding something to work on.
```

---

## Phase 2: Task Selection

Scan the codebase for small improvements:
- TODO/FIXME comments
- Missing error handling
- Functions without tests
- Type issues (`any` types)

Present 3-4 specific suggestions and let user choose.

---

## Phase 3: Explore Demo

Briefly demonstrate explore mode:
- Read relevant files
- Draw ASCII diagrams if helpful
- Note considerations

---

## Phase 4-8: Create Artifacts

Walk through creating:
1. **Proposal** - WHY we're making this change
2. **Specs** - WHAT in precise, testable terms
3. **Design** - HOW we'll build it
4. **Tasks** - Checkboxes for implementation

Pause for user approval at each step.

---

## Phase 9: Apply

Implement each task:
- Announce what's being worked on
- Make code changes
- Mark tasks complete
- Show progress

---

## Phase 10: Archive

```bash
openspec archive "<name>"
```

---

## Phase 11: Recap

```
## Congratulations!

You just completed a full OpenSpec cycle:

1. Explore - Thought through the problem
2. New - Created a change container
3. Proposal - Captured WHY
4. Specs - Defined WHAT
5. Design - Decided HOW
6. Tasks - Broke it into steps
7. Apply - Implemented the work
8. Archive - Preserved the record

## Command Reference

| Command | What it does |
|---------|--------------|
| /opsx:explore | Think through problems |
| /opsx:new | Start a new change |
| /opsx:ff | Fast-forward: all artifacts at once |
| /opsx:continue | Continue existing change |
| /opsx:apply | Implement tasks |
| /opsx:verify | Verify implementation |
| /opsx:archive | Archive when done |
```

---

## Guardrails

- Follow EXPLAIN -> DO -> SHOW -> PAUSE pattern at key transitions
- Keep narration light during implementation
- Don't skip phases - the goal is teaching the workflow
- Handle exits gracefully
- Use real codebase tasks, not fake examples
