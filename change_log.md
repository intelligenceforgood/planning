# Planning Change Log (active items only)

Last updated: 14 Dec 2025

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2025-12-14.md`.

## 2025-12-11
- Repo rename to `core/` is complete. Flip any remaining `proto` references and use `I4G_API_KIND=core` going forward.

## 2025-12-10
- PII vault finalized: deterministic `AAA-XXXXXXXX` tokens, sharded GCS layout, and cross-project Secret Manager/KMS bindings
  captured in [core/docs/pii_vault.md](../core/docs/pii_vault.md). Cloud Run must read pepper/key via env vars.

## 2025-12-06
- LEA dossier flow: portal download + verification parity (API proxy + Web Crypto); nightly smoke covers `/reports/dossiers`.
  Use the signature manifest contract in [core/docs/architecture.md](../core/docs/architecture.md) for any new report work.

## 2025-12-02
- Hybrid search + structured filters are baseline: Vertex AI Search + SQL dual-write with retry queue. See ingestion settings in
  `config/settings.*.toml` and the retrieval contracts in [core/docs/architecture.md](../core/docs/architecture.md).
