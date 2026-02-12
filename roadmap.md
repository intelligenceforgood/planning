# Roadmap

**Status**: Active
**Last updated**: February 12, 2026

## Current Sprint: Quality Elevation Round 2 (Feb 2026)

A second-pass systematic improvement of the codebase, building on the completed
[Consolidation Sprint](archive/consolidation_plan.md) and
[Debt Remediation Sprint](archive/debt_remediation_plan.md). Tracked in
[tasks/quality_elevation_plan.md](tasks/quality_elevation_plan.md).

### Completed

- [x] Phase 1: Retired Streamlit legacy code, Dockerfiles, and Terraform resources
- [x] Phase 1: Removed Firestore residuals across docs and diagrams
- [x] Phase 2: Updated PRD, architecture, data model, IAM, storage, jobs, RAG TDDs
- [x] Phase 2: Updated arch-viz diagrams (IAP, intake form corrections)
- [x] Phase 3: Full backend audit (24 debt items); remediated P0 bug, deps, tests, entry points
- [x] Phase 4: Full frontend audit (26 debt items); remediated 8 quick-win items + runtime bug fix
- [x] Phase 5: End-user documentation (GitBook, runbooks, CONTRIBUTING)
- [x] Phase 6: Infrastructure & config consistency (Terraform, env vars, CI/CD)
- [x] Debt Remediation Round 1: 68 debt items across 10 work streams — ALL COMPLETE
- [x] Quality Elevation Round 2: WS-1 through WS-9 complete (66 items); WS-10 in progress
  - **WS-1:** Security hardening (CORS, auth, API key leak, allUsers removal)
  - **WS-2:** Config discipline & API quality
  - **WS-3:** Store consolidation & factory discipline
  - **WS-4:** API completeness & correctness
  - **WS-5:** Core code organization (settings split, type modernization)
  - **WS-6:** UI performance & bundle optimization
  - **WS-7:** UI code quality & deduplication
  - **WS-8:** Test coverage expansion
  - **WS-9:** Infrastructure quality (dev/prod parity, Terraform modularization)
  - **WS-10:** Documentation & planning alignment (in progress)

---

## Principles

- Keep parity and security features stable (tokenization, dual-write ingestion, dossier flow) while consolidating.
- Make decisions reversible: favor feature toggles and configuration over code forks.
- Timebox reactivation: when the team reconvenes, start with a 1-2 day planning refresh using the PRDs and `change_log.md`.

## Next Milestones

1. **Production Hardening v2**
   - ~~Replace prototype API-key auth with IAP JWT verification in FastAPI.~~ _(Done — WS-1/E2)_
   - Implement full RBAC (currently all authenticated Cloud users get admin role).
   - Wire alerting for PII access, ingestion failures, and dossier verification.
   - Capture baseline SLOs (perf/latency, queue depth) and size autoscaling limits.

2. **Partner/LEA Integrations**
   - Formalize report delivery and receipt flows (LEA portal or partner API).
   - Add signing/attestation for reports where required; keep signature manifest the source of truth.
   - Define data-sharing boundaries and redaction defaults per partner.

## Standing Follow-ups

- [ ] **Performance Optimization**: Execute the [Case Classification Optimization Plan](tasks/perf_optimization_classification.md) to fix slow bootstrapping.
- [ ] **Verify Attachment Retrieval**: Confirm that `source_url` in the `source_documents` SQL table correctly points to the original files in GCS/Local FS.
- [ ] **Wire RAG pipeline to settings.llm.provider**: `pipeline.py` hardcodes Ollama; needs the same provider switch as `classifier.py`.

## When Work Resumes

- Re-read PRDs (`prd_production.md`, `prd_prototype.md`) and the `change_log.md`.
- Rehydrate from `change_log.md`, the active task plan in `tasks/`, and `.entire/`/`.claud/` context.
- Draft a 4-week execution plan aligned to whichever milestone is picked first; push any new research spikes into `planning/archive/` once resolved.
