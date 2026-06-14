# Task Plan: Integrate AG2 Built-In Capabilities into Custom Skills

**Objective:** Enhance the custom I4G skills to leverage Antigravity 2.0's built-in features (`/grill-me`, `/goal`, `/teamwork-preview`, `/schedule`, `define_subagent`, `ask_question`, `research` subagent) instead of reimplementing equivalent functionality.

**All tasks are 🟢 SIMPLE** — each is a small, isolated text edit to a single markdown file. Use **Gemini 3.5 Flash** for all tasks.

---

## How to Execute This Plan

1. Switch to **Gemini 3.5 Flash** in AG2
2. Say: `/work-on-task planning/tasks/ag2-integration.md — start with task 1`
3. After each task, the agent will check it off and move to the next
4. All tasks are independent — you can do them in any order or skip any

---

## Task Checklist

### Task 1: Add `/grill-me` reference to `/prd`

- [x] 🟢 **Modify** `antigravity/.agents/skills/prd/SKILL.md`

**What to change:** Add a "Before You Start" section between the "When to Use" section (line 16) and the "Template" section (line 17).

**Insert this text after line 16:**

```markdown

## Before You Start

1. **Consider running `/grill-me` first.** AG2's built-in `/grill-me` command runs an interactive interview that systematically resolves design decisions, ambiguities, and scope questions. This prevents mid-PRD clarification loops that waste Opus tokens. Especially useful when the feature request is vague or spans multiple repos.
```

---

### Task 2: Add `/grill-me` reference to `/arch`

- [x] 🟢 **Modify** `antigravity/.agents/skills/arch/SKILL.md`

**What to change:** Add a step to the existing "Before You Start" section (after line 20).

**Add as item 3 in the "Before You Start" list (after the existing two items at lines 19-20):**

```markdown
3. **If design decisions are unresolved**, recommend the user run AG2's `/grill-me` command first. It conducts a structured interactive interview to align on architectural trade-offs before committing Opus tokens to the full design.
```

---

### Task 3: Upgrade `/delegate` to use `define_subagent` for specialized repo agents

- [x] 🟢 **Modify** `antigravity/.agents/skills/delegate/SKILL.md`

**What to change:** In the EXECUTE section (around line 105), replace the generic subagent invocation guidance with specialized subagent definitions.

**Find this text (around lines 107-111):**
```
For **parallelizable units**: invoke all subagents simultaneously using `invoke_subagent` with multiple entries in the `Subagents` array. Each subagent:
- Gets `enable_write_tools: true`
- Workspace mode: `inherit`
- Receives the delegation brief as its prompt
- Has a descriptive `Role` (e.g., "Backend API Implementer", "Frontend Route Builder")
```

**Replace with:**
```
**Prefer specialized subagents over generic ones.** Use AG2's `define_subagent` tool to create repo-specific agents with targeted system prompts and knowledge. This reduces per-subagent token overhead by pre-loading only the relevant standards.

**Recommended subagent definitions (define once per session, reuse across delegations):**

| Subagent Name | System Prompt Should Include | Use For |
|:---|:---|:---|
| `core_impl` | `core/AGENTS.md` + `antigravity/knowledge/standards/python.md` | Backend API changes in `core/` |
| `ssi_impl` | `ssi/AGENTS.md` + `antigravity/knowledge/standards/python.md` | SSI agent/adapter changes in `ssi/` |
| `ui_impl` | `ui/AGENTS.md` + `antigravity/knowledge/standards/typescript.md` | Frontend/React changes in `ui/` |
| `infra_impl` | `infra/AGENTS.md` + `antigravity/knowledge/standards/terraform.md` | Infrastructure changes in `infra/` |

If a delegation unit spans repos not covered above, fall back to the generic `self` subagent type.

For **parallelizable units**: invoke all subagents simultaneously using `invoke_subagent`. Each subagent:
- Gets `enable_write_tools: true`
- Workspace mode: `inherit`
- Receives the delegation brief as its prompt
- Has a descriptive `Role` (e.g., "Core Backend Implementer", "UI Route Builder")
```

---

### Task 4: Add `ask_question` recommendation to `/clarify`

- [x] 🟢 **Modify** `antigravity/.agents/skills/clarify/SKILL.md`

**What to change:** Add a note after the clarification block template (after line 41) recommending the `ask_question` tool.

**Insert after line 41 (after the closing `</clarify>` tag line):**

```markdown

4. **Use AG2's `ask_question` tool when options are clear.** If the clarification has discrete options (e.g., "Should we use approach A or B?"), use the `ask_question` tool instead of free-form text. This renders an interactive multi-choice modal that is faster for the user and produces unambiguous structured responses — saving tokens on parsing.

5. **Do not keep working.** Do not commit speculative changes. Leave the workspace in a clean state.
```

**Also delete the existing line 43** (the current "Do not keep working" step 4) since we're renumbering it as step 5 above.

---

### Task 5: Add `/goal` and `/teamwork-preview` to the quota playbook

- [x] 🟢 **Modify** `antigravity/docs/quota-playbook.md`

**What to change:** Add a new section after "Prompt Engineering for Efficiency" (after line 143) and before "Skills Quick Reference by Quota State" (line 146).

**Insert this new section between lines 143 and 144:**

