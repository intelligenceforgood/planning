# Persistent Prompt – Proto / i4g

Use this file to rehydrate context whenever a coding session restarts (e.g., VS Code crash, new machine, fresh agent instance).

## 1. Immediate Setup Checklist
- **Scan planning artifacts:** Read the latest versions of the files in `planning/` (`change_log.md`, `future_architecture.md`, `gap_analysis.md`, `implementation_roadmap.md`, `migration_plan.md`, `system_review.md`, `technology_evaluation.md`, etc.) to refresh project state.
- **Review recent decisions:** `planning/change_log.md` captures the running ledger of architectural choices and coding conventions. Always skim the newest entries.
- **Confirm environment:** Workspace assumes the Conda env `i4g` (`/Users/jerry/miniforge3/envs/i4g`). Verify interpreter selection if commands fail and avoid spawning ad-hoc shells or unnamed envs—always run tools via `conda run -n i4g` (or the VS Code-selected interpreter) so dependencies stay consistent.

## 2. Engineering Conventions (Always Active)
- Write comprehensive **type hints** for new/modified Python code.
- Use **Google-style docstrings** and add concise inline comments when logic is non-trivial.
- Maintain the **Pydantic settings** structure introduced on 2025-11-07 (nested sections for `api`, `storage`, `vector`, `llm`, etc.) and prefer env-variable overrides over hard-coded values.
- Instantiate structured, review, and vector stores through the shared factory helpers in `src/i4g/services/factories.py` so configuration-driven backend swaps keep working across the codebase.
- When updating configs or workflows, reflect the change in both code and the relevant planning docs (usually the change log).
- For Milestone 2 planning work, keep `planning/m2_task_outline.md` alongside `planning/future_architecture.md`; update both as architecture decisions evolve. Use Mermaid diagrams for topology when practical. GitHub’s preview or mermaid.live render reliably; locally, the VS Code extension `bierner.markdown-mermaid` currently offers the best support.
- Assume a two-person team (you + Copilot) with you as the sole decision maker—no external reviews or approvals are required. Stakeholders can share feedback, but changes only happen if you choose to take them on.
- `I4G_ENV=local` now enforces sandbox defaults (mock identity, SQLite/Chroma backends, Ollama, Secret Manager off). Keep that profile intact for laptop runs; cloud environments focus on the two GCP projects `i4g-dev` and `i4g-prod` unless we explicitly carve out security test sandboxes.
- Use `python scripts/bootstrap_local_sandbox.py --reset` whenever you need to rebuild local demo data (bundles, OCR outputs, Chroma store, review cases) in one step.
- Terraform automation lives in `infra/` with a GCS backend and Workload Identity Federation to GitHub Actions (`modules/iam/workload_identity_github`). Target `i4g-dev` for all applies until `i4g-prod` is ready; impersonate `sa-infra` via `gcloud auth application-default login` + token creator role before running plans locally.

## 3. Workflow Expectations
- Record significant decisions or work-in-progress summaries in `planning/change_log.md` (or add new dated docs if better suited).
- Before pushing, run the appropriate smoke tests or pytest suites when code changes warrant it; note in the summary if tests were skipped.
- Preserve ASCII-only edits unless existing files already contain Unicode that is necessary.
- Never revert user-authored changes unless explicitly instructed.
- Terraform changes are mirrored in GitHub Actions (`infra/.github/workflows/terraform-dev.yml`); keep repository variables (`TF_GCP_*`) updated when project IDs or providers change.
- When listing risks/blockers, focus on technology or architectural uncertainties that might cause rework; stakeholder alignment is informational only.

## 4. Rehydration Notes
- If the session resumes after a gap, rerun a quick diff (`git status -sb`) to understand outstanding work.
- Re-open this document plus `planning/change_log.md` as your first two references; they act as the shared prompt for ongoing collaboration.

_This document should evolve alongside the project—update it whenever expectations or processes change so future sessions stay aligned._
