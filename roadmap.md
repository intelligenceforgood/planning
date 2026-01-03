# Roadmap (future-facing)

**Status**: Paused pending team direction
**Last updated**: December 14, 2025

The legacy migration is complete; active planning now focuses on what comes next. Remaining milestones depend on future
product direction and team availability. This roadmap is intentionally short so we can pick up quickly when priorities
solidify.

## Principles
- Keep parity and security features stable (tokenization, dual-write ingestion, dossier flow) while we pause.
- Make decisions reversible: favor feature toggles and configuration over code forks.
- Timebox reactivation: when the team reconvenes, start with a 1–2 day planning refresh using the PRDs and `change_log.md`.

## Next Milestones (deferred)
1) **Production Hardening v2**
  - Enforce IAP/OAuth everywhere; remove temporary bypasses.
  - Wire alerting for PII access, ingestion failures, and dossier verification.
  - Capture baseline SLOs (perf/latency, queue depth) and size autoscaling limits.

2) **Partner/LEA Integrations**
  - Formalize report delivery and receipt flows (LEA portal or partner API).
  - Add signing/attestation for reports where required; keep signature manifest the source of truth.
  - Define data-sharing boundaries and redaction defaults per partner.

## Immediate Follow-ups
- [ ] **Verify Attachment Retrieval**: Confirm that `source_url` in the `source_documents` SQL table correctly points to the original files in GCS/Local FS, ensuring the removal of Firestore didn't break the link between cases and their evidence.

## When Work Resumes
- Re-read PRDs (`prd_production.md`, `prd_prototype.md`) and the trimmed `change_log.md`.
- Rehydrate Copilot via `copilot_prompt/persistent_prompt.md` and update `copilot_prompt/COPILOT_SESSION.md` with the new
	focus areas.
- Draft a 4-week execution plan aligned to whichever milestone we pick first; push any new research spikes into
	`planning/archive/` once resolved.
