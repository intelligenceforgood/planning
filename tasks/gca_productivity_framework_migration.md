# GCA Productivity Framework Migration & Implementation Plan

This document outlines the step-by-step tasks to transition from the Copilot workflow to the new **Gemini Code Assist (GCA) Productivity Framework** ("The GCA Blueprint"). The developer guide can be found in `gemini/README.md`.

---

## 🎯 Phase 1: Foundation & Repository Setup (Sprint 1)

### Task 1.1: Initialize `gemini` Repository
- [x] Create a new repository named `gemini` adjacent to your other I4G repositories.
- [x] Create the core directory structure:
  ```bash
  mkdir -p gemini/.gemini
  mkdir -p gemini/prompts
  mkdir -p gemini/snippets
  mkdir -p gemini/docs
  ```

### Task 1.2: Establish GCA Global Configurations (Standards & Shared Instructions)
- [x] **Create `.gemini/config.yaml`**: Define the standard behavior for GCA across the I4G platform (severity levels, file inclusion/exclusion rules, ignored patterns).
- [x] **Create `.gemini/styleguide.md`**: Extract and consolidate the extensive core architectural and coding standards from the Copilot repo. **CRITICAL:** We must port over the specific nuances from:
  - **Standards:** `python.instructions.md`, `typescript-react.instructions.md`, `terraform.instructions.md`, `settings-config.instructions.md`, `merge-commit-discipline.instructions.md`, `ui-sdk-build-checklist.instructions.md`, `bigquery.instructions.md`, `ml-training-workflow.instructions.md`, `ruff-pitfalls.instructions.md`.
  - **Shared Context:** `general-coding.instructions.md`, `architecture-cheatsheet.instructions.md`, `pre-merge-checklist.instructions.md`, `doc-governance.instructions.md`, `handoff-manifest.instructions.md`, `phishdestroy-provider-gating.instructions.md`, `phishdestroy-provenance.instructions.md`.
  *(Note: This represents a massive consolidation effort to ensure no architectural constraints or specific CI/CD gate checks are lost.)*

### Task 1.3: Develop the Comprehensive Prompt & Routine Library
Port over the full suite of developer routines into GCA-compatible markdown templates inside the `prompts/` directory:
- [x] **Planning & Scaffolding**: `prd-template.md`, `architecture-template.md`, `impl-plan.md`, `tdd-template.md` (ported from Copilot shared).
- [x] **Core Daily Routines** (Must replicate Copilot's step-by-step enforcement):
  - `plan-work.md` (from `plan-work.prompt.md`)
  - `work-on-task.md` (from `work-on-task.prompt.md`)
  - `fix-bug.md` (from `fix-bug.prompt.md`)
  - `clarify.md` (from `clarify.prompt.md`)
- [x] **Code Review & Quality Gates**:
  - `code-review.md` (from `pre-merge-review.prompt.md`). **CRITICAL Multi-Repo Logic:**
    - Identifying changed repos across the entire workspace (core, ssi, ui, infra).
    - Verifying architecture consistency and cross-repo dependencies.
    - Ensuring codes and docs (`docs/config/settings_manifest.yaml`, `planning/change_log.md`) are synchronized.
    - Running repo-specific quality gates (e.g., Python pre-commit double-pass, UI make check/build).
    - Verifying that all changes across all repos are merged simultaneously to keep the entire application in a clean, consistent state.
- [x] **Deployment & Validation**:
  - `deploy-to-dev.md` (from `deploy-to-dev.prompt.md`)
  - `manual-verification.md` (from `manual-verification.prompt.md`)
  - `merge.md` (from `merge.prompt.md`)
  - `check-log.md` (from `check-log.prompt.md`)
- [x] **Agile & Session Management**:
  - `rehydrate-session.md` (from `rehydrate-session.prompt.md`)
  - `sprint-wrapup.md` (from `sprint-wrapup.prompt.md`)
  - `record-lesson.md` (from `record-lesson.prompt.md`)
  - `hardening-sprint.md` (from `hardening-sprint.prompt.md`)
- [x] **Handoffs**:
  - `handoff.md` (from `handoff.prompt.md`)
  - `execute-manifest.md` (from `execute-manifest.prompt.md`)
  - `verify-handoff.md` (from `verify-handoff.prompt.md`)

### Task 1.4: VSCode Snippet Integration
- [x] Create `snippets/gemini.code-snippets`: Convert the most frequently used prompt commands into VSCode snippets so developers can type quickly (e.g., typing `gca-prd` expands to the full `@prompts/prd-template.md` invocation).

---

## 🚀 Phase 2: Deployment & Workspace Integration (Sprint 1)

### Task 2.1: The "Anchor" Context Setup
- [x] In all 9 existing I4G product repositories (`core/`, `ui/`, `infra/`, etc.), create a symlink or fetch mechanism to reference the global styleguide:
  ```bash
  # Inside an I4G repo:
  mkdir -p .gemini
  ln -s ../gemini/.gemini/styleguide.md .gemini/styleguide.md
  ```
  *(Note: GCA automatically reads `.gemini` folders in the workspace root).*

### Task 2.2: Master Prompt Execution
- [x] Run the "Master Prompt" provided in your brief within GCA Chat to auto-generate the initial content for the files listed in Phase 1.

### Task 2.3: Create Developer Guide
- [x] Create a `README.md` in the `gemini` repository detailing how to use this new framework to develop large-scale software features in VSCode using GCA.

---

## 📈 Success Metrics to Track
As we adopt this new workflow, we will measure success against your defined KPIs:
1. **Architecture Consistency:** Are different repos naturally aligning due to the `.gemini/styleguide.md`?
2. **Coding Quality:** Reduced linting errors and standardized file structures.
3. **Test Coverage:** Increase in unit/smoke tests generated during the TDD phase.
4. **Documentation:** Are PRDs and implementation plans consistently generated and stored in the `docs/` folders?


## 📚 Phase 3: Comprehensive Documentation & Onboarding (Sprint 2)

### Task 3.1: Rework `gemini/README.md`
- [x] Overhaul `gemini/README.md` to match the enhanced GCA framework quality and detail seen in the Copilot repo.
- [x] Define the repository structure, quick start guide, and the role of `.gemini/` in workspace projects.

### Task 3.2: Create GCA Framework Documentation Suite
- [x] Migrate and adapt Copilot framework documents to the new GCA context in `gemini/docs/`.
- [x] `docs/routine-catalog.md`: Catalog of all available GCA prompts and how to invoke them via snippets.
- [x] `docs/onboarding.md`: Comprehensive guide for developers on setting up their environment with GCA and VSCode.
- [x] `docs/cookbook.md`: Real-world workflow examples, prompt combinations, and interaction patterns for GCA.
- [x] `docs/customization-guide.md`: How to extend the GCA framework with new prompts and standards.

## 🔗 Phase 4: Multi-Repo Integration (Sprint 2)

### Task 4.1: Retain and Migrate Repo-Specific Instructions
- [x] Identify existing repo-specific `.github/copilot-instructions.md` in all product repositories (`core/`, `ui/`, `infra/`, etc.).
- [x] Migrate these repo-specific details (conda environments, build commands, architecture notes) into corresponding `.gemini/config.yaml` or a `.gemini/context.md` file within each repository to ensure GCA loads local context alongside global standards.
