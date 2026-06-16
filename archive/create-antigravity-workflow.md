**Objective:** Rebuild the Antigravity workflow framework from the ground up, replacing the superficial copy-paste migration with a properly architected system that leverages Antigravity's native capabilities (KIs, persistent context, user_rules, autonomous tool-calling, conversation logs).

### 1. Milestones

1. **Phase 1 — Foundation & Routing**: Clean the repo, design the dispatch architecture, establish how workflows are discovered and invoked.
2. **Phase 2 — Knowledge Migration**: Adapt GCA styles into Antigravity-native knowledge files and design the lessons-learned system.
3. **Phase 3 — Core Workflow Refactoring**: Rewrite all 18 GCA prompts as Antigravity-native workflows, organized by lifecycle tier.
4. **Phase 4 — Documentation Suite**: Rewrite onboarding, cookbook, routine catalog, and customization guides for the new paradigm.
5. **Phase 5 — Validation & Rollout**: End-to-end testing, team trial, feedback integration.

---

### 2. Task Checklist

#### Phase 1 — Foundation & Routing

- [x] Step 1.1: **Clean the Antigravity Repo.** Remove all 18 bulk-copied GCA prompt files from `antigravity/workflows/` and all 13 blind-copied GCA style files from `antigravity/knowledge/`. Start with a clean slate. The repo structure should be:
  ```
  antigravity/
  ├── workflows/          # (empty — will be populated in Phase 3)
  │   ├── planning/       # PRD, arch, plan-work
  │   ├── execution/      # work-on-task, tdd, fix-bug, clarify
  │   ├── review/         # code-review, check-log, manual-verification
  │   └── lifecycle/      # sprint-wrapup, git-merge, deploy-to-dev, record-lesson
  ├── knowledge/          # (empty — will be populated in Phase 2)
  │   ├── architecture/   # Architecture cheat sheet, routing rules
  │   ├── standards/      # Python, TypeScript, testing, security, CI/CD, etc.
  │   └── operational/    # Lessons learned, pitfalls, environment specifics
  ├── docs/               # (will be rewritten in Phase 4)
  ├── README.md
  └── .gitignore
  ```

- [x] Step 1.2: **Design the Workflow Dispatch Layer.** This is the critical design decision. Define how developers invoke workflows in Antigravity. The recommended approach:

  **Option A — `@[file]` Mention Pattern (Recommended):**
  Users mention the workflow file directly in their prompt:
  ```
  @[antigravity/workflows/planning/plan-work.md] Plan the new bulk export feature described in planning/prd_bulk_export.md
  ```
  Antigravity will read the file and treat it as instructions.

  **Option B — Natural Language with user_rules Aliases:**
  Add to `user_rules`: "When the user says 'plan work' or 'plan-work', read and execute the workflow in `antigravity/workflows/planning/plan-work.md`."

  **Decision needed:** Option A is explicit and reliable. Option B is ergonomic but fragile. Recommend **Option A as primary, Option B as sugar**.

  Deliverable: A `antigravity/docs/workflow-dispatch.md` explaining the invocation mechanism.

- [x] Step 1.3: **Create the Workflow Index.** Create `antigravity/workflows/INDEX.md` — a machine-readable and human-readable catalog of all available workflows. This serves the same discoverability purpose as the GCA `routine-catalog.md` + `gemini.code-snippets` combined.

  Format per entry:
  ```markdown
  ### plan-work
  - **File:** `workflows/planning/plan-work.md`
  - **Trigger:** `@[antigravity/workflows/planning/plan-work.md] <description>`
  - **Purpose:** Break a feature/task into implementable steps
  - **Input:** Task description, PRD, or user story
  - **Output:** Plan saved to `planning/tasks/`
  ```

