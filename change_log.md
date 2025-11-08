# DT-IFG Migration Change Log

_Last updated: 7 Nov 2025_

This log captures significant planning decisions and architecture changes as we progress through the migration milestones. Update entries chronologically.

## 2025-11-06
- Added open-first guiding principle to migration plan.
- Published technology evaluation matrix covering identity, retrieval/search, and LLM hosting options.
- Drafted future-state architecture describing GCP-only, open-aligned topology.
- Created implementation roadmap sketching workstreams and sequencing.

## 2025-11-07
- Clarified future-state architecture vector-store placement and added managed vs local deployment profiles.
- Standardised configuration approach on Pydantic BaseSettings with environment-specific overrides.
- Refactored runtime settings into nested sections (`settings.api`, `settings.storage`, `settings.vector`, etc.) to enable per-component swaps between local resources and GCP services.
- Codified engineering defaults: prefer comprehensive type hints, Google-style docstrings, and focused inline comments to aid long-term maintainability.
- Added `planning/persistent_prompt.md` as the canonical session-rehydration checklist (scan planning docs, refresh change log, honor coding conventions).
- Added `src/i4g/services/factories.py` with helper builders for structured, review, and vector stores so services can instantiate backends directly from configuration.
- Migrated ingestion, retrieval, report generation, worker tasks, and CLI admin utilities to the new factory helpers so configuration-driven backend swaps propagate consistently.
- Began Milestone 2 prep: extracted action list from `migration_plan.md` and outlined upcoming architecture deliverables.
- Expanded `planning/future_architecture.md` with Mermaid topology diagram, detailed data-flow narratives, and capability replacement matrix to anchor Milestone 2 discussions.
- Documented preferred Mermaid preview tooling (`bierner.markdown-mermaid`) in `persistent_prompt.md` so contributors know how to view diagrams locally.
- Captured single-owner context in `persistent_prompt.md` (work assumed by Jerry, with Copilot support) to keep action items grounded.
- Elaborated the Security & IAM section (service accounts, secrets, monitoring) in `future_architecture.md` and marked the corresponding Milestone 2 workstream as drafted.
- Added automatic local-environment overrides (`mock` auth, SQLite/Chroma stores, Ollama, Secret Manager disabled) so the sandbox can run on a laptop without cloud credentials and documented the profile in planning notes.
- Introduced `scripts/bootstrap_local_sandbox.py` to recreate demo data with a single command, keeping the laptop environment reproducible.