```markdown

---

## AG2 Built-In Power Features

AG2 has built-in slash commands that can dramatically reduce your manual overhead. Use them to complement your custom skills:

### `/goal` — Autonomous Long-Running Tasks
Instead of manually chaining skills (plan → implement → review → merge), tell AG2 to complete the entire goal autonomously:

```
/goal: Implement all 🟢 SIMPLE tasks in planning/tasks/bulk-export.md, run tests, and prepare for review
```

AG2 will work continuously until the goal is achieved, chaining skills as needed. **Best for:** batches of simple implementation tasks on Gemini. **Avoid for:** tasks requiring architectural decisions (those need Opus planning first).

### `/teamwork-preview` — Multi-Agent Collaboration
For large features spanning 3+ repos, `/teamwork-preview` spawns a coordinated team of agents. This is a more powerful version of `/delegate` — AG2 handles the orchestration automatically.

```
/teamwork-preview: Implement the bulk export feature from planning/tasks/bulk-export.md
```

**Best for:** Large, well-planned features with independent work streams. **Requires:** An existing task plan with clear, file-isolated tasks.

### `/grill-me` — Interactive Design Interview
Before spending Opus tokens on `/prd` or `/arch`, use `/grill-me` to resolve design ambiguities through a structured Q&A:

```
/grill-me: I want to add bulk CSV export to the reports system
```

AG2 will ask targeted questions to nail down scope, edge cases, and trade-offs — so your subsequent planning session is focused and efficient.

### `/schedule` — Automated Maintenance
Set up recurring maintenance tasks:

```
/schedule: Run /codebase-digest every Monday at 9am
```

This keeps your repo digests fresh automatically, so every session starts with current structural context.
```

---

### Task 6: Add `/schedule` reference to `/codebase-digest`

- [x] 🟢 **Modify** `antigravity/.agents/skills/codebase-digest/SKILL.md`

**What to change:** Add a tip to the execution rules section at the end of the file about using AG2's `/schedule` command for automation.

**Add this as the last execution rule (append to the execution rules list at the end of the file):**

```markdown
- **Automate with `/schedule`**: Instead of remembering to run this skill weekly, the user can set up a recurring schedule with AG2's built-in `/schedule` command: `/schedule: Run /codebase-digest every Monday at 9am`. This ensures digests are always fresh without manual intervention.
```

---

### Task 7: Add `research` subagent reference to `/context-map`

- [x] 🟢 **Modify** `antigravity/.agents/skills/context-map/SKILL.md`

**What to change:** In the execution rules section (at the end of the file, around line 119), add a note about using AG2's built-in `research` subagent for background scanning.

**Add this as a new execution rule (after the existing rule about being read-only):**

```markdown
5. **Use the `research` subagent for background scanning.** When generating a context map for a large slice (4+ repos), consider invoking AG2's built-in `research` subagent to scan repos in parallel. The research subagent is read-only by design and returns summarized findings — a natural fit for context extraction.
```

---

### Task 8: Add `/goal` reference to `using-skills.md`

- [x] 🟢 **Modify** `antigravity/docs/using-skills.md`

**What to change:** In the "Skill Chaining" section (around line 34), add a note about using `/goal` as an alternative to manual chaining.

**Find this text (around lines 34-37):**
```
## Skill Chaining

Some skills reference other skills internally (e.g., `wrapup-and-merge` chains `sprint-wrapup` → `git-merge`). When the agent encounters such a reference, it natively invokes the referenced skill and executes it as a sub-procedure.

You do not need to manually chain skills. Just invoke the top-level one.
```

**Replace with:**
```
## Skill Chaining

Some skills reference other skills internally (e.g., `wrapup-and-merge` chains `sprint-wrapup` → `git-merge`). When the agent encounters such a reference, it natively invokes the referenced skill and executes it as a sub-procedure.

You do not need to manually chain skills. Just invoke the top-level one.

### Autonomous Chaining with `/goal`

For longer chains of work, AG2's built-in `/goal` command can execute multiple skills autonomously until the goal is fully achieved. Instead of manually invoking each skill in a chain, describe the end state:

```text
/goal: Implement all 🟢 tasks in planning/tasks/bulk-export.md, run tests, do a lean review, and merge
```

AG2 will chain `/work-on-task` → `/lean-review` → `/git-merge` automatically. Use this on **Gemini** for implementation-heavy work to maximize throughput without manual intervention.
```

---

### Task 9: Update skill catalog with `/teamwork-preview` chain

- [x] 🟢 **Modify** `antigravity/docs/skill-catalog.md`

**What to change:** At the end of the "Skill Chains" section (after the "Quota-Optimized Feature" chain), add a new chain.

**Append after the last skill chain entry:**

```markdown

### Multi-Agent Feature (Large Scope)
```
/grill-me → prd → arch (Opus) → plan-work (Opus) → session-bridge → /teamwork-preview (Gemini, autonomous) → code-review (Sonnet) → git-merge
```
```

---

## Summary

| Task | File | Change | Complexity |
|:---|:---|:---|:---|
| 1 | `prd/SKILL.md` | Add `/grill-me` reference | 🟢 3 lines |
| 2 | `arch/SKILL.md` | Add `/grill-me` reference | 🟢 1 line |
| 3 | `delegate/SKILL.md` | Upgrade to `define_subagent` | 🟢 ~15 lines |
| 4 | `clarify/SKILL.md` | Add `ask_question` tool reference | 🟢 ~5 lines |
| 5 | `quota-playbook.md` | Add AG2 Power Features section | 🟢 ~40 lines |
| 6 | `codebase-digest/SKILL.md` | Add `/schedule` reference | 🟢 1 line |
| 7 | `context-map/SKILL.md` | Add `research` subagent reference | 🟢 2 lines |
| 8 | `using-skills.md` | Add `/goal` autonomous chaining | 🟢 ~10 lines |
| 9 | `skill-catalog.md` | Add multi-agent skill chain | 🟢 4 lines |

**Total: 9 tasks, all 🟢 SIMPLE, all Gemini-safe.**
**Estimated: 1 Gemini session, ~9 turns.**
