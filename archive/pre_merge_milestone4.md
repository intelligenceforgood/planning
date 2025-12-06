# Pre-merge Checklist: Milestone 4 (Agentic Evidence Dossiers)

Before merging the Milestone 4 changes into `main`, run these checks and capture notes in the PR description.

## Functional checks
- [ ] Run the dossier API unit tests: `conda run -n i4g pytest tests/unit/api/test_reports.py -q`
- [ ] Run the local pilot verification: `conda run -n i4g python scripts/run_lea_pilot.py` (should return `0` and print `VERIFY OK`).
- [ ] Start FastAPI and run the integration smoke script:
  ```bash
  conda run -n i4g nohup uvicorn i4g.api.app:app --port 8000 &
  conda run -n i4g python scripts/enqueue_sample_dossier.py
  conda run -n i4g python scripts/smoke_dossiers.py --api-url http://127.0.0.1:8000 --token dev-token --limit 1
  ```

## Docs & Runbooks
- [ ] Ensure `docs/runbooks/console/reports.md` includes a step-by-step verification guide and CLI examples.
- [ ] Ensure `docs/dev_guide.md` describes the test scripts and env vars for local runs.
- [ ] Ensure `docs/architecture.md` reflects the current Dossier flow/version and links to the Drive diagram.
- [ ] Ensure `docs/runbooks/console/dossier_monitoring.md` has at least one sample alert rule and remediation steps.

## Infra & CI
- [ ] Nightly smoke action (`.github/workflows/nightly-smoke-dossiers.yml`) is present and configured to create sample artifacts and run the smoke script.
- [ ] Ensure the Action uses a small Python dependency set so it remains reliable in CI; remove heavy extras where possible.

## Security & PII
- [ ] Confirm that Dossier artifacts emitted into Drive are controlled by shared Drive ACLs and do not leak raw PII in the manifest.

## Tests & Lint
- [ ] Run unit test suite for the subset of services touched by M4 (reports, store, dossier pipeline).
- [ ] Run `pre-commit` and fix any style issues, or annotate PR with skipped tests justification where `adhoc/` tests depend on heavy libs.

## Post-merge actions (required after merge)
- [ ] Monitor the nightly smoke for 48 hours; escalate on repeated mismatches.
- [ ] Confirm dashboard alerts fire and assigned on-call is notified.
- [ ] Schedule a follow-up sprint item to implement KMS-backed signing and Air-gapped verify flow (if required by LEA).