- [x] Step 1.4: **Define Global Agent Behavior via user_rules.** Draft the additions to `user_rules` that establish consistent agent behavior across all sessions. Key rules:
  - When working in any I4G repo, proactively read the relevant knowledge files from `antigravity/knowledge/`
  - Never output full file contents in chat — just list modified files
  - Always check off completed tasks in plan files
  - Use `planning/change_log.md` to record significant changes
  - When encountering ambiguity, stop and ask (don't guess)
  - Multi-repo changes must be committed together to maintain consistency

---

#### Phase 2 — Knowledge Migration

- [x] Step 2.1: **Adapt Architecture Knowledge.** Rewrite `architecture.md` for Antigravity context. Key changes:
  - Remove `applyTo` frontmatter (not an Antigravity concept)
  - Remove references to `.gemini/styles/` and `@file:` tags
  - Add Antigravity-specific header explaining this is reference material the agent should proactively consult
  - Content itself (routing tables, auth model, storage, database schema, pitfalls) is excellent and should be preserved verbatim
  - Split into `knowledge/architecture/` sub-files if the 306-line monolith is unwieldy

- [x] Step 2.2: **Adapt Language Standards.** Rewrite `python.md`, `typescript.md`, `testing.md` for Antigravity. Changes:
  - Remove `applyTo` frontmatter
  - Add clear headers: "These standards apply when working on Python/TypeScript files in any I4G repository"
  - Content is good — preserve the specific rules, just remove GCA-specific framing
  - Place in `knowledge/standards/`

- [x] Step 2.3: **Adapt Operational Knowledge.** Rewrite `ci-cd.md`, `docker.md`, `security.md`, `data.md`, `settings.md`, `terraform.md`, `docs.md` for Antigravity. Same adaptation pattern as above.
  - Place in `knowledge/standards/` or `knowledge/operational/` as appropriate

- [x] Step 2.4: **Adapt Routing & Workflow Rules.** Rewrite `00-routing.md` and `workflow.md`:
  - `00-routing.md`: Remove `.gemini/context.md` references. Replace with: "When working in a specific repo, check for repo-specific rules in that repo's root directory."
  - `workflow.md`: Remove Agent Mode, snippet, and GCA-specific references. Adapt the merge discipline and multi-phase execution rules for Antigravity's autonomous paradigm.

- [x] Step 2.5: **Port Lessons Learned to Knowledge.** Migrate the content from `gemini/memories/repo/lessons-learned.md` into `antigravity/knowledge/operational/lessons-learned.md`. This operational knowledge is extremely valuable and must not be lost. Categorize:
  - Workspace navigation & token conservation → adapt for Antigravity (some rules are now irrelevant)
  - Boundaries and reliability → keep and adapt
  - Workflow and prompt interpretation → rewrite for Antigravity paradigm
  - Tracking & planning → keep as-is (universal)
  - Coding specifics → keep as-is (universal)

- [x] Step 2.6: **Design the KI Promotion Pipeline.** Document how knowledge gets promoted from volatile (conversation learnings) → persistent (KI files in `knowledge/operational/`) → structural (updates to standards files). This replaces the GCA `record-lesson.md` auto-promotion mechanism.

---

#### Phase 3 — Core Workflow Refactoring

Each workflow must be rewritten with these principles:
1. Written as **instructions to an autonomous agent** — no "ask the user to tag" patterns
2. The agent should **proactively read** relevant knowledge files — no "require the user to load" patterns
3. Remove all GCA-specific syntax (`@file:`, `@folder:`, Agent Mode references)
4. Add Antigravity-specific instructions where the agent's tools change the approach (e.g., `grep_search` replaces manual scoping)
5. Preserve all operational detail and domain knowledge from the GCA originals

##### Tier 1: Planning Workflows

- [x] Step 3.1: **Rewrite `plan-work.md`.** Port from `gemini/prompts/plan-work.md`. Key adaptations:
  - Remove "Ask the user to explicitly tag" → "Proactively read `antigravity/knowledge/architecture/` and relevant language standards"
  - Remove snippet references (`/work-on-task`) → "Instruct the user to invoke the work-on-task workflow for each step"
  - Keep: Template structure, milestone/checklist format, risk identification, the `planning/tasks/` save location
  - Add: Use `write_to_file` to save the plan (not "use file system tools")
  - Place in `workflows/planning/`

- [x] Step 3.2: **Rewrite `prd.md`.** Port from `gemini/prompts/prd.md`. Key adaptations:
  - Add: Role instruction ("You are a Product Manager")
  - Add: Save output to `planning/prds/` using `write_to_file`
  - Add: After generating, proactively identify affected repos and suggest the architecture workflow as next step
  - Place in `workflows/planning/`

- [x] Step 3.3: **Rewrite `arch.md`.** Port from `gemini/prompts/arch.md`. Key adaptations:
  - Replace "Ensure it complies with `.gemini/styles/`" → "Proactively read `antigravity/knowledge/architecture/` to ensure compliance"
  - Keep: System overview, component design, data model, API interface sections
  - Adapt: File Manifest section — remove `@file:` syntax, use absolute paths
  - Add: Save output to `planning/architecture/` using `write_to_file`
  - Place in `workflows/planning/`

##### Tier 2: Daily Execution Workflows

- [x] Step 3.4: **Rewrite `work-on-task.md`.** Port from `gemini/prompts/work-on-task.md`. Key adaptations:
  - Remove "Ensure the new code follows rules in style guides" → "Before implementing, read the relevant standards from `antigravity/knowledge/standards/`"
  - Keep: All specific implementation rules (get_settings(), factories, type hints, docstrings, exception handling)
  - Keep: Test instructions (conda run, pytest, etc.)
  - Keep: Document step, change_log.md updates, checkbox checking
  - Keep: Local validation with pre-commit
  - Add: Explicit `run_command` instructions for test and validation steps
  - Place in `workflows/execution/`

- [x] Step 3.5: **Rewrite `tdd.md`.** Port from `gemini/prompts/tdd.md`. Key adaptations:
  - Remove "Require the user to tag the specific source file" → "Use `grep_search` or `list_dir` to locate the relevant source and test files"
  - Remove "Enforce referencing `@file:.gemini/styles/testing.md`" → "Proactively read `antigravity/knowledge/standards/testing.md`"
  - Keep: Red/Green/Refactor phases
  - Add: Use `run_command` to execute tests between phases
  - Place in `workflows/execution/`

- [x] Step 3.6: **Rewrite `fix-bug.md`.** Port from `gemini/prompts/fix-bug.md`. Key adaptations:
  - Remove "Require the user to tag specific files" → "Use `grep_search` and `view_file` to locate relevant code from stack traces"
  - Remove "Ask the user to tag the appropriate language style guide" → "Proactively read from `antigravity/knowledge/standards/`"
  - Add: Use `run_command` to reproduce the bug if possible
  - Add: Use `run_command` to verify the fix
  - Place in `workflows/execution/`

- [x] Step 3.7: **Rewrite `clarify.md`.** Port from `gemini/prompts/clarify.md`. Key adaptations:
  - Remove "Tell the user to turn Agent Mode OFF" — not applicable to Antigravity
  - Keep: The structured clarification block format (it's excellent)
  - Keep: "Do not keep working" and "Do not commit speculative changes" discipline
  - Place in `workflows/execution/`

##### Tier 3: Review & Quality Workflows

- [x] Step 3.8: **Rewrite `code-review.md`.** Port from `gemini/prompts/code-review.md`. Key adaptations:
  - **CRITICAL:** Remove "Do NOT search the workspace for changes" — this was a GCA token-saving measure that cripples Antigravity. Replace with: "Run `git diff` and `git status` across all workspace repos to identify changes"
  - Remove "Ask the user to explicitly tag changed files" → autonomous diff generation
  - Remove "Instruct the user to explicitly tag ONLY the corresponding styleguides" → "Proactively read the relevant standards from `antigravity/knowledge/standards/`"
  - Keep: Multi-repo consistency checks, documentation sync, architecture consistency, quality gates, test coverage
  - Add: Use `run_command` to run quality gates (pre-commit, make build, etc.)
  - Place in `workflows/review/`

- [x] Step 3.9: **Rewrite `check-log.md`.** Port from `gemini/prompts/check-log.md`. Key adaptations:
  - Keep: GCP project detection logic (this is critical operational knowledge)
  - Keep: `gcloud logging read` command templates
  - Keep: Diagnosis steps and root cause analysis
  - Add: Use `run_command` to execute gcloud commands
  - Add: Use `grep_search` to locate relevant source code from error traces
  - Place in `workflows/review/`

- [x] Step 3.10: **Rewrite `manual-verification.md`.** Port from `gemini/prompts/manual-verification.md`. Key adaptations:
  - Keep: Health checks, API smoke tests, UI verification, worker verification
  - Add: Use `run_command` for API health checks (curl commands)
  - Add: Consider using `browser_subagent` for UI verification
  - Place in `workflows/review/`

##### Tier 4: Lifecycle Workflows

- [x] Step 3.11: **Rewrite `sprint-wrapup.md`.** Port from `gemini/prompts/sprint-wrapup.md`. Key adaptations:
  - Keep: All 9 steps — they are excellent operational procedure
  - Adapt: "Inspect the `git diff` for drift" → use `run_command` to generate diffs
  - Adapt: "Check `git log` across repos" → use `run_command` for multi-repo log scanning
  - Keep: Risk assessment, manual steps listing, merge readiness
  - Keep: Lesson recording (now routes to `antigravity/knowledge/operational/lessons-learned.md`)
  - Place in `workflows/lifecycle/`

- [x] Step 3.12: **Rewrite `git-merge.md`.** Port from `gemini/prompts/git-merge.md`. Key adaptations:
  - Keep: All 5 phases — this is the crown jewel workflow
  - Adapt Phase 2: Instead of "Execute every step of `@prompts/code-review.md`" → "Read and execute the code review procedure from `antigravity/workflows/review/code-review.md`"
  - Adapt Phase 3: Use `run_command` for `git status`, `git diff --check`, `grep` scans
  - Keep: Secret scanning rules (sk-, ghp_, AIza, AKIA patterns)
  - Keep: Stray file detection rules
  - Keep: Conventional commit format
  - **CRITICAL**: Keep the "Do NOT ask for permission to push" instruction — this is deliberately aggressive
  - Adapt: Reference `antigravity/knowledge/standards/workflow.md` instead of `.gemini/styles/workflow.md`
  - Place in `workflows/lifecycle/`

- [x] Step 3.13: **Rewrite `wrapup-and-merge.md`.** Port from `gemini/prompts/wrapup-and-merge.md`. Key adaptations:
  - Adapt cross-references to point to new workflow locations
  - Keep: The 2-phase structure (sprint-wrapup then merge)
  - Place in `workflows/lifecycle/`

- [x] Step 3.14: **Rewrite `deploy-to-dev.md`.** Port from `gemini/prompts/deploy-to-dev.md`. Key adaptations:
  - Remove "Require the user to tag `@file:.gemini/styles/ci-cd.md`" → proactively read from knowledge
  - Keep: All operational detail (smoke test commands, image build logic, migration steps, post-deploy verification)
  - Keep: Dev/prod parity check
  - Add: Use `run_command` for build and deploy commands
  - Place in `workflows/lifecycle/`

- [x] Step 3.15: **Rewrite `record-lesson.md`.** Port from `gemini/prompts/record-lesson.md`. Key adaptations:
  - Change target file from `memories/repo/lessons-learned.md` → `antigravity/knowledge/operational/lessons-learned.md`
  - Keep: Categorization system (coding pitfall, architecture pattern, workflow tip, environment/config)
  - Adapt auto-promotion target: from `.gemini/styles/` → `antigravity/knowledge/standards/`
  - Place in `workflows/lifecycle/`

- [x] Step 3.16: **Rewrite `hardening-sprint.md`.** Port from `gemini/prompts/hardening-sprint.md`. Key adaptations:
  - Remove Agent Mode quota management warnings
  - Keep: Plan loading, progress tracking, context loading
  - Adapt file references to planning directory paths
  - Place in `workflows/lifecycle/`

##### Tier 5: Session Management (Mostly Obsolete)

- [x] Step 3.17: **Evaluate `rehydrate-session.md` and `prepare-new-session.md` for obsolescence.** 
  - `rehydrate-session.md`: In Antigravity, KIs auto-load across sessions and conversation logs are retrievable. The explicit "read memories, read architecture, read changelog" steps are largely handled natively. **Recommendation:** Mark as obsolete. Create a minimal "session-start" workflow that just reminds the agent to check KIs and recent conversation context.
  - `prepare-new-session.md`: The "generate a copy-paste prompt for a new session" pattern is obsolete. Antigravity can retrieve previous conversation logs natively. **Recommendation:** Mark as obsolete. Replace with a simple "session-summary" workflow that documents current state in `planning/change_log.md` before closing.

---

#### Phase 4 — Documentation Suite

- [x] Step 4.1: **Rewrite the README.** The current README is 11 lines. It should match the quality of the GCA README (87 lines). Include:
  - What the framework provides (in Antigravity-native terms)
  - Quick start guide (how to invoke workflows, what the `@[file]` pattern looks like)
  - Repository structure explanation
  - Links to all documentation

- [x] Step 4.2: **Rewrite the Onboarding Guide.** The current guide is superficial. Match the GCA onboarding depth:
  - Prerequisites (Antigravity installed, workspace repos cloned)
  - Workspace setup (explain multi-root — emphasize it just works)
  - How to invoke workflows (the dispatch mechanism from Step 1.2)
  - Understanding agent autonomy (what it will do vs. what it asks permission for)
  - First workflow walkthrough (step-by-step example)
  - Session management tips (when to start new sessions, how context persists)

- [x] Step 4.3: **Rewrite the Cookbook.** The current cookbook has 4 generic examples. Match the GCA cookbook's 5 detailed recipes plus add Antigravity-specific ones:
  - Recipe 1: End-to-end feature development (PRD → arch → plan → execute → review → merge)
  - Recipe 2: Bug hunting and fixing (stack trace → check-log → fix-bug → verify)
  - Recipe 3: Session continuation (how context persists naturally in Antigravity)
  - Recipe 4: Deep refactoring with cross-repo impact
  - Recipe 5: Platform hardening sprint
  - Recipe 6 (NEW): Cross-repo merge workflow
  - Recipe 7 (NEW): GCP log diagnosis → automated fix pipeline

- [x] Step 4.4: **Create the Routine Catalog.** Port the GCA `routine-catalog.md` with updated names, locations, and trigger patterns. Organize by tier (Planning, Execution, Review, Lifecycle).

- [x] Step 4.5: **Create the Customization Guide.** Explain how team members can:
  - Add new workflows
  - Update knowledge files
  - Record lessons that persist as KIs
  - Contribute to the framework via PR

---

#### Phase 5 — Validation & Rollout

- [x] Step 5.1: **Functional Validation.** Execute each workflow in a real scenario to verify it works end-to-end:
  - Plan a small feature using `plan-work.md`
  - Execute a task using `work-on-task.md`
  - Fix a known bug using `fix-bug.md`
  - Run a code review using `code-review.md`
  - Run a merge using `git-merge.md`

- [x] Step 5.2: **Cross-Repo Validation.** Verify multi-root workspace behavior:
  - Edit files in `core/` and `ui/` in the same session
  - Run tests in both repos
  - Commit and push changes across repos

- [x] Step 5.3: **Team Trial.** Have 2-3 team members use the framework for 1 week. Collect feedback on:
  - Workflow invocation ergonomics
  - Missing workflows or knowledge
  - Agent behavior consistency
  - Pain points vs. GCA

- [x] Step 5.4: **Finalize and Commit.** Incorporate feedback, update documentation, and commit the final framework to the `antigravity` repository. Tag as `v1.0`.