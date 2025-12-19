# Planning Change Log (active items only)

Last updated: 16 Dec 2025

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2025-12-14.md`.

## 2025-12-19
- Fixed Cloud Run job authentication: `process-intakes` now generates OIDC tokens for service-to-service calls to the API gateway.
- Updated `i4g bootstrap dev verify` to support IAP-protected environments by injecting local identity tokens.
- Refined bootstrap documentation: separated bundle preparation into [core/docs/cookbooks/prepare_bootstrap_bundles.md](../core/docs/cookbooks/prepare_bootstrap_bundles.md) and clarified smoke test expectations.

## 2025-12-11
- Repo rename to `core/` is complete. Flip any remaining `proto` references and use `I4G_API_KIND=core` going forward.

## 2025-12-16
- Data reset/bootstrap plan established for local + dev environments. Canonical bundles live in GCS with manifests; CLI flows will support wipe/import/verify across all storages. See [data_reset_bootstrap_plan.md](data_reset_bootstrap_plan.md).
- Local bootstrap verification now emits a bundle manifest hash and ingestion-run summary to catch stale datasets early.
- Optional dossier signature smoke added to local bootstrap (`--smoke-dossiers`) for end-to-end verification when API is up.
- Archived the data reset/bootstrap sprint plan to [planning/archive/data_reset_bootstrap_plan.md](../planning/archive/data_reset_bootstrap_plan.md) after completing all checklist items.

## 2025-12-10
- PII vault finalized: deterministic `AAA-XXXXXXXX` tokens, sharded GCS layout, and cross-project Secret Manager/KMS bindings
  captured in [core/docs/design/pii_vault.md](../core/docs/design/pii_vault.md). Cloud Run must read pepper/key via env vars.

## 2025-12-06
- LEA dossier flow: portal download + verification parity (API proxy + Web Crypto); nightly smoke covers `/reports/dossiers`.
  Use the signature manifest contract in [core/docs/design/architecture.md](../core/docs/design/architecture.md) for any new report work.

## 2025-12-02
- Hybrid search + structured filters are baseline: Vertex AI Search + SQL dual-write with retry queue. See ingestion settings in
  `config/settings.*.toml` and the retrieval contracts in [core/docs/design/architecture.md](../core/docs/design/architecture.md).
