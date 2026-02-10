# Roadmap

**Status**: Active
**Last updated**: February 8, 2026

## Current Sprint: CTO-Ready Consolidation (Feb 2026)

A cross-repo quality sweep to bring documentation, code, and infrastructure into alignment
for external review. Tracked in [tasks/consolidation_plan.md](tasks/consolidation_plan.md).

### Completed (Phases 1-4)
- [x] Phase 1: Retired Streamlit legacy code, Dockerfiles, and Terraform resources
- [x] Phase 1: Removed Firestore residuals across docs and diagrams
- [x] Phase 2: Updated PRD, architecture, data model, IAM, storage, jobs, RAG TDDs
- [x] Phase 2: Updated arch-viz diagrams (IAP, intake form corrections)
- [x] Phase 3: Full backend audit (24 debt items); remediated P0 bug, deps, tests, entry points
- [x] Phase 4: Full frontend audit (26 debt items); remediated 8 quick-win items + runtime bug fix
- **Debt inventory:** 19 of 61 items resolved; 42 deferred architectural refactors

### Remaining Phases
- **Phase 5**: End-user documentation (GitBook, runbooks, CONTRIBUTING)
- **Phase 6**: Infrastructure & config consistency (Terraform, env vars, CI/CD)

---

## Principles
- Keep parity and security features stable (tokenization, dual-write ingestion, dossier flow) while consolidating.
- Make decisions reversible: favor feature toggles and configuration over code forks.
- Timebox reactivation: when the team reconvenes, start with a 1-2 day planning refresh using the PRDs and `change_log.md`.

## Next Milestones (post-consolidation)
1) **Production Hardening v2**
   - Replace prototype API-key auth with IAP JWT verification in FastAPI.
   - Wire alerting for PII access, ingestion failures, and dossier verification.
   - Capture baseline SLOs (perf/latency, queue depth) and size autoscaling limits.

2) **Partner/LEA Integrations**
   - Formalize report delivery and receipt flows (LEA portal or partner API).
   - Add signing/attestation for reports where required; keep signature manifest the source of truth.
   - Define data-sharing boundaries and redaction defaults per partner.

## Standing Follow-ups
- [ ] **Performance Optimization**: Execute the [Case Classification Optimization Plan](tasks/perf_optimization_classification.md) to fix slow bootstrapping.
- [ ] **Verify Attachment Retrieval**: Confirm that `source_url` in the `source_documents` SQL table correctly points to the original files in GCS/Local FS.
- [ ] **Wire RAG pipeline to settings.llm.provider**: `pipeline.py` hardcodes Ollama; needs the same provider switch as `classifier.py`.

## When Work Resumes
- Re-read PRDs (`prd_production.md`, `prd_prototype.md`) and the trimmed `change_log.md`.
- Rehydrate from `change_log.md`, the active task plan in `tasks/`, and `.entire/`/`.claud/` context.
- Draft a 4-week execution plan aligned to whichever milestone we pick first; push any new research spikes into `planning/archive/` once resolved.
