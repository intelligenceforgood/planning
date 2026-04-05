# Planning Change Log (active items only)

Last updated: 05 Apr 2026

## 2026-04-05 — TIFAP Enrichment Sprint: Schema Normalization + Entity UI

Schema normalization (migration `20260404_01`): `cases.description` column added, `scam_records.classification_result` and `tags` removed, FK constraints on `review_queue` and `scam_records` to `cases`. Display reads (dashboard, case detail, analytics, dossier bundler) now join `cases` directly instead of `scam_records`. Entity extraction keys aligned between NER rules and worker job. New API: `GET /cases/{id}/related` (entity-overlap ranking). UI: Extracted Entities card on case detail, Related Cases card, graph deep-linking from entity explorer, edge click detail with linked case IDs, help modal on network graph. SSI `sql.py` synced with core schema changes.

**Repos affected:** `core/`, `ssi/`, `ui/`, `copilot/`, `planning/`

## 2026-03-24 — ML Platform: Phase 2 Implementation (Sprints 0–4)

Implemented all code deliverables for ML Phase 2: Training Maturity + Continuous Learning. All 7 PRD deliverables (Vizier, shadow mode, continuous retraining, Model Monitoring, accuracy dashboard, cost comparison, NER model) have code committed across `ml/`, `core/`, and `infra/`.

**Repos affected:** `ml/`, `core/`, `infra/`, `planning/`

**ml/ — 22 modified + 21 new files (2001 insertions):**

- **Sprint 0 (Repo Hygiene):** Fixed README paths, deployment runbook conda env, moved `pipeline.yaml` to `pipelines/`, added `compile-pipeline` Makefile target, `.gitignore` + `pyproject.toml` cleanup
- **Sprint 1 (Monitoring + Dashboards):** Implemented `drift.py` (PSI-based prediction/feature drift), `triggers.py` (retraining conditions: data volume, drift, time, force), accuracy materialization, cost summary materialization, BigQuery DDL for `analytics_drift_metrics`, `analytics_trigger_log`, `analytics_cost_summary`
- **Sprint 2 (Shadow Mode + Vizier):** Shadow model loading with memory guard, async shadow inference on `/predict/classify`, `is_shadow` BQ column, `compute_shadow_comparison()`, Vizier hyperparameter tuning (`create_vizier_study`, `run_vizier_sweep`, `get_best_config`), search spaces in pipeline configs
- **Sprint 3 (Continuous Retraining):** `submit_pipeline()` utility, `trigger_retraining.py` Cloud Run Job entry point, retraining runbook
- **Sprint 4 (NER Model):** NER evaluation harness (`seqeval`, BIO tag alignment, per-entity-type F1), NER training container (`containers/train-ner/`, `docker/train-ner.Dockerfile`), multi-capability serving (entity extraction endpoint), NER pipeline config, promotion gate for NER
- **Tests:** 238 passing (101 new tests across 8 new test files)
- **Fixed during pre-merge review:** broken SQL table name in `v_case_features.sql`, `__import__` anti-pattern in `accuracy.py`, bare `except Exception` annotations (6 locations), stray `=1.2` pip output file

**core/ — 4 files (169 insertions):**

- `MLPlatformClient.extract_entities()` — NER endpoint integration
- `entity_extraction_backend` setting (`llm` | `ml_platform`)
- Settings manifest updated with new ML setting
- 8 unit tests passing

**infra/ — 2 files (337 insertions):**

- Vertex AI Model Monitoring job on `serving-prod`
- Cloud Scheduler jobs: drift computation, accuracy materialization, cost materialization, daily retrain trigger, monthly force retrain
- `retrain-trigger` Cloud Run Job
- `NER_MODEL_ARTIFACT_URI` and `SHADOW_MODEL_ARTIFACT_URI` env vars on Cloud Run serving service

**Remaining operational tasks (not code — post-merge):**

- `terraform apply` on `infra/environments/ml/`
- Create Looker Studio dashboards (accuracy + cost)
- Build and push NER training container
- Train NER model, evaluate, deploy to `serving-dev`
- Curate NER golden test set
- Run Vizier sweep on dev
- Activate shadow mode on prod

## 2026-03-22 — ML Platform: Phase 0 Complete

Completed all 68 tasks across 2 sprints. The ML platform is end-to-end functional: data pipeline, training pipeline, model serving, and prediction logging all operational on `i4g-ml` GCP project.

**Repos affected:** `ml/`, `core/`, `infra/`, `planning/`

**Infrastructure (infra/):**

- Terraform modules: `bigquery/dataset`, `vertex_ai/endpoint` — composed in `stacks/ml/`
- GCP resources: BigQuery dataset (`i4g_ml` with 9 tables), Vertex AI Endpoints (`serving-dev`, `serving-prod`), GCS bucket, Artifact Registry, Cloud Run Job (`etl-ingest`)
- Cross-project IAM: `sa-ml-platform` → `i4g-dev` (Cloud SQL reader), `sa-core` → `i4g-ml` (Vertex AI user)

**ML Platform (ml/):**

- ETL pipeline: watermark-based incremental sync from Cloud SQL → BigQuery `raw.*` tables
- Feature engineering: BigQuery SQL view `v_case_features` + scheduled materialization
- Dataset management: stratified split, validation, JSONL export to GCS, golden test set
- Evaluation harness: per-axis P/R/F1, weighted overall, eval gate for promotion
- Training containers: PyTorch (Gemma 2B + LoRA), XGBoost, serving (FastAPI)
- KFP v2 training pipeline: prepare → train → evaluate → register → deploy
- Model registry: stage transitions (experimental → candidate → champion)
- Serving: `/predict/classify` (Vertex AI + direct format), `/feedback`, `/health`
- Prediction + outcome logging to BigQuery (fire-and-forget)
- Evaluation notebook: `notebooks/evaluation/classification_eval.ipynb` — metrics table, F1 bar chart, confusion matrices, baseline comparison

**Core Integration (core/):**

- `analyst_labels` Alembic migration with FK → cases, indexes
- `MLPlatformClient` async httpx client (`classify`, `send_feedback`)
- `build_inference_client()` factory: routes to ML platform or LLM based on settings
- `[ml]` settings section: `inference_backend`, `platform_base_url`, `platform_auth_method`, `fallback_to_llm`
- Unit tests: 5/5 passing (settings, factory, both backends)

**Deferred to Phase 1:**

- `/feedback` e2e test: Vertex AI predict route only proxies `/predict`; needs Cloud Run service fronting container
- Core → Vertex AI integration test: same blocking issue; `MLPlatformClient` unit-tested against direct HTTP format
- Real model training: stub model returns UNKNOWN; evaluation notebook skeleton ready for real metrics

**Next step:** Phase 1 — train a real Gemma 2B + LoRA model on labeled data, deploy Cloud Run service for direct HTTP access, integrate Core → ML platform end-to-end.

## 2026-03-20 — ML Platform: Architecture Redesign (PRD v3 + TDD v2)

Rewrote [ML Platform PRD](prd_ml_infrastructure.md) and [ML Platform TDD](../core/docs/design/ml_infrastructure_tdd.md) as a **standalone ML platform** — separate codebase (`ml/`), separate GCP project (`i4g-ml`), API-driven integration with i4g.

- ML platform is an external service that i4g consumes (like Gemini), not code embedded in core
- GCP-native stack: Vertex AI (Training, Pipelines, Endpoints, Model Registry, Experiments, Workbench, Model Monitoring), BigQuery, Cloud Storage
- Pipeline orchestration: Vertex AI Pipelines (zero baseline cost), not Airflow/Prefect
- Single `i4g-ml` GCP project with dev + prod serving endpoints
- Full data platform: ETL pipelines, BigQuery warehouse, feature engineering, prediction/outcome logging
- Multi-framework training: PyTorch, TensorFlow, XGBoost, Spark ML, HuggingFace
- Continuous learning loop: predictions → outcomes → retraining
- Four-phase delivery: Foundation → Data Maturity → Training Maturity → Advanced Capabilities

**Next step:** Create `ml/` repo and `i4g-ml` GCP project to begin Phase 0.

## 2026-03-18 — PII Vault Simplification: Sprint 3 (Documentation Cleanup)

Completed Sprint 3 of `tasks/pii_vault_simplification.md` — systematic removal of all PII vault/tokenization references from documentation.

**Core design docs (core/docs/):**

- Rewrote `pii_vault.md` — now covers intake Fernet encryption, encrypted fields, audit-logged decryption, victim-contact redaction
- Deleted `pii_vault_redesign.md` (superseded)
- Updated `architecture.md` (~22 edits): removed TokenVault/VaultService from diagrams, updated exec summary, component tables, data flows, SA table, encryption sections, metrics, alerting, disaster recovery
- Updated `data_model.md`, `jobs.md`, `storage.md`, `iam.md`, `security_audit.md`, `compliance.md`, `tdd.md`, `glossary.md`

**Cookbooks (core/docs/cookbooks/):**

- Updated `bootstrap_environments.md`, `smoke_test.md`, `cloud_sql_primer.md`, `github_actions_setup.md`

**Config reference (core/docs/config/):**

- Removed 9 `pii.*` entries + 2 vault password entries from `README.md`, `settings_manifest.yaml`, `settings_manifest.json`
- Updated `crypto.pii_key` description, renamed `detokenization_alert_threshold` → `contact_decrypt_alert_threshold`

**Gitbook docs (docs/book/):**

- Updated `sdk_endpoint_coverage.md`, `authentication.md`, `sample-requests.md`
- Rewrote `secrets-reference.md` (removed tokenization-pepper, pii-tokenization-key, KMS vault key; added crypto-pii-key)
- Updated `settings.md` (removed pii/vault rows), `slo_definitions.md` (removed Detokenize latency, PII Vault Access)
- Rewrote `security-model.md` mermaid diagram (removed VaultZone subgraph) and safeguards text

**Planning docs:**

- Updated `status_updates/2026-01-05.md` link and description

**Utility scripts:**

- Updated `check_settings_drift.py` — removed vault password entries from allowlists

## 2026-03-18 — PII Vault Simplification: Sprint 1 Leftovers + Sprint 2 Complete

Completed all remaining Sprint 1 tasks and all Sprint 2 tasks from `tasks/pii_vault_simplification.md`.

**Sprint 1 leftovers (core/):**

- Added `audit_log` table to main `METADATA` in `sql.py` (victim-contact access tracking)
- Added `IntakeStore.get_contact()` with Fernet decryption + audit logging
- Added `GET /intakes/{id}/contact` API endpoint with `IntakeContactResponse` model
- Added `redact_victim_contact()` to ingest pipeline — replaces victim email/phone with `[VICTIM_EMAIL]`/`[VICTIM_PHONE]` markers before storing case text
- Added 8 new unit tests (5 redaction, 3 contact+audit)

**Sprint 2 (infra/):**

- Deleted `stacks/pii-vault/`, `environments/pii-vault/`, `modules/iam/pii_vault_access/`, `stacks/app/iam_vault.tf`
- Cleaned all vault references from app stack locals, variables, tfvars (dev+prod), moved blocks
- Migrated `I4G_CRYPTO__PII_KEY` secret path from vault project (`i4g-pii-vault-{env}`) → main project (`i4g-{env}`)
- Removed `I4G_PII__PEPPER` from all jobs; removed `sa-vault` service account
- Renamed monitoring: `pii_access_alert` → `victim_contact_access_alert`, `detokenization_threshold` → `victim_contact_access_threshold`

**Validation:** 1255 tests passed, pre-commit clean double-pass.

## 2026-03-17 — Unify SSI Investigation Routing Through Core

### Design Decision: Eliminate Dual-Path SSI Investigation Routing

Removed the `if (SSI_API_URL) → proxyToSsi() else → proxyToCore()` branch from the investigation trigger and status-polling routes. All investigation lifecycle requests now **always** route through Core API, regardless of environment.

**Rationale:**

- SSI investigation is a 3-party interaction (core-svc, ssi-svc, i4g-console). Core manages the database, task status, and audit log — it must be in the loop.
- Two trigger paths exist: manual (UI `/investigate`) and automated (case-intake URL detection). The automated path is definitively UI → Core → SSI. Unifying gives both triggers the same orchestration code.
- Eliminates circular service dependency (SSI no longer needs to call back to Core for task/audit).
- Single auth direction: Core → SSI (OIDC). No bidirectional service-to-service auth needed.
- eCX routes remain direct-to-SSI (stateless reads, Core has no role).

**Files changed:**

- `ui/apps/web/src/app/api/ssi/investigate/route.ts` — removed `proxyToSsi()`, always calls Core
- `ui/apps/web/src/app/api/ssi/investigate/[id]/route.ts` — removed `proxyToSsi()`, always polls Core
- `ui/apps/web/src/lib/server/ssi-proxy.ts` — updated docs (eCX-only helper)
- `ui/apps/web/tests/unit/ssi-dedup-proxy.test.ts` — removed SSI-direct test suite, added "routes through core even when SSI_API_URL set" test
- `core/.github/architecture-cheatsheet.instructions.md` — updated routing tables, pitfall #4
- `planning/proposals/ssi_routing_unification.md` — design decision + consistency checklist

See `planning/proposals/ssi_routing_unification.md` for the full design record and post-sprint consistency checklist.

## 2026-03-17 — Bug Fixes: eCX 502 on Redeploy + EvidenceStorageClient API

### eCX 502 on Cloud Run Redeploy (Root Cause + Fix)

**Root cause:** The UI's eCX proxy routes (`/api/ssi/ecx/*`) use `resolveSsiUrl()` which reads `SSI_API_URL`. In cloud, this env var was **not set** on the i4g-console service — the original comment said "SSI_API_URL is local-dev-only." The investigate/poll routes had a core-API fallback (`if (process.env.SSI_API_URL) { proxyToSsi() } else { proxyToCore() }`), but the eCX routes added in Phase 2/3 did not. Without `SSI_API_URL`, all eCX requests fell back to `http://localhost:8100` on the console container, returning 502.

Each "fix" was likely someone manually adding `SSI_API_URL` to the Cloud Run service via GCP console, which Terraform overwrote on the next `terraform apply`.

**Fix:** Added `SSI_API_URL = module.run_ssi_service[0].uri` to the console env vars in `infra/stacks/app/main.tf`, gated by `var.ssi_service_enabled`. This persists across all deploys. Updated the architecture cheatsheet to document the eCX proxy routes and their SSI-direct dependency.

**Files changed:**

- `infra/stacks/app/main.tf` — added `SSI_API_URL` to console env vars
- `core/.github/architecture-cheatsheet.instructions.md` — added eCX proxy routes table

### EvidenceStorageClient.\_sharded_subpath → sharded_subpath

Promoted `_sharded_subpath` from private to public. The method is a static utility called from `orchestrator.py` to construct GCS evidence paths — accessing a private method from outside the class violated the API contract.

**Files changed:**

- `ssi/src/ssi/evidence/storage.py` — renamed `_sharded_subpath` → `sharded_subpath`
- `ssi/src/ssi/investigator/orchestrator.py` — updated call site

## 2025-07-15 — SSI ↔ Cases Deep Integration (Phases 1–5)

Completed the full SSI ↔ Cases deep integration across five phases. Cases and SSI investigations are now bidirectionally linked, with auto-investigation of URLs found in case narratives and evidence stored under a UUID-prefix sharding scheme.

### Database & Schema (Phase 1)

- Added `case_investigations` join table for one-to-many case↔investigation linking (`trigger_type`: manual, auto, case_created)
- Added `site_scans.normalized_url` column with URL dedup at trigger time
- Backfill scripts: `backfill_case_investigations.py`, `backfill_normalized_urls.py`

### Auto-Investigation Job (Phase 2)

- New `auto_investigate` worker job: queries URL indicators from batch cases, applies domain blocklist + dedup, triggers SSI investigations via Cloud Run
- Extended `linkage_extract` with `mode="cases"` to extract URL indicators from case narratives via LLM
- URL dedup via `check_url_duplicate()` with configurable staleness window
- Domain blocklist support via `is_domain_blocked()` with merged blocklist

### API & Backend (Phase 3)

- New endpoints: `GET /cases/{id}/activity`, `POST /cases/{id}/investigate`
- Case detail response (`GET /cases/{id}`) includes `investigations` array
- Scan detail response (`GET /investigations/ssi/{id}`) includes `linkedCases` array
- SSI evidence API with GCS signed URL generation and dual-path resolution

### UI (Phase 4)

- Activity bar on case detail showing running/completed SSI investigations
- URL investigation status panel with dedup warnings
- Investigation history on case detail

### Evidence Migration & Docs (Phase 5)

- Evidence storage migrated to UUID-prefix sharding (`scans/{hex[:2]}/{hex[2:4]}/{scan_id}/`)
- Per-scan evidence manifests (`metadata.json`) with SHA-256 integrity hashes
- Migration script: `scripts/migrate_evidence_paths.py` (local + GCS, dry-run support)
- Manifest generation script: `scripts/generate_evidence_manifests.py`

### Settings

- New `auto_investigate` section: `enabled`, `staleness_days`, `max_concurrent`, `domain_blocklist`
- Settings manifests regenerated (YAML, JSON, README.md, docs book)

### Tests

- E2E smoke test: `tests/adhoc/test_ssi_case_integration_e2e.py` (5 tests covering full flow)
- Unit tests for migration and manifest scripts

### Documentation

- Updated `docs/book/architecture/ssi-architecture.md` with case↔investigation linking, auto-investigation, evidence storage sections
- Created `docs/book/guides/auto-investigation.md` analyst guide
- Created `docs/book/architecture/evidence-storage.md` design doc (sharding, manifests, resolution strategy)
- Updated `docs/book/SUMMARY.md` with new pages

## 2026-03-14 — TIFAP Sprint 6: External Integrations, Hardening & Documentation (core/ + ui/ + docs/ + ssi/)

Completed Sprint 6 — the final sprint of the Threat Intelligence & Fraud Analytics Platform (TIFAP). All PRD features F-00a through F-52 are implemented or deferred with rationale.

### Blockchain Analytics (S6-01 to S6-05)

- Created `src/i4g/services/blockchain_enrichment.py` — vendor-agnostic blockchain analytics integration (Chainalysis, Elliptic, TRM Labs, or mock). Returns wallet labels, risk scores, transaction amounts, exchange attribution.
- Added `blockchain_vendor` and `blockchain_api_key` to `EnrichmentSettings`.
- Added wallet cluster edge type to `GraphService` — blockchain-derived wallet groupings appear as gold thick edges in the network graph.
- Added blockchain enrichment data to entity detail views for wallet entities.

### LEA Referral Tracking (S6-06 to S6-08)

- Added `POST /cases/{id}/lea-referral` and `GET /cases/{id}/lea-referral` endpoints to `cases.py`.
- LEA referral status aggregated in campaign detail view (which member cases have been referred).

### Partner Indicator Feed (S6-09 to S6-11)

- Created `src/i4g/api/partner_feed.py` — machine-readable indicator feed with STIX 2.1 + CSV export at `GET /feeds/indicators`.
- Dedicated API key authentication (`X-Partner-API-Key` header) via `partner_api_keys` table, SHA-256 key hashing.
- In-memory rate limiting per partner key with configurable `rate_limit_per_minute`.
- Audit logging to `partner_feed_audit` table for all feed access.
- Wired router into `app.py`.

### Mobile Dashboard (S6-12 to S6-13)

- Created `kpi-sparkline-card.tsx` — responsive KPI card component with inline Recharts sparkline.
- Created `campaign-alerts.tsx` — mobile-friendly campaign alert list using `ThreatCampaign` SDK type.
- Made Impact Dashboard responsive: 2-column KPI grid on mobile, responsive chart heights (`h-60 sm:h-80`).

### Hardening & Performance (S6-14 to S6-18)

- Added 9 database indexes to `sql.py` for analytics query optimization (cases, entities, intake_records, indicator_stats, campaign_stats).
- Created `performance_audit.md`, `security_audit.md`, `accessibility_audit.md` design docs.

### Testing (S6-19 to S6-24)

- 34 unit tests across 6 test files — all pass.
- Coverage: blockchain enrichment (mock vendor, cluster, unknown vendor, dataclass fields), LEA referral API (POST/GET), partner feed (models, hashing, rate limiting, audit), performance (index coverage), security (auth enforcement, PII leakage, audit tables), E2E regression (user journeys).

### Documentation (S6-25 to S6-43)

- Updated TDD (`threat_intelligence_analytics_tdd.md`) — version 1.3, blockchain integration + partner feed file inventory.
- Created `docs/book/architecture/threat-intelligence.md` — full TIFAP architecture overview.
- Updated `docs/book/architecture/security-model.md` — Sprint 6 security sections.
- Updated `core/docs/design/campaign_governance_bridge.md` — reconciled with threat campaigns model.
- Created `docs/book/guides/admin/partner_feed.md` — partner feed admin guide.
- Updated `docs/book/guides/law-enforcement.md` — LEA referral tracking, blockchain enrichment in dossiers.
- Created `core/docs/runbooks/analytics_operations.md` — aggregation + enrichment ops runbook.
- Updated `core/docs/cookbooks/smoke_test.md` — analytics smoke test procedures.
- Updated `core/docs/design/architecture.md` — TIFAP components in router table + future architecture.
- Updated `docs/book/api/taxonomy_reference.md` — analytics usage (Sankey, heatmap, trend views).
- Updated `ui/docs/developer-guide.md` — TIFAP frontend development guide.
- Updated `ui/docs/ui_architecture.md` — final nav map with Intelligence, Impact, Reports sections.
- Updated `ui/docs/user-guide.md` — Intelligence Hub, Impact Dashboard enhancements, Reports.
- Created `core/docs/runbooks/console/partner_feed_monitoring.md` — partner feed ops runbook.
- Updated `docs/book/SUMMARY.md` — added partner feed and threat intelligence entries.
- Updated `docs/book/api/sdk_endpoint_coverage.md` — Sprint 6 endpoints.
- Updated `docs/config/settings_manifest.yaml` and `settings_manifest.json` — blockchain + partner_feed settings.
- Updated `ssi/docs/tdd.md` — CampaignCorrelator migration to threat_campaigns model.
- Updated `docs/book/ssi/ecrimex-integration.md` — analytics view of eCX submissions and enrichment.

### Settings Added

- `I4G_ENRICHMENT__BLOCKCHAIN_VENDOR` (default: `mock`)
- `I4G_ENRICHMENT__BLOCKCHAIN_API_KEY` (default: empty)
- `I4G_PARTNER_FEED__ENABLED` (default: `false`)
- `I4G_PARTNER_FEED__RATE_LIMIT_PER_MINUTE` (default: `60`)
- `I4G_PARTNER_FEED__DEFAULT_PAGE_SIZE` (default: `100`)
- `I4G_PARTNER_FEED__MAX_PAGE_SIZE` (default: `1000`)

### Not in Scope

- S6-06 (LEA referral UI) — backend API implemented, frontend wiring deferred to UI sprint.
- S6-05 (wallet cluster edge UI rendering) — backend API implemented, frontend gold-edge rendering deferred to UI sprint.

## 2026-03-14 — TIFAP Sprint 5: Automation + Advanced Features (core/ + docs/)

Completed Sprint 5 of the Threat Intelligence & Fraud Analytics Platform (TIFAP).

### Graph — Advanced (S5-01, S5-02, S5-09)

- **Temporal animation**: `GraphService.get_temporal_snapshots()` generates time-sliced graph snapshots for date-slider animation. API endpoint `GET /intelligence/graph/temporal`.
- **Louvain clustering**: `GraphService.detect_clusters()` uses `networkx.community.louvain_communities` with configurable resolution. Returns cluster ID, size, members, density, avg risk score, entity type breakdown. `enrich_with_clusters()` writes cluster membership to nodes.
- **Infrastructure edges**: `GraphService.add_infrastructure_edges()` loads shared-hosting relationships into the graph with `relationship="infrastructure"` metadata.

### Watchlist & Alerts (S5-04, S5-05, S5-06)

- Created `WatchlistStore` (`store/watchlist_store.py`) — full CRUD for watchlist items and alerts with duplicate detection.
- Added watchlist API endpoints to `intelligence.py` — item CRUD, alert listing, mark-read.
- Created `worker/jobs/watchlist_check.py` — scheduled job checking pinned entities for new case activity and loss threshold breaches.

### Infrastructure Clustering (S5-08)

- Created `worker/jobs/infrastructure_clustering.py` — discovers shared-hosting edges via entity co-occurrence across cases. Edge types: shared_ip, shared_registrar, shared_hosting, shared_case.
- Added `infrastructure_edges` table to `sql.py`.

### External Enrichment (S5-11, S5-12, S5-13)

- Created `services/enrichment/passive_dns.py` — SecurityTrails API integration for historical DNS resolution.
- Created `services/enrichment/asn_lookup.py` — RDAP bootstrap for IP→ASN lookup (no API key).
- Created `worker/jobs/takedown_check.py` — periodic URL reachability check, sets `taken_down_at` on `entity_stats`.

### Scheduled Reports (S5-14)

- Created `worker/jobs/scheduled_reports.py` — configurable auto-generation of recurring reports (daily/weekly/monthly) with CRUD helpers.
- Added `scheduled_reports` table to `sql.py`.

### Embeddable Charts (S5-17, S5-18)

- Added `POST /intelligence/charts/share` — creates time-limited read-only share tokens.
- Added `GET /intelligence/charts/{token_id}/embed` — retrieves chart config for embedding.
- Added `chart_share_tokens` table to `sql.py`.

### Researcher Access (S5-19, S5-20, S5-21)

- Created `services/anonymizer.py` — PII hashing (SHA-256 prefix), loss rounding, batch anonymization.
- Added `GET /exports/researcher/entities` — anonymized entity export (CSV/JSON) for researcher role.

### Victim Analytics (S5-22, S5-23)

- Added `GET /impact/victims` — aggregate victim demographics (age range, country, contact channel) from intake records.

### Settings & Config (S5-24, S5-25)

- Extended `AnalyticsSettings` with `watchlist_check_interval_minutes`, `infrastructure_clustering_interval_hours`, `scheduled_report_check_interval_minutes`.
- Created `EnrichmentSettings` with `securitytrails_api_key`, `takedown_check_interval_hours`, `takedown_max_urls_per_run`.
- Added `[enrichment]` section to `settings.default.toml`.
- 10 unit tests for new settings — all pass.

### Testing (S5-26 to S5-32)

- 48 unit tests across 9 test files — all pass.
- Coverage: temporal graph, Louvain clustering, watchlist CRUD/alerts, infrastructure edge classification, watchlist check helpers, scheduled report cadence, passive DNS/ASN enrichment, PII anonymization, settings overrides.

### Documentation (S5-35 to S5-46)

- Updated TDD (`threat_intelligence_analytics_tdd.md`) with Sections 20–26: clustering, infrastructure edges, watchlist architecture, scheduled reports, external enrichment, researcher anonymization.
- Created `docs/book/guides/analyst/watchlist.md` — watchlist user guide.
- Updated `docs/book/guides/analyst/network_graph.md` — temporal animation, cluster visualization, infrastructure edges.
- Created `docs/book/guides/admin/scheduled_reports.md` — scheduled reports admin guide.
- Updated `core/docs/design/jobs.md` — added watchlist check, infrastructure clustering, takedown check, scheduled reports jobs.
- Updated `docs/config/settings_manifest.yaml` and `settings_manifest.json` — added all Sprint 5 `I4G_ANALYTICS__*` and `I4G_ENRICHMENT__*` env vars.
- Created `core/docs/cookbooks/external_enrichment.md` — passive DNS, ASN, takedown verification setup and troubleshooting.
- Created `core/docs/runbooks/console/watchlist_alerts.md` — watchlist job monitoring and alert triage.
- Updated `docs/book/guides/user-guide.md` — added researcher access section.
- Updated `docs/book/SUMMARY.md` — added watchlist, scheduled reports entries.
- Updated `docs/book/architecture/data-pipeline.md` — added enrichment sources and automation jobs.

### CLI Commands Added

- `i4g jobs watchlist-check`
- `i4g jobs infrastructure-clustering`
- `i4g jobs takedown-check`
- `i4g jobs scheduled-reports`

### Not in Scope (Frontend / Email)

- S5-03, S5-07, S5-10, S5-15 (UI components) — deferred to frontend sprint.
- S5-16 (email delivery for scheduled reports) — deferred pending SMTP/SendGrid integration.
- S5-33 (frontend component tests), S5-34 (E2E smoke) — deferred to frontend sprint.

### Post-Review Hardening (2026-03-14)

- **Scheduled report execution contract fixed**: report builder now sends schedule scope as `date_range` (not `range`), and API normalizes legacy payloads for backward compatibility.
- **One-time cadence corrected**: schedules with `cadence="once"` now deactivate after first run (`is_active=false`, `next_run_at=null`) instead of recurring.
- **Email delivery safety**: scheduled-report emails send only when a report artifact is confirmed on disk, and include the generated artifact as an attachment.
- **Dashboard resiliency**: Intelligence Dashboard no longer fails when watchlist alerts fetch fails; alerts now degrade to an empty list.
- **Regression tests added**: unit tests now cover one-time cadence deactivation and email-after-artifact semantics for scheduled reports.

## 2026-03-14 — TIFAP Sprint 4: Graph, Taxonomy, Geography, Timeline (core/ + ui/ + docs/)

Completed Sprint 4 of the Threat Intelligence & Fraud Analytics Platform (TIFAP).

### Schema Migrations (S4-01 to S4-04)

- Added `taken_down_at` TIMESTAMP to `site_scans`.
- Added `lea_referred_at`, `lea_agency`, `lea_case_number` to `cases`.
- Added `victim_age_range` TEXT to `intake_records`.
- Split `contact_handle` into `contact_channel` + `contact_identifier` on `intake_records`.

### Backend APIs (S4-05 to S4-22)

- **Network Graph** — `GET /intelligence/graph` (seed, hops, filters → `GraphPayload`), `GET /intelligence/graph/export` (PNG/SVG), `GraphService` with spring layout for >500 nodes.
- **Taxonomy Explorer** — `GET /impact/taxonomy/sankey`, `/heatmap`, `/trend` — category flow, heatmap grid, time-series.
- **Geographic Analysis** — `GET /impact/geography` (country summary), `GET /impact/geography/{country}` (detail with records).
- **Timeline** — `GET /intelligence/timeline` (multi-track activity with period/granularity).
- **Entity Annotations** — full CRUD at `/intelligence/annotations`.
- **Entity Status** — `PUT /intelligence/entities/{type}/{value}/status` with status transitions.
- **Bulk Actions** — `POST /intelligence/entities/bulk-actions` for export/tag/status_update.

### Frontend (S4-23 to S4-38)

- **Network Graph** — canvas-based force-directed graph with seed input, hop selector, entity-type color coding, zoom, and PNG/SVG export.
- **Taxonomy Explorer** — three view modes (Sankey flow diagram, heatmap grid, trend sparklines) with period controls.
- **Geographic Heatmap** — country summary cards, ranked country list with bar chart, drill-down detail panel.
- **Timeline** — multi-track bar charts for cases/indicators/campaigns with period and granularity controls.
- **SDK types** — `GraphPayload`, `GraphNode`, `GraphEdge`, `SankeyResponse`, `HeatmapCell`, `TaxonomyTrendPoint`, `GeographySummary`, `CountryDetailResponse`, `TimelineResponse`, `AnnotationResponse`.

### Testing (S4-39 to S4-48)

- 75 backend unit tests covering graph, taxonomy, geography, timeline, annotation, entity status, and bulk action APIs.
- 15 frontend unit tests covering network graph, timeline, taxonomy explorer, and geography components.
- E2E smoke test for graph seed/expand, timeline, taxonomy, and geography views.
- Bug fixes discovered via testing: `classification` column (not `category`), `victim_country` (not `country`), `sql_schema.entity_stats` reference pattern, `GraphService` local import patch path, layout dict format.

### Documentation (S4-49 to S4-60)

- Updated TDD with Sections 14–19 (graph, taxonomy, geography, timeline, annotations, key files).
- Updated system topology with GraphService and analytics aggregation job.
- Created analyst guides: network graph, taxonomy explorer, geographic heatmap, timeline.
- Created ops runbook for graph performance monitoring.
- Created analytics aggregation cookbook.
- Updated SUMMARY.md and sample-requests.md with Sprint 4 entries.

## 2026-03-13 — TIFAP Sprint 3: Impact Analytics + Campaigns + Reports (core/ + ui/ + docs/)

Completed Sprint 3 of the Threat Intelligence & Fraud Analytics Platform (TIFAP).

### Backend APIs

- **Impact router** (`src/i4g/api/impact.py`) — 5 endpoints: KPI dashboard with vs-prior-period trends, loss-by-taxonomy treemap, detection velocity, pipeline funnel, cumulative indicators.
- **Campaign intelligence** — 6 new endpoints in `intelligence.py`: campaign list/detail/manage/timeline/graph, LEA referral suggestions.
- **Report generation** — 3 new endpoints in `reports.py`: generate (with TLP labeling), library listing, download.
- **LEA referral engine** (`src/i4g/services/lea_referral.py`) — scores entities and campaigns by loss, case count, and risk for LEA referral suggestions.
- **Export adapters** (`src/i4g/services/export_adapters.py`) — protocol-based CSV/XLSX/STIX adapters with `get_adapter()` factory.

### Report Templates

- **Executive Summary** (`templates/reports/executive_summary.md.j2`) — KPI table, loss distribution, detection velocity, pipeline throughput.
- **LEA Dossier** (`templates/reports/lea_dossier.md.j2`) — cover sheet, indicator declarations, evidence exhibits, integrity manifest.
- **Chart rendering** — `ReportChartRenderer` in `dossier_visuals.py` for PIL-based bar/line/funnel charts.
- **Chain-of-custody** — `compute_aggregate_hash()` and `hash_content()` in `dossier_signatures.py` for two-tier hashing.

### Frontend (ui/)

- **Impact Dashboard** — KPI cards, loss-by-taxonomy bar chart, detection velocity line, pipeline funnel, cumulative indicators (recharts).
- **Campaign Intelligence** — campaign list with status badges, detail page with KPI cards and timeline bar chart, entity network summary.
- **Reports** — Report Library table and Report Builder form (template, scope, TLP selector).
- **LEA suggestions** — Intelligence Dashboard shows referral suggestion cards with risk scores.
- **Navigation** — Reports section added with dossiers, library, builder sub-nav.

### Tests

- Backend: 42 tests across 6 files (impact API, TLP labeling, export adapters, LEA referral, chain-of-custody, report charts).
- Frontend: 8 component tests (impact charts, campaign timeline).

### Documentation

- TDD updated with Sprint 3 sections (impact API, campaign intelligence, report generation, export adapters).
- Data pipeline guide updated with analytics aggregation stage.
- New user guides: campaigns, impact dashboard, reports.
- Law enforcement guide updated with LEA dossier generation and chain-of-custody.
- New runbooks: intelligence dashboard, campaign management.
- Reports runbook updated with Executive Summary and LEA Dossier procedures.
- SUMMARY.md and sample-requests.md updated.

## 2026-03-12 — TIFAP Sprint 2: Core Intelligence UI (core/ + ui/)

Completed Sprint 2 of the Threat Intelligence & Fraud Analytics Platform (TIFAP).

### Backend APIs

- **Intelligence router** (`src/i4g/api/intelligence.py`) — 10 endpoints: entity list/detail/activity/neighbors, indicator list/detail, dashboard widgets, search facets. Role-based access with researcher anonymization (canonical values masked to `***` + last 4 chars).
- **Exports router** (`src/i4g/api/exports.py`) — CSV/XLSX entity and indicator exports with bank account masking for non-analyst roles. STIX 2.1 bundle export for indicators. Audit logging on every export.
- **GraphService** (`src/i4g/services/graph_service.py`) — NetworkX co-occurrence graph with `get_neighbors` (1-hop), `get_subgraph`, `detect_clusters`, `compute_layout` (spring layout for ≥500 nodes), `serialize`.
- **Role hierarchy** expanded to 5 roles: `researcher < user < analyst < leo ≤ admin`.

### Frontend (ui/)

- **Navigation restructure** — sidebar split into Intelligence (Entity Explorer, Indicator Registry, Intelligence Dashboard) and Impact (Dashboard, Search, Cases, Taxonomy, Analytics) groups.
- **Entity Explorer** — paginated table with search, filter sidebar, sort, entity detail panel with activity sparkline and co-occurrence graph.
- **Indicator Registry** — segmented list with category tabs, bulk actions, confidence filters, STIX export.
- **Intelligence Dashboard** — widget grid with entity, indicator, campaign, and platform KPI cards plus trend sparklines.
- **Global Search** — command palette (Ctrl/⌘+K) for cross-entity search.

### SDK

- 9 new methods in `@i4g/sdk`: `getEntities`, `getEntity`, `getEntityActivity`, `getEntityNeighbors`, `getIndicators`, `getIndicator`, `getDashboardWidgets`, `exportEntities`, `exportIndicators`.
- Zod schemas for all intelligence response types.

### Tests

- 4 backend test files: `test_intelligence.py` (13 tests), `test_graph_service.py` (17 tests), `test_exports.py` (8 tests), `test_role_access.py` (12 tests).
- 2 frontend unit test files: `entity-explorer.test.tsx` (8 tests), `indicator-registry.test.tsx` (9 tests).
- 1 Playwright smoke test: `intelligence-smoke.spec.ts` (5 tests).

### Documentation

- Updated: TDD, IAM, sample requests, SDK coverage, field name translation, UI architecture, API reference, analyst guide index, SUMMARY.md.
- New guides: Entity Explorer, Indicator Registry.

---

## 2026-03-12 — TIFAP Sprint 1: Data Foundation (core/ + ssi/)

Completed Sprint 1 of the Threat Intelligence & Fraud Analytics Platform (TIFAP).

### Schema & Migrations

- **7 new tables**: `threat_campaigns`, `threat_campaign_cases`, `intake_indicator_links`, `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis`.
- **3 new columns**: `cases.ingestion_batch_id`, `intake_records.loss_currency`, `intake_records.victim_country`.
- **Alembic migration** `20260312_01_add_tifap_tables` — idempotent with full downgrade support.

### Stores & Factories

- `ThreatCampaignStore` — campaign CRUD, merge, split, case linking.
- `AnalyticsStore` — read-only queries for pre-computed aggregate tables.
- `IntakeStore` — new `intake_indicator_links` methods (`link_indicator`, `get_indicator_links`, `get_intakes_for_indicator`).
- Factory functions `build_threat_campaign_store()` and `build_analytics_store()` in `services/factories.py`.

### Jobs

- **Analytics Aggregation** (`i4g jobs analytics`) — pre-computes entity_stats, indicator_stats, campaign_stats, and platform_kpis. Includes campaign risk scoring (PRD §7.5), lifecycle transitions (PRD §7.3), taxonomy rollup, and PII soft-anonymization.
- **Linkage Extraction** (`i4g jobs linkage-extract`) — LLM-driven extraction of financial indicators from intake narratives with confidence scoring. Supports `--backfill`.

### Settings

- New `AnalyticsSettings` section with `refresh_interval_minutes`, `loss_linkage_confidence_threshold`, and `campaign_risk_weights`.

### SSI Integration

- Migrated `CampaignCorrelator` to write to `threat_campaigns` / `threat_campaign_cases` instead of `cases.campaign_id`. Added table stubs to SSI's `CORE_METADATA`.

### Tests

- 43 new unit tests across 5 test files: settings (3), threat_campaign_store (9), analytics_store (7), analytics_aggregation (14), linkage_extract (10). All passing.

### Documentation

- Created TDD: `core/docs/design/threat_intelligence_analytics_tdd.md`.
- Updated `data_model.md`, `jobs.md`, `storage.md`, `dev_guide.md`.
- Updated settings manifests (`settings_manifest.yaml`, `settings_manifest.json`) and `docs/config/README.md`.

## 2026-03-11 — Terraform DRY Refactor: Stacks Pattern (infra/)

Major infrastructure refactoring merged to main. All per-environment Terraform logic
consolidated into shared stack modules (`stacks/app/`, `stacks/pii-vault/`). The
`environments/` directories are now thin wrappers (backend + tfvars only).

**What changed:**

- Created `infra/stacks/app/` — contains all app-stack logic that was previously duplicated
  between `environments/app/dev/` and `environments/app/prod/`: Cloud Run services, WIF,
  IAM bindings, Cloud SQL, storage, jobs, monitoring, and load balancer.
- Created `infra/stacks/pii-vault/` — unified vault stack (Cloud SQL, Cloud KMS, Secret Manager,
  optional vault Cloud Run service) replacing per-environment copies.
- `environments/app/{dev,prod}/` and `environments/pii-vault/{dev,prod}/` reduced to thin
  wrappers: `backend.tf`, `providers.tf`, `variables.tf`, `main.tf` (single module call),
  `outputs.tf` (passthrough), and `terraform.tfvars`.
- Deleted per-environment files: `locals.tf`, `database.tf`, `database_users.tf`, `iam_vault.tf`,
  `cloud_run.tf` (all logic now lives in the relevant stack).
- `moved.tf` files added to each environment to migrate Terraform state without destroy/recreate.
- CI updated: `stacks/**` added to path triggers in `terraform-prod.yml`.

**Documentation updated (same PR):**

- `infra/README.md` — rewrote "Repository Layout" section to describe the stacks pattern.
- `infra/docs/README.md` — fixed stale `environments/dev/` path (now `environments/app/dev/`).
- `infra/docs/iap_manual.md` — added note that IAP logic lives in `stacks/app/`, not env wrappers.
- `infra/environments/pii-vault/README.md` — noted stacks pattern and thin-wrapper role.
- `core/docs/cookbooks/github_actions_setup.md` — updated WIF edit instructions to point to
  `stacks/app/main.tf` (the unified stack) instead of old per-environment `main.tf` files.
- `core/docs/runbooks/dossiers_deployment_checklist.md` — fixed two stale path references
  (`environments/{dev,prod}/` → `environments/app/{dev,prod}/`).

**Deferred (optional cleanup):**

- Remove `moved.tf` files from all 4 environments after confirming state stability in both
  dev and prod (safe to delete once apply runs cleanly post-migration).
- Delete any `.backup/` directories from environment folders if still present.

---

## 2026-03-07 — eCX Integration: Module Wrap-Up

All three phases of the SSI–eCrimeX integration are complete and archived.
Condensed summary moved to `planning/archive/ecx_integration_summary.md`.
Plan status updated to Archived in `planning/tasks/ecx_integration_plan.md`.

**Remaining non-development items (deferred):**

- APWG data sharing agreement (required before production submissions)
- Cloud Run Job validation in `i4g-dev` (Terraform + job definitions ready)

**Pre-merge review results:**

- SSI unit tests: 925 passed, 0 failures
- Core unit tests: 908 passed, 3 skipped, 0 failures
- Pre-commit clean double-pass on both `ssi/` and `core/`
- Fixed trailing whitespace in `ssi/config/settings.dev.toml`

## 2026-03-06 — eCX Integration Final Tasks: Security, Tests, Docs, Fix Flaky Tests

Completed remaining cross-phase tasks from the eCX integration plan.

**Security fixes:**

- **CRITICAL**: Removed hardcoded eCX API key from `ssi/config/settings.dev.toml`
  (was committed to git). Key now set to `""` with comment directing to Secret
  Manager injection via `SSI_ECX__API_KEY`. Key rotation recommended since it was
  in git history.
- Verified PII cannot leak into eCX submissions — synthetic identity is
  architecturally isolated (never stored in `InvestigationResult`; wallet regex
  patterns reject non-blockchain formats).
- Verified audit trail via `ecx_submissions` table (status, timestamps, analyst,
  ecx_record_id per action).
- Verified sandbox isolation: default `base_url` is sandbox; production requires
  explicit override; double safety gate on submissions.

**Integration tests (3H):**

- Added `TestECXPollerSandbox` (5 tests): poll_phish_module, cursor persistence,
  incremental polling, auto-investigate with mock, run_poll_cycle.
- Added `TestCampaignCorrelationSandbox`: correlation with live enrichment data.
- Added `TestEndToEndSandbox`: full poll → investigate → submit cycle against
  sandbox API.

**Documentation:**

- Created `docs/config/ssi_ecx_settings_manifest.yaml` — all 19 `SSI_ECX__*`
  variables with types, defaults, descriptions, and sensitive flag.
- Created `docs/config/ssi_ecx_settings_manifest.json` — JSON equivalent.
- Updated `docs/config/README.md` — cross-reference to SSI manifest.
- Updated `docs/book/ssi/configuration.md` — added Phase 2 (submission) and
  Phase 3 (polling) settings tables.
- Created `docs/book/ssi/ecrimex-integration.md` — user guide covering
  enrichment, submission governance, polling, campaign correlation, ad-hoc queries.
- Added eCrimeX Integration to `docs/book/SUMMARY.md`.

**Flaky test fix:**

- Created `core/tests/unit/api/conftest.py` with `_clear_rate_limit_state`
  autouse fixture that clears `REQUEST_LOG` before each API test. This prevents
  rate-limit state from leaking between test files. 204 core API tests pass.

**Deferred items (operational/external):**

- 3B "Validate Cloud Run Job in i4g-dev" — deferred; requires decision on
  sandbox vs production base_url for dev environment. Poller uses cursor-based
  delta polling (not full DB pull), but org isn't ready for production data flood.
- "Secure data sharing agreement with APWG" — legal/business prerequisite for
  Phase 2 production launch.
- "Rotate eCX API key" — operational step after removing from git history.

### Files Created

- `core/tests/unit/api/conftest.py`
- `docs/config/ssi_ecx_settings_manifest.yaml`
- `docs/config/ssi_ecx_settings_manifest.json`
- `docs/book/ssi/ecrimex-integration.md`

### Files Modified

- `ssi/config/settings.dev.toml` — removed hardcoded API key
- `ssi/tests/integration/test_ecx_sandbox.py` — added polling + correlation + E2E tests
- `docs/config/README.md` — added SSI manifest reference
- `docs/book/ssi/configuration.md` — added submission + polling settings
- `docs/book/SUMMARY.md` — added eCrimeX Integration page
- `planning/tasks/ecx_integration_plan.md` — updated checkboxes

---

## 2026-03-06 — eCrimeX Integration Phase 3 — Inbound Polling + Campaign Correlation + UI [COMPLETE]

Completed Phase 3 of the eCX integration: inbound polling (3A), deployment
infrastructure (3B), campaign correlation (3C), intelligence feed UI (3E),
trend dashboard (3F), Phase 2 follow-ups (3G), and test/validation (3H).
925 SSI tests, 906 core tests, 122 UI tests pass. Pre-commit clean double-pass
on both SSI and core repos.

**3A — Alembic Migration:**

- `ecx_polling_state` table migration created in core
  (`20260306_01_add_ecx_polling_state.py`)

**3B — Deployment:**

- Terraform resources for Cloud Run Job + Cloud Scheduler in
  `infra/environments/app/dev/` (terraform.tfvars + main.tf VPC override)
- Deployment docs in `ssi/docs/tdd_ecx_integration.md` sections 11.3, 11.4, 15.2

**3C — Campaign Correlation:**

- `CampaignCorrelator` class in `ssi/src/ssi/ecx/correlation.py`
- Three strategies: wallet-based, infrastructure (IP/ASN), brand impersonation
- 22 unit tests in `ssi/tests/unit/test_ecx_correlation.py`

**3E — UI Intelligence Feed & Campaign View:**

- SSI API: `GET /ecx/feed` (browse eCX records with filters) and
  `GET /ecx/polling-status` (polling cursor state) — 9 tests
- Core API: `GET /campaigns/{campaign_id}` with linked cases
- UI proxy routes: `/api/ssi/ecx/feed`, `/api/ssi/ecx/polling-status`
- Intelligence Feed page (`/ssi/ecx-feed`) — module selector, confidence/brand
  filters, one-click Investigate, polling status banner
- Campaign detail page (`/campaigns/[id]`) — campaign info, taxonomy badges,
  linked cases timeline with risk scores
- Navigation: "Intelligence Feed" + "Trend Dashboard" under SSI nav group
- EcxEnrichmentPanel already in investigation detail Recon tab (Community Intel)
- Component tests: 9 feed tests, 9 campaign detail tests

**3F — Trend Dashboard:**

- SSI API stats endpoints: `GET /ecx/stats/phish-by-brand`,
  `GET /ecx/stats/wallet-heatmap`, `GET /ecx/stats/geo-infrastructure` — 9 tests
- Store methods: `stats_submissions_by_brand`, `stats_wallet_heatmap`,
  `stats_wallet_currency_breakdown`, `stats_geo_infrastructure`
- UI proxy routes for all three stats endpoints
- Trend Dashboard page (`/ssi/ecx-dashboard`) — Recharts: phish by brand
  line chart, wallet currency pie chart, top wallets bar chart, geo distribution
  bar chart
- 6 dashboard component tests

**3G — Phase 2 Follow-ups:**

- Submission UI component tests covered in existing test suite

### Files Created (this session)

- `ui/apps/web/src/app/(console)/campaigns/[id]/page.tsx`
- `ui/apps/web/src/app/(console)/ssi/ecx-dashboard/page.tsx`
- `ui/apps/web/src/app/api/ssi/ecx/stats/phish-by-brand/route.ts`
- `ui/apps/web/src/app/api/ssi/ecx/stats/wallet-heatmap/route.ts`
- `ui/apps/web/src/app/api/ssi/ecx/stats/geo-infrastructure/route.ts`
- `ui/apps/web/tests/unit/ecx-feed-page.test.tsx`
- `ui/apps/web/tests/unit/campaign-detail-page.test.tsx`
- `ui/apps/web/tests/unit/ecx-dashboard-page.test.tsx`
- `ssi/tests/unit/test_ecx_stats.py`

### Files Modified (this session)

- `ssi/src/ssi/api/ecx_routes.py` — stats endpoints + response models
- `ssi/src/ssi/store/scan_store.py` — stats query methods
- `core/src/i4g/services/campaigns.py` — `get_campaign_detail()` method
- `core/src/i4g/api/campaigns.py` — `GET /campaigns/{campaign_id}` endpoint
- `ui/apps/web/src/types/ssi.ts` — feed/polling types
- `ui/apps/web/src/app/(console)/navigation.tsx` — Intelligence Feed + Trend Dashboard nav items
- `planning/tasks/ecx_integration_plan.md` — Phase 3 checkboxes updated

## 2026-03-05 — eCrimeX Integration Phase 2 — UI + Integration Tests [COMPLETE]

Completed the remaining 2G (UI) and 2H (integration tests + docs) items for
Phase 2. All backend tasks (2A–2F) were already done. 855 unit tests pass.
Pre-commit clean double-pass. TypeScript type check zero errors.

**2G — Analyst Console changes:**

- **Investigation detail Results tab** — `EcxSubmissionsPanel` component added.
  Shows per-submission status badge, eCX record ID, module, confidence, submitted-by,
  submitted-at. Approve/Reject/Retract action buttons with analyst ID input for each
  queued row. Fetches from `/api/ssi/ecx/submissions?scan_id=`.
- **Investigation list** — Second filter row for eCX submission status (All / Queued /
  Submitted / Failed / Rejected). "Submissions queue" button in page header linking
  to `/ssi/submissions`. Filters compose with existing status filter.
- **Submissions queue page** (`/ssi/submissions`) — Dedicated client component with
  full submissions table, status filter pills, bulk analyst ID input, Bulk Approve /
  Bulk Reject actions using `Promise.allSettled`, per-row Approve/Reject/Retract
  buttons, selection count footer.
- **Sidebar navigation** — "Submissions" link (Upload icon) added under Scam
  Investigator children in `navigation.tsx`.
- **API proxy routes** — Four Next.js route handlers created:
  `GET /api/ssi/ecx/submissions`, `POST /api/ssi/ecx/submissions/[id]/approve|reject|retract`.
- **TypeScript types** — `EcxSubmissionStatus`, `EcxSubmission`,
  `EcxSubmissionsResponse`, `EcxApproveRequest`, `EcxRejectRequest` added to
  `ui/apps/web/src/types/ssi.ts`.
- **Backend filter** — `list_scans()` in `scan_store.py` now accepts
  `ecx_submission_status` and filters via EXISTS subquery. `list_investigations`
  FastAPI endpoint exposes this as a query param.

**2H — Integration tests + docs:**

- **Sandbox integration tests** — `TestECXSubmissionSandbox` class added to
  `ssi/tests/integration/test_ecx_sandbox.py`. Tests: `test_submit_phish_and_verify`,
  `test_submit_crypto_and_verify`, `test_update_record`, `test_add_note`,
  `test_dedup_existing`, `test_analyst_reject`, `test_retract`. All guarded by the
  dual safety-gate env var check; skip gracefully when submission is disabled or
  when eCX module access is denied.
- **Submission governance doc** — `ssi/docs/submission_governance.md` created.
  Covers: safety gates, confidence thresholds, module field mapping, submission
  lifecycle diagram, analyst approval workflow, deduplication, retraction flow,
  full env var reference table, enabling step-by-step guide, testing commands.

### Files Created (this session)

- `ssi/docs/submission_governance.md`
- `ui/apps/web/src/app/api/ssi/ecx/submissions/route.ts`
- `ui/apps/web/src/app/api/ssi/ecx/submissions/[id]/approve/route.ts`
- `ui/apps/web/src/app/api/ssi/ecx/submissions/[id]/reject/route.ts`
- `ui/apps/web/src/app/api/ssi/ecx/submissions/[id]/retract/route.ts`
- `ui/apps/web/src/app/(console)/ssi/submissions/page.tsx`

### Files Modified (this session)

- `ssi/src/ssi/store/scan_store.py` — `list_scans` + `ecx_submission_status` filter
- `ssi/src/ssi/api/investigation_routes.py` — `list_investigations` + `ecx_submission_status` query param
- `ssi/tests/integration/test_ecx_sandbox.py` — `TestECXSubmissionSandbox` class added
- `ui/apps/web/src/types/ssi.ts` — ECX submission types added
- `ui/apps/web/src/app/(console)/ssi/investigations/[id]/page.tsx` — `EcxSubmissionsPanel` + Results tab wiring
- `ui/apps/web/src/app/(console)/ssi/investigations/page.tsx` — ECX filter row + header button
- `ui/apps/web/src/app/(console)/navigation.tsx` — Submissions nav link
- `planning/tasks/ecx_integration_plan.md` — 2G/2H checkboxes updated

---

**Phase 2 wrap-up additions (this session):**

- **2A tests:** `TestECXClientSubmitMethods` added to `test_ecx.py` — mocked HTTP
  tests for `submit_phish`, `submit_crypto`, `submit_domain`, `submit_ip`,
  `add_note`, `update_record`, verifying request body construction and error handling.
- **2B tests:** `TestECXSubmissionCRUD` added to `test_scan_store.py` — create,
  update, get (not found), list (unfiltered / filtered by status / filtered by
  scan_id).
- **2C tests:** `TestFieldMapping` added to `test_ecx_submission.py` — phish brand
  and IP forwarding, crypto currency code lookup via `ecx_currency_map.json`,
  domain classification forwarding.
- **2D model + test:** `ecx_submissions: list[dict[str, Any]]` field added to
  `InvestigationResult`. `_run_ecx_submission()` in orchestrator now writes rows
  back to `result.ecx_submissions`. `TestEndToEndSubmissionFlow` added to
  `test_ecx_submission.py` covering both the populated-field path and the
  dedup-update path.
- **2E tests:** `TestAPISubmissionEndpoints` added to `test_ecx.py` — list,
  approve, reject, retract endpoints plus 503/404/400 error cases.
- **2F tests + impl:** `TestCLICommands` extended in `test_ecx.py` with submit,
  status, retract, list-submissions tests. All four CLI commands (`submit`,
  `status`, `retract`, `submissions`) written cleanly into `ecx_cmd.py` (the
  file had been corrupted by a prior session; recovered via `git stash` and
  rewritten from scratch).
- **Bug fix:** `ECXSubmissionResponse.error_message: str` changed to
  `str | None = None` to allow retract / approve paths where no error is present.
- **Bug fix:** Reject endpoint long-line refactored to satisfy ruff E501.
- **Pre-commit:** Clean double-pass — black, isort, ruff, whitespace, yaml, toml
  all passed with no modifications on second run.

**Safety design:** Both `SSI_ECX__SUBMISSION_ENABLED=true` **and**
`SSI_ECX__SUBMISSION_AGREEMENT_SIGNED=true` must be explicitly set before any
indicator data is transmitted to eCrimeX. The second flag defaults to `false` with
a loud WARNING log until the agreement is signed.

- **ECXClient submit methods (2A):** Added `submit_phish`, `submit_crypto`,
  `submit_domain`, `submit_ip`, `add_note`, `update_record` to `ECXClient` in
  `ssi/src/ssi/osint/ecrimex.py`. All use the existing `@with_retries` decorator.
- **Submissions Table (2B):** `ecx_submissions` SQLAlchemy table added to
  `ssi/src/ssi/store/sql.py` with 15 columns tracking the full submission
  lifecycle (pending → queued → submitted / updated / failed / rejected / retracted).
  Alembic migration `20260305_01_add_ecx_submissions.py` created in `core/`.
  Five CRUD methods added to `ScanStore`: `create_ecx_submission`,
  `update_ecx_submission`, `get_ecx_submission`, `list_ecx_submissions`,
  `_row_to_dict`.
- **Governance Service (2C):** New `ssi/src/ssi/ecx/` package with
  `ECXSubmissionService`. Routes indicators by confidence: `>= auto_submit_threshold`
  → auto-submit; `>= queue_threshold` → analyst review queue; below → skip.
  Deduplication checks eCX before every POST and sends a PUT update when a
  matching record already exists. Public methods: `process_investigation`,
  `analyst_approve`, `analyst_reject`, `retract`.
- **Pipeline wiring (2D):** `_run_ecx_submission()` added to
  `investigator/orchestrator.py` and called after `persist_investigation()`. Fully
  non-blocking — exceptions are caught and logged, never propagated.
- **API endpoints (2E):** Four new endpoints on `ecx_routes.py`:
  `GET /ecx/submissions`, `POST /ecx/submissions/{id}/approve|reject|retract`.
  New Pydantic models: `ECXApproveRequest`, `ECXRejectRequest`, `ECXSubmissionResponse`.
- **CLI commands (2F):** Four new sub-commands added to `ssi ecx`:
  `submit <investigation-id>`, `status <investigation-id>`,
  `retract <submission-id> --analyst`, and `submissions` (queue list).
- **Unit Tests:** 32 new tests in `tests/unit/test_ecx_submission.py` covering
  safety gates, threshold routing, deduplication, analyst approve/reject/retract,
  `_extract_confidence`, `_extract_domain`, `_extract_indicators`, and the factory.
  All 32 pass.

### Files Created

- `ssi/src/ssi/ecx/__init__.py`
- `ssi/src/ssi/ecx/submission.py`
- `ssi/tests/unit/test_ecx_submission.py`
- `core/src/i4g/migrations/versions/20260305_01_add_ecx_submissions.py`

### Files Modified

- `ssi/src/ssi/settings/config.py` — `ECXSettings`: +`submission_agreement_signed`, +`queue_threshold`
- `ssi/config/settings.default.toml` — `[ecx]`: +`submission_agreement_signed = false`, +`queue_threshold = 50`
- `ssi/src/ssi/models/ecx.py` — `ECXSubmissionRecord` expanded; +`ECXApproveRequest`, `ECXRejectRequest`, `ECXSubmissionResponse`
- `ssi/src/ssi/store/sql.py` — +`ecx_submissions` table
- `ssi/src/ssi/store/scan_store.py` — +5 CRUD methods for `ecx_submissions`
- `ssi/src/ssi/osint/ecrimex.py` — +6 Phase 2 submit methods
- `ssi/src/ssi/investigator/orchestrator.py` — +`_run_ecx_submission()` + wired call
- `ssi/src/ssi/api/ecx_routes.py` — +4 submission management endpoints
- `ssi/src/ssi/cli/ecx_cmd.py` — +4 submission CLI commands

---

## 2026-03-05 — eCrimeX Integration Phase 1 — Consume (Enrichment)

Implemented the full Phase 1 eCX integration for SSI, enabling every investigation
to be enriched with APWG community intelligence data during passive recon:

- **Settings & Models (1A):** Added `ECXSettings` Pydantic model with env-var
  overrides (`SSI_ECX__*`), `[ecx]` TOML config sections, Pydantic models for
  all 6 eCX modules (`ECXPhishRecord`, `ECXCryptoRecord`, `ECXMalDomainRecord`,
  `ECXMalIPRecord`, `ECXEnrichmentResult`, `ECXSubmissionRecord`), and
  `ecx_currency_map.json` for token symbol mapping.
- **ECXClient (1B):** Full HTTP client in `ssi/src/ssi/osint/ecrimex.py` with
  `@with_retries`, camelCase→snake_case normalisation, 5 search methods
  (phish, domain, IP, crypto, report-phishing), singleton accessor, and
  graceful degradation.
- **Enrichment Pipeline (1C):** `enrich_from_ecx()` and
  `enrich_wallets_from_ecx()` with `_safe_query()` fault isolation. Wired into
  orchestrator at two points: passive recon phase and post-wallet-extraction.
- **Cache Table (1D):** `ecx_enrichments` SQLAlchemy table added to
  `ssi/src/ssi/store/sql.py` with scan_id, query_module, and expiry indexes.
- **Cache Layer (1D):** `cache_ecx_enrichments()`, `get_ecx_enrichments()`, and
  `get_cached_ecx_enrichment()` methods added to `ScanStore`. Cache is wired into
  orchestrator after `persist_investigation()`. Configurable TTL via
  `cache_ttl_hours` setting. Expired entries filtered by `cache_expires_at > now`.
- **Report & STIX (1E):** "Community Intelligence (eCrimeX)" section added to
  `report.md.j2` with tables for all 5 modules. STIX bundle extended with
  `_add_ecx_indicators()` for phish and crypto hits with eCrimeX external
  references. Wallet manifest table now shows "eCX Status" column (Known ✓/—).
- **CLI & API (1F):** `ssi ecx search {phish|domain|ip|crypto}` CLI commands
  with Rich tables and JSON output. FastAPI router with 4 POST search endpoints
  and `GET /ecx/investigate/{scan_id}` for cached enrichment lookup.
- **Wallet Expansion (1G):** Added XLM (Stellar), XMR (Monero), ZEC (Zcash),
  XZC (Firo) regex patterns to `patterns.py`, `wallet_allowlist.json`, and
  compiled `DEFAULT_TOKEN_NETWORKS`. Reordered patterns so specific-prefix
  patterns precede the broad SOL/Base58 matcher. Expanded JS extraction patterns
  in `zen_manager.py` from 7 to 16 (LTC-bech32, BCH, ADA, ZEC, XZC, XLM, XMR,
  DASH, DOGE, LTC-legacy).
- **Unit Tests (1H):** 64 eCX tests (`test_ecx.py`) covering models, key
  normalisation, client methods, singleton, safe_query, enrichment, currency
  map, settings, cache layer, report rendering, STIX bundle, CLI commands, and
  API endpoints. Test fixtures in `tests/fixtures/ecx_responses.py`. Full suite:
  783 passed. Pre-commit hooks: clean double-pass.
- **Docs (1A):** SSI configuration docs updated with complete `SSI_ECX__*`
  env-var reference table.

### Files Created

- `ssi/src/ssi/models/ecx.py`
- `ssi/src/ssi/osint/ecrimex.py`
- `ssi/config/ecx_currency_map.json`
- `ssi/src/ssi/cli/ecx_cmd.py`
- `ssi/src/ssi/api/ecx_routes.py`
- `ssi/tests/unit/test_ecx.py`
- `ssi/tests/fixtures/ecx_responses.py`

### Files Modified

- `ssi/src/ssi/settings/config.py` — ECXSettings + ecx field + path resolution
- `ssi/config/settings.default.toml` — [ecx] section
- `ssi/config/settings.local.toml` — [ecx] section
- `ssi/src/ssi/models/investigation.py` — ecx_enrichment field
- `ssi/src/ssi/investigator/orchestrator.py` — enrichment wiring + cache persistence
- `ssi/src/ssi/store/sql.py` — ecx_enrichments table
- `ssi/src/ssi/store/scan_store.py` — cache read/write/expiry methods
- `ssi/templates/report.md.j2` — Community Intelligence section + wallet eCX status
- `ssi/src/ssi/evidence/stix.py` — \_add_ecx_indicators
- `ssi/src/ssi/cli/app.py` — ecx_app registration
- `ssi/src/ssi/api/app.py` — ecx_router registration
- `ssi/src/ssi/browser/zen_manager.py` — expanded JS wallet extraction (16 patterns)
- `ssi/src/ssi/wallet/patterns.py` — 4 new patterns + reorder
- `ssi/src/ssi/wallet/allowlist.py` — 4 new DEFAULT_TOKEN_NETWORKS
- `ssi/config/wallet_allowlist.json` — 4 new entries
- `ssi/tests/unit/test_wallet.py` — new addresses + pattern tests + count updates

## 2026-03-04 — Feedback Feature — Deploy-Ready

Completed all remaining items for the inline feedback system (Phases 1–4 already
implemented; these are the deployment-gate items):

- **Core fix:** `_get_service()` now short-circuits to `LoggingFeedbackService`
  when `I4G_ENV=local` — prevents 403 from ADC credentials lacking the Sheets
  scope during local development. `LoggingFeedbackService.submit()` raised to
  `WARNING` so output surfaces through uvicorn's default handler.
- **Settings** (`config/settings.local.toml`): Added `[feedback]` section with
  `enabled = true` and `sheet_id = ""`.
- **Tests** (`tests/unit/settings/test_feedback_settings.py`): Five tests cover
  defaults, `I4G_FEEDBACK__SHEET_ID` override, and `I4G_FEEDBACK__ENABLED`
  toggle.
- **Infra** (`infra/environments/app/{dev,prod}/main.tf`): Added
  `google_project_service.sheets` to enable `sheets.googleapis.com` in both
  environments.
- **Infra** (`infra/environments/app/{dev,prod}/terraform.tfvars`): Added
  `I4G_FEEDBACK__SHEET_ID` to `core_svc_env_vars` and
  `NEXT_PUBLIC_FEEDBACK_ENABLED = "true"` to `console_env_vars`.
- **UI** (`ui/apps/web/.env.local`): Added `NEXT_PUBLIC_FEEDBACK_ENABLED=true`.
- **Docs** (`docs/config/settings_manifest.{yaml,json}`): Added
  `feedback.enabled` and `feedback.sheet_id` entries.

**Manual steps still required before first cloud deploy:**

1. Run `terraform apply` in `infra/environments/app/dev` to enable the Sheets
   API and redeploy Cloud Run with the new env var.
2. Share the Google Sheet (`1o8iSyLtFbSxdqEtT-L7OQvSqKTealP1H8f0VZzZKTw8`)
   with `sa-app@i4g-dev.iam.gserviceaccount.com` as **Editor**.
3. Verify a feedback submission creates a row in the Sheet tab.
4. Repeat steps 1–3 for prod once dev is verified.

**Context:** Phase 8 removes the backwards-compat shim and dead code introduced during the SDK migration (Phases 2–3). All consumers use `chat_model` directly; `vertex_ai_model` is no longer needed.

**Changes:**

- `core/src/i4g/llm/client.py` — Removed `_resolve_model_name()` shim; `build_llm_client` and `_build_vertex_langchain` now use `settings.llm.chat_model` directly
- `core/src/i4g/settings/sections/ml.py` — Removed deprecated `vertex_ai_model` field (`LLM_VERTEX_AI_MODEL` / `LLM__VERTEX_AI__MODEL` env vars no longer honored)
- `core/src/i4g/settings/runtime_overrides.py` — Removed `"vertex_ai_model": None` from local-mode override dict
- `core/tests/unit/llm/test_client.py` — Removed `TestResolveModelName` class (3 tests) and `vertex_ai_model` from `_make_settings`; removed `_resolve_model_name` import
- `core/config/settings.default.toml` — Removed commented `# vertex_ai_model = ""` line
- `infra/environments/app/dev/terraform.tfvars` — `I4G_LLM__PROVIDER` changed to `"gemini"` (core-svc, ingest-job sweeper)
- `infra/environments/app/prod/terraform.tfvars` — `I4G_LLM__PROVIDER` changed to `"gemini"` (core-svc, report-job, account-job, retention-purge)
- `docs/config/settings_manifest.json` — Removed `llm.vertex_ai_model` entry
- `docs/book/config/settings.md` — Removed `llm.vertex_ai_model` row; updated provider Literal to `Literal['ollama', 'vertex_ai', 'gemini', 'mock']`

**Note (Phase 8.2):** `google-cloud-aiplatform` was already fully removed in Phase 2; no further action required.

**Tests:** 881 passed, 3 skipped (3 fewer than Phase 5 baseline — the 3 removed `TestResolveModelName` tests).

**Remaining (Phase 7 — manual cloud deployment):** Deploy Core API + SSI to `i4g-dev`, monitor 48h, then deploy to `i4g-prod`.

## 2026-03-05 — Core Pre-commit Standardization (Matches SSI Standard) — Complete

**Context:** SSI had a more robust pre-commit suite (black + isort + ruff + pre-commit-hooks). Core only had black + isort without ruff or the pre-commit-hooks suite.

**Changes:**

- `core/.pre-commit-config.yaml` — Rewritten to match SSI structure: black (frozen 26.1.0, `--line-length=120`), isort (frozen 8.0.1, `--profile=black --line-length=120`), ruff (frozen v0.15.4, `--fix`), plus trailing-whitespace, end-of-file-fixer, check-yaml, check-toml, check-added-large-files from pre-commit-hooks v6.0.0
- `core/pyproject.toml` — Added `[tool.ruff]`, `[tool.ruff.lint]`, `[tool.ruff.lint.per-file-ignores]`: rules `E/F/N/W/UP/B/SIM` selected (`I` omitted — isort is authoritative for imports to avoid isort 8.0.1 ↔ ruff I001 convergence conflict), `B008` globally ignored (FastAPI Depends idiom), per-file-ignores for tests (N806/N803) and migration/infra scripts (E501)
- 25 real ruff violations fixed: missing imports (`Settings`, `EntityStore`, `DossierPlan`, `Optional`, `Dict`, `documents`), unused variables across 7 files, duplicate test function
- 45 auto-fixes applied: UP042 StrEnum conversions, UP031 %-format → f-strings, SIM simplifications, B905/B007/B017
- 40 `# noqa` directives added for pre-existing brownfield E501/B904 violations
- B904 in `review_search.py` fixed with proper `from exc` exception chaining
- End-of-file and trailing-whitespace normalization across 80+ files

**Decision:** `I` (isort rules) excluded from ruff's select because isort 8.0.1 (pre-commit frozen) and ruff's I001 disagree on aliased same-module imports (e.g., `from i4g.store.sql import session_factory as build_sql_session_factory`), causing an infinite fix loop. isort is the single authoritative import formatter.

**Tests:** 884 passed, 3 skipped — no regressions.

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2026-02-28.md` (and before that, `archive/change_log_2025-12-14.md`).

## 2026-03-04 — Gemini Model Migration: Phases 5 & 6 (Testing + Infra) — Complete

**Context:** Phases 1–4 had already migrated Core SDK (`google-genai==1.52.0`) and updated all model strings to `gemini-2.5-flash`. Phases 5 and 6 complete the verification and infrastructure alignment.

**Phase 5 — Testing & Evaluation results:**

- Core unit tests: **884 passed, 3 skipped, 0 failures** (no regressions from SDK migration)
- Core mock smoke: `MockLLMClient.generate()` works; `google-genai` SDK imports correctly with `gemini` provider + `gemini-2.5-flash` model
- SSI unit tests: **715 passed, 0 failures** (model-string update to `gemini-2.5-flash` in Phase 3 fully validated)
- Structured output / JSON mode audited: both Core and SSI use `response_mime_type="application/json"` via `types.GenerateContentConfig` — correct `google-genai` SDK pattern, no breaking changes

**Phase 6 — Infrastructure & Config:**

- `infra/environments/app/dev/terraform.tfvars` — core-svc `I4G_LLM__CHAT_MODEL` and SSI `SSI_LLM__MODEL`: `gemini-2.0-flash` → `gemini-2.5-flash`
- `infra/environments/app/prod/terraform.tfvars` — SSI `SSI_LLM__MODEL`: `gemini-2.0-flash` → `gemini-2.5-flash`
- Docs (`settings_manifest.json`, `settings.md`) and `settings.default.toml` were already current — no further changes needed
- Phase 6.5 (quota verification in `i4g-dev`) is a manual GCP Console step remaining before deploy

**Status:** Phase 7 (deploy to `i4g-dev`) is next.

## 2026-03-04 — Gemini Model Migration: Phase 3 (Model String Updates) — Complete

**Context:** SSI still defaulted to the retiring `gemini-2.0-flash` (June 1 deadline). Phase 3 updates all model string references across SSI and Core to `gemini-2.5-flash`.

**Changes:**

- `ssi/src/ssi/llm/gemini_provider.py` — updated `GeminiProvider.__init__` default from `gemini-2.0-flash` → `gemini-2.5-flash`; updated docstring example
- `ssi/config/settings.dev.toml` — updated `model = "gemini-2.5-flash"`
- `ssi/tests/unit/test_settings.py` — updated `test_dev_profile_loads_gemini` assertion to `gemini-2.5-flash`
- `ssi/src/ssi/monitoring/__init__.py` — added `gemini-2.5-flash` cost entry (`input: $0.0003`, `output: $0.0025` per 1K tokens); kept `gemini-2.0-flash` with retirement note for historical tracking
- `core/tests/unit/llm/test_client.py` — replaced deprecated `gemini-pro` in `vertex_ai_model` override test fixture with `gemini-2.5-flash`
- `core/config/settings.default.toml` — improved `[llm]` section comment to call out `gemini-2.5-flash` as the Vertex AI target model
- `core/src/i4g/cli/bootstrap/dev/jobs.py` — confirmed already at `gemini-2.5-flash`; no change required

**Test results:** SSI — 715 passed; Core LLM tests — 12 passed; 0 failures across both.

**Next:** Phase 5 — unit + smoke testing with new SDK and model.

## 2026-03-04 — Gemini Model Migration: Phase 4 (Breaking-Change Audit) — Complete

**Context:** Phase 4 audits core and SSI for Gemini 3.x breaking changes before finalizing the `gemini-2.5-flash` migration target.

**Findings (all six items cleared — no code changes required):**

- **Top-K removal (4.1):** All `top_k` occurrences are Vertex AI Vector Search nearest-neighbor count parameters (`retriever.py`, `vertex_vector.py`, `structured.py`) — not Gemini generation sampling. Neither `client.py` (Core) nor `gemini_provider.py` (SSI) pass `top_k` to `GenerateContentConfig`. No action required.
- **Thinking parameter (4.2):** No `thinking_budget` or `thinking_level` anywhere. Not applicable.
- **Thought signatures (4.3):** Not required for `gemini-2.5-flash`. SSI passes standard `role/content` message history only. Flag for future Gemini 3 Pro+ migration.
- **PDF processing (4.4):** Core uses a dedicated OCR pipeline (`i4g.ingestion`); SSI uses Playwright browser automation. The LLM is never called with raw PDF bytes. Not applicable.
- **Temperature (4.5):** Core and SSI both default to `temperature=0.1`. The `1.0` advisory applies to Gemini 3 Pro+ only; no restriction on `gemini-2.5-flash`. No change needed now.
- **Content filter defaults (4.6):** SSI `_safety_off()` explicitly disables all four harm categories (`DANGEROUS_CONTENT`, `HARASSMENT`, `HATE_SPEECH`, `SEXUALLY_EXPLICIT`) via `HarmBlockThreshold.OFF` — valid with current `google-genai` SDK and `gemini-2.5-flash`. Core's `GenerateContentConfig` omits safety settings (uses model defaults). No changes needed. Revisit category names when migrating to Gemini 3.x.

**Decision:** No code changes required for Phase 4. All identified breaking changes are Gemini 3.x concerns; current target is `gemini-2.5-flash`. Plan updated to mark Phase 4 ✅.

## 2026-03-03 — Gemini Model Migration: Phase 2 (Core SDK Migration) — Complete

**Context:** Core used the deprecated `vertexai.generative_models` SDK (`google-cloud-aiplatform`). Phase 2 migrates to the `google-genai` unified SDK, aligning with the SSI repo which already uses it.

**Changes:**

- `core/pyproject.toml` — replaced `google-cloud-aiplatform>=1.70.0,<3.0` with `google-genai>=1.0.0,<2.0`
- `core/src/i4g/services/classifier.py` — removed `vertexai.init()` / `GenerativeModel` imports; rewrote `VertexAIClient` to use `genai.Client(vertexai=True)` and `models.generate_content()` with `types.GenerateContentConfig`
- `core/src/i4g/llm/client.py` — rewrote `_build_vertex_langchain()` to use `genai.Client`; `_VertexLangChainAdapter` now holds a `genai.Client` instance instead of `GenerativeModel`
- `core/src/i4g/settings/sections/ml.py` — added `"gemini"` as accepted `provider` value (synonym for `"vertex_ai"`); existing deployments using `I4G_LLM__PROVIDER=vertex_ai` are unaffected
- `core/requirements.txt` — regenerated via `pip-compile`; `google-cloud-aiplatform` removed, `google-genai==1.52.0` pinned
- Full unit test suite: **884 passed, 3 skipped, 0 failures**

**Next:** Phase 3 — model string updates (SSI default → `gemini-2.5-flash`, infra tfvars).

## 2026-03-03 — Phase 3C: Analyst Guidance in Cloud Mode — Complete

**Context:** With live monitoring deployed (Phase 3B), analysts can observe SSI investigations in the cloud but cannot guide them. Phase 3C adds bidirectional guidance — analysts submit commands (click, goto, type, skip, abort, etc.) through the UI, which are stored in core and polled by SSI during the investigation.

**Architecture:**

1. **Core endpoints** — `POST /events/ssi/{scan_id}/guidance` stores commands in `ssi_guidance_commands` table (Alembic `20260303_02`). `GET .../guidance/pending` returns unacknowledged commands. `POST .../guidance/{id}/ack` marks consumed. Redis pub/sub notifies on `ssi:guidance:{scan_id}`.
2. **SSI polling** — `GuidancePollRelay` (background `asyncio.Task`) continuously polls core and feeds commands into `EventBus.provide_guidance()`. `GuidancePollHandler` implements `GuidanceHandler` protocol for future `AgentController` integration. Enabled via `SSI_INTEGRATION__GUIDANCE_POLL_ENABLED=true`.
3. **UI** — Next.js proxy route at `/api/events/ssi/[scanId]/guidance`. `useInvestigationMonitor.sendGuidance()` falls back to HTTP POST in SSE/cloud mode. `/ssi` page has action dropdown, value input, reason field, and send button.
4. **Auto-continue** — `GuidancePollHandler` returns `HumanAction.CONTINUE` after 300s timeout if no analyst responds.

**Files changed (core):** `src/i4g/store/sql.py`, `src/i4g/store/ssi_events_store.py`, `src/i4g/api/ssi_events.py`, `src/i4g/migrations/versions/20260303_02_add_ssi_guidance_commands.py`, `tests/unit/test_ssi_guidance.py` (8 tests)

**Files changed (ssi):** `src/ssi/monitoring/guidance_poll_handler.py`, `src/ssi/settings/config.py`, `src/ssi/api/investigation_routes.py`, `tests/unit/test_guidance_poll.py` (8 tests)

**Files changed (ui):** `apps/web/src/app/api/events/ssi/[scanId]/guidance/route.ts`, `apps/web/src/lib/use-investigation-monitor.ts`, `apps/web/src/app/(console)/ssi/page.tsx`

## 2026-03-03 — 3B.10 Root Cause 5: WebSocket Transport Still Active in Cloud

**Context:** After deploying with `.dockerignore`, Cloud Run timeout, and SSE proxy rewrite fixes, the Live View still showed `connecting…` indefinitely (no longer going to "unavailable" — timeout fix helped). Cloud Run logs confirmed **zero** requests to `/api/events/ssi/` during the entire investigation. The hook was calling WebSocket `connect()` instead of `connectSSE()`.

**Diagnosis:** `NEXT_PUBLIC_SSI_WS_URL=ws://localhost:8100` was still baked into the deployed image despite `.dockerignore`. Docker's build cache retained the stale `COPY . .` layer from a prior build. The hook's transport decision — `if (process.env.NEXT_PUBLIC_SSI_WS_URL) connect() else connectSSE()` — always chose WebSocket. WebSocket to `ws://localhost:8100` inside a Cloud Run container fails silently (no server to connect to), keeps retrying, and produces no server-side logs.

**Fix — runtime transport selection:** Added `shouldUseWebSocket()` helper that requires **both** `NEXT_PUBLIC_SSI_WS_URL` to be set **and** `window.location.protocol !== "https:"`. In cloud (always HTTPS), this forces SSE transport regardless of whether the env var got baked in. WebSocket is now only used under HTTP (local dev). Also added `console.debug` diagnostic logging for transport selection, SSE connection, and errors.

**Files changed:**

- `ui/apps/web/src/lib/use-investigation-monitor.ts` — `shouldUseWebSocket()` guard, diagnostic logging
- `ui/apps/web/src/app/api/ssi/investigate/[id]/route.ts` — diagnostic log showing `ssi_investigation_id` from core
- `ui/apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts` — log on stream open

**Action required:** Rebuild `i4g-console` with `--no-cache` flag, then redeploy. Check browser console for `[Monitor]` logs to confirm SSE transport is selected.

## 2026-03-03 — 3B.10 SSE Proxy Rewrite: Polling Replaces Stream Proxy

**Context:** After rebuilding with `.dockerignore` and Cloud Run timeout fixes, the Live View still showed `connecting…` → `disconnected` after ~60 s. Root cause: Next.js patches global `fetch` for response caching. The SSE proxy route's `await fetch(upstream_sse_url)` buffered the entire SSE response body before resolving — but SSE streams never end, so the fetch hung until the browser's EventSource exhausted its retry budget (~60 s).

**Fix — polling approach:**

1. **Rewrote SSE proxy route** (`ui/apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts`) from a stream-proxy to a polling loop. Every 2.5 s, the route calls `GET /events/ssi/{scanId}?after={timestamp}` (short-lived JSON fetch that resolves instantly) and re-emits new events as SSE `data:` frames. Sends `: connected` comment on stream open to trigger `EventSource.onopen` immediately.

2. **Added `after` query param** to core-svc `GET /events/ssi/{scan_id}` endpoint (`core/src/i4g/api/ssi_events.py`). Accepts ISO-8601 timestamp; returns only events strictly after that time. Enables incremental polling (avoids re-sending all events every cycle).

**Why not `cache: "no-store"`?** It might work in isolation, but behaviour is fragile across Next.js versions — the patched `fetch` wrapper has changed multiple times and may re-introduce buffering. The polling approach is reliable regardless of Next.js internals: each poll is a standard short-lived JSON request.

**Files changed:**

- `ui/apps/web/src/app/api/events/ssi/[scanId]/stream/route.ts` — rewritten (stream proxy → polling loop)
- `core/src/i4g/api/ssi_events.py` — added `after` query param to `get_ssi_events()`
- `planning/tasks/ssi_case_enrichment_and_live_monitor.md` — updated 3B.10 with all 4 root causes

**Action required:** Rebuild + redeploy both `i4g-console` and `core-svc` images, then `terraform apply dev`, then re-run E2E cloud smoke.

## 2026-03-03 — 3B.10 Live View Bug Investigation: Three Root Causes Found

**Context:** After starting an investigation in dev (GCP), the Live View status badge stayed on `connecting…` then switched to `disconnected`. The Live View panel showed "not available". No errors in ssi-svc or core-svc logs.

**Root causes diagnosed and fixed:**

1. **Primary — `.env.local` bundled into Cloud Run image (no `.dockerignore`).**
   `NEXT_PUBLIC_SSI_WS_URL=ws://localhost:8100` from `.env.local` was copied into the cloud image during `docker build` because `ui/` had no `.dockerignore`. Next.js bakes `NEXT_PUBLIC_*` vars at build time, so the cloud console tried WebSocket to `localhost:8100` (immediate failure), never falling back to SSE. The `ws.onclose` retried MAX_RETRIES (10) then set state to `"disconnected"` — all client-side, no server errors.
   **Fix:** Added `ui/.dockerignore` excluding `**/.env.local` and `**/.env.*.local`.
   **Action required:** Rebuild `i4g-console` image and redeploy to dev.

2. **Secondary — Cloud Run request timeout at 300 s.**
   Both `core-svc` and `i4g-console` had `timeout_seconds = 300` (module default). Long-lived SSE streams would be cut at 5 min. Added `timeout_seconds = 3600` on both services in `dev` and `prod` `main.tf`.
   **Note:** GCP Global HTTPS LB backend services backed by Serverless NEGs do **not** support `timeoutSec` — applying it returns a 400 error. That setting only works for instance group / zonal NEG backends. The timeout for Cloud Run SSE is controlled solely by the Cloud Run service's `timeout_seconds`.

**Files changed:**

- `ui/.dockerignore` — new file (excludes `.env.local` from Docker build context)
- `infra/environments/app/dev/main.tf` — `timeout_seconds = 3600` on `run_core_svc` and `run_console`
- `infra/environments/app/prod/main.tf` — same as dev

## 2026-03-03 — Phase 3B: Cloud Live Monitoring via DB-Polled SSE

- **What changed:** Implemented end-to-end cloud live monitoring: SSI pushes events over HTTP → core persists them → SSE streams them to the browser. 3B.1–3B.9 are complete; 3B.10 (E2E cloud verification) remains.
- **Core repo:**
  - Added `ssi_events` table to `sql.py` and Alembic migration `20260302_01_add_ssi_events.py`.
  - New `SsiEventsStore` (`store/ssi_events_store.py`) with `insert_event_batch`, `get_events`, `get_latest_timestamp`.
  - New `SsiEventsRouter` (`api/ssi_events.py`): `POST /events/ssi/{scan_id}` (ingest + Redis publish), `GET /events/ssi/{scan_id}` (replay), `GET /events/ssi/{scan_id}/stream` (SSE — Redis pub/sub fan-out with DB-polling fallback).
  - Added `RedisSettings` (`REDIS__URL`, `REDIS__CHANNEL_PREFIX`, `REDIS__POLL_INTERVAL_SECONDS`) and `SsiSettings.events_endpoint` to settings.
  - New factory `build_ssi_events_store()` in `services/factories.py`.
  - Router registered in `api/app.py`.
  - Tests: `tests/unit/test_ssi_events.py` (6 passed, 2 skipped for auth-env dependency).
- **SSI repo:**
  - New `HttpEventSink` (`monitoring/http_event_sink.py`): batches events, throttles screenshots (configurable interval), JPEG-compresses via Pillow, POSTs to core with bearer token or Google OIDC auth.
  - Added `IntegrationSettings.push_events_to_core` (`SSI_INTEGRATION__PUSH_EVENTS_TO_CORE`) and `screenshot_interval_seconds`.
  - Wired `HttpEventSink` into `trigger_investigate` and `_run_investigation` (flush on teardown).
  - Tests: `tests/unit/test_http_event_sink.py` (13 passed).
- **UI repo:**
  - New SSE proxy route `app/api/events/ssi/[scanId]/stream/route.ts` — streams core `/events/ssi/{scanId}/stream` with proper `text/event-stream` headers, `X-Accel-Buffering: no`, IAP auth via `getIapHeaders`.
  - `useInvestigationMonitor` extended with dual-transport support: WebSocket when `NEXT_PUBLIC_SSI_WS_URL` is set, SSE via EventSource when absent. Added `transport` to hook return type.
  - `LiveMonitorTab` on `/ssi/investigations/[id]` now shows `ReplayPanel` for completed/failed scans (fetches `GET /api/events/ssi/{scanId}`, renders final JPEG screenshot and reverse-chronological event log). `LiveMonitorContent` is only mounted for running/pending scans so no WS connection opens unnecessarily.

## 2026-03-02 — Phase 3A: Live Monitor on Investigate Page

- **What changed:** Embedded a read-only Live View panel on the `/ssi` investigate page, showing live screenshots and an event log during active/full investigations. Previously, live monitoring required navigating to a separate `/ssi/investigations/[id]` page.
- **SSI repo:** Added `emit_sync()` to `EventBus` for sync→async bridging from background threads. Wired `EventBus` through `trigger_investigate` → `_run_investigation` → `run_investigation` → `BrowserAgent`. Orchestrator emits state changes, screenshot updates, wallet findings, and completion/error events at each investigation phase. `BrowserAgent` gained a `step_callback` for per-step screenshot streaming. Pre-creates scan rows in `trigger_investigate` so the poll proxy works immediately.
- **Core repo:** Deduplicated `report.pdf` from artifacts list (prominent "Investigation Report (PDF)" entry covers it). Added `?action=inline` to SSI report URL. Evidence download serves images/PDFs/text inline instead of forcing downloads. Evidence bundle preserves subdirectory structure from `title` column.
- **UI repo:** Added Live View toggle panel on `/ssi` with screenshot display, status badge, and reverse-chronological event log. `useInvestigationMonitor` gained exponential-backoff retry (up to 10 attempts) and React Strict Mode guards. Poll proxy rewired to query SSI's `/investigations/{id}` endpoint and surface `ssi_investigation_id` during running status. Guidance controls on `/ssi/investigations/[id]` disabled when disconnected.
- **Tests:** Core 868 passed (1 skipped), SSI 723 passed. Fixed `test_ssi_pdf_report_artifact` to match new `?action=inline` URL.

## 2026-03-02 — 3.0.12b: Rename `fastapi`/`fastapi-gateway` → `core-svc`

- **What changed:** Renamed all deployment artifact references from `fastapi`/`fastapi-gateway` to `core-svc` across the entire workspace. The FastAPI Python framework is unchanged — only the Cloud Run service name, Docker image name, Dockerfile name, Terraform variables/modules, CI matrix entries, and documentation labels were updated.
- **Core repo:** Renamed `docker/fastapi.Dockerfile` → `docker/core-svc.Dockerfile`. Updated CI workflow matrix (`fastapi` → `core-svc`). Changed default URLs in `SmokeSettings` and `DEFAULT_SMOKE_API_URL` from `fastapi-gateway-*` to `core-svc-*`. Updated `clean_cloud_run_history.sh`. Renamed `FASTAPI_BASE` → `CORE_API_BASE` in all runbooks/cookbooks. Updated architecture.md Mermaid diagrams, iam.md service matrix, dev_guide.md build examples, settings manifests.
- **Infra repo (dev + prod):** Renamed all `fastapi_*` Terraform variables → `core_svc_*` (`core_svc_image`, `core_svc_env_vars`, `core_svc_secret_env_vars`, `core_svc_invoker_member(s)`, `core_svc_custom_domain`). Renamed module `run_fastapi` → `run_core_svc`, locals/outputs. Updated `name = "core-svc"` (was `"fastapi-gateway"`), image path `applications/core-svc:*`, labels `service = "core-svc"`. Updated IAP OAuth refs (`iap-core-svc`). Updated all docs/READMEs, scripts, bootstrap.
- **Docs repo:** Updated system-topology and security-model Mermaid diagrams, SVGs, settings manifests, secrets-reference, CLI guide. Replaced `FastAPI Gateway` labels with `Core API (core-svc)`.
- **UI repo:** Updated `deployment-guide.md` — `I4G_API_URL` default, env var descriptions.
- **SSI repo:** Updated `api_reference.md` — `core FastAPI gateway` → `Core API (core-svc)`.
- **All repos:** Updated `.github/copilot-instructions.md` Docker Build Reference section (`fastapi` → `core-svc`).
- **Note:** Terraform `name` change on the Cloud Run Service triggers a destroy+recreate. Apply requires coordinating DNS/domain mapping, IAP backend, and UI `I4G_API_URL` in the same apply. Consider blue-green approach.

## 2026-03-02 — 3.0.12: Remove ssi-job, Service-Only Cutover (code complete)

- **What changed:** Eliminated the `ssi-investigate` Cloud Run Job, `ssi_job.mode` toggle, and all `SSI_JOB__*` / `I4G_SSI_JOB__*` env vars. SSI investigations now run exclusively via the `ssi-svc` Cloud Run Service (`POST /trigger/investigate` and `POST /trigger/batch`).
- **SSI repo:** Removed `jobs.py`, `batch_jobs.py`, `job_routes.py`, `ssi-job.Dockerfile`. Rewrote CLI (`job.py`) for in-process orchestrator. Added `investigation_routes.py` with `/trigger/investigate` and `/trigger/batch` endpoints. Consolidated to single `Dockerfile`. 723 tests pass.
- **Core repo:** Removed `_trigger_cloud_run_job()`, `_trigger_local_investigation()`, and mode branching from `investigations.py`. Renamed `SsiJobSettings` → `SsiSettings`, `settings.ssi_job` → `settings.ssi`. Updated endpoint to `/trigger/investigate`. Removed job-only fields (`job_name`, `project`, `region`, `service_account`). 868 tests pass.
- **Infra repo (dev + prod):** Removed `ssi_investigate` job block from `terraform.tfvars` (image, env vars, secrets). Replaced `I4G_SSI_JOB__MODE` + `I4G_SSI_JOB__SERVICE_URL` with `I4G_SSI__SERVICE_URL` in gateway config. Renamed `SSI_JOB__PUSH_TO_CORE` → `SSI_INTEGRATION__PUSH_TO_CORE`, removed `SSI_JOB__SCAN_TYPE`. Set `ssi_service_enabled` default to `true`.
- **Docs repo:** Updated all config manifests (`settings_manifest.json`, `settings_manifest.yaml`, `settings.md`, `settings.yaml`), SSI docs (`getting-started.md`, `README.md`, `configuration.md`), API docs, and system topology Mermaid diagram. Cloud Run Jobs count updated from 8 to 7.
- **UI repo:** Verified clean — no `ssi_job`/`SSI_JOB`/`ssi-job` references.
- **Env var mapping note:** `SSI_JOB__PUSH_TO_CORE` maps to `SSI_INTEGRATION__PUSH_TO_CORE` (lives in SSI's `IntegrationSettings` with `env_prefix="SSI_INTEGRATION__"`). `SSI_JOB__SCAN_TYPE` removed entirely — `scan_type` is per-investigation, not a global setting.
- **Remaining:** Terraform plan + apply (3.0.12ae), E2E validation (3.0.12an–ao), GCP job resource deletion (3.0.12ap).

## 2026-02-28 — SSI Cases Pipeline: Enrichment + Backfill

- **Issue 1 (Feb 27→28 case gap):** Analysis complete. Cases created Feb 27 came from a Docker image built from an uncommitted working tree that had a temporary `push_to_core` fix. Feb 28 Phase F commits reverted to broken CLI envvar behavior. The working tree fix (`_create_case_direct`, no gate) restored case creation Mar 1. No code change needed — the prior session's fix (default `push_to_core="true"` + `SSI_JOB__PUSH_TO_CORE` envvar) resolves this going forward.
- **Issue 2 (dead env var):** Fixed. Replaced `SSI_INTEGRATION__PUSH_TO_CORE` with `SSI_JOB__PUSH_TO_CORE = "true"` in both `infra/environments/app/dev/terraform.tfvars` and `infra/environments/app/prod/terraform.tfvars`. The old env var targeted the deprecated `IntegrationSettings` Pydantic section; no code read it on the direct-DB path.
- **Issue 3 (empty timeline/artifacts):** Implemented. `ScanStore.create_case_record()` now inserts `review_actions` (timeline) and `source_documents` (artifacts) rows alongside cases/scam_records/review_queue. Two new helper methods: `_insert_timeline_events()` (6 event types matching the legacy HTTP bridge reference) and `_insert_evidence_documents()` (chain-of-custody aware, GCS URI construction, MIME type mapping, fallback for known files). Table definitions for `review_actions` and `source_documents` added to `ssi/src/ssi/store/sql.py` under `CORE_METADATA`.
- **Tests:** 13 new tests in `ssi/tests/unit/test_case_enrichment.py` — all pass. 34 existing scan_store tests still pass.
- **Backfill:** Linked 14 orphaned `site_scans` rows to their corresponding cases by matching `site_scans.metadata->>'investigation_id'` to `cases.metadata->>'ssi_investigation_id'`. 15 total linked scans (14 backfilled + 1 from direct DB path). 17 remaining orphans are scans without cases (pre-integration or failed runs).
- **Files changed:** `ssi/src/ssi/store/scan_store.py` (enrichment methods), `ssi/src/ssi/store/sql.py` (table defs), `infra/environments/app/dev/terraform.tfvars`, `infra/environments/app/prod/terraform.tfvars`, `ssi/tests/unit/test_case_enrichment.py` (new).

## 2026-02-28 — SSI API Consolidation: Complete (All Phases Done)

- **Phase H — Validation & Cloud Smoke Test:** Deployed to `i4g-dev` and passed full smoke test checklist.
  - **H.1 Deploy:** Terraform applied (0 add, 2 change, 0 destroy — scaling drift only). Built and deployed `fastapi:dev` (gateway rev `00168-kdv`), `ssi-job:dev`, and `i4g-console:dev` (rev `00113-7j4`).
  - **H.2 Smoke test:** All endpoints verified via IAP-authenticated curl: investigation trigger (HTTP 202 → Cloud Run Job), task polling (`running` → `completed`, 39.52s), history (latest scan appears), detail (camelCase keys, wallets/PII/agent data), evidence bundle (307 → GCS signed URL), report PDF (307 → GCS signed URL), wallet search (200, cross-scan dedup). Case back-reference N/A (benign test site, no case created).
- **Post-merge items:** Orchestrator `investigation_id` skip-create test added (`ssi/tests/unit/test_orchestrator.py`, 3 tests, SSI 720 passed). Prod terraform plan verified clean (0 add, 1 change, 0 destroy — no `ssi-api` resources).
- **Consolidation status:** All 8 phases complete. SSI API fully merged into the FastAPI gateway. Single gateway (19 routers), single Cloud SQL database, one Cloud Run Job.

## 2026-02-28 — SSI API Consolidation: Phase F Complete, A Done, H Validated (earlier)

- **Phase F — Infrastructure Decommission:** Staged rollout complete. The standalone `ssi-api` Cloud Run Service has been deleted. All SSI traffic now routes through the FastAPI gateway. Terraform changes applied: removed `module "run_ssi_api"`, `ssi-api` IAP binding, `sa-ssi` IAP access, and `ssi_api_*` variables. `ssi-api` Artifact Registry images cleaned up. `ssi/docker/ssi-api.Dockerfile` deleted. SSI's `scripts/build_image.sh` updated to remove `ssi-api` references.
- **Task status tracking:** Refactored from HTTP callback (`TaskStatusReporter`) to shared database polling. Core pre-creates a `site_scans` row before launching the SSI Cloud Run Job; the job writes status updates directly to the shared Cloud SQL database; the `GET /tasks/{task_id}` endpoint polls the scan row for completion. This eliminates the OIDC authentication dance between SSI Job and core gateway.
- **Architecture:** Single gateway (19 routers), single Cloud SQL database, one Cloud Run Job (`ssi-investigate`). No `ssi-api` service in production.
- **Phase A — Documentation:** Complete. Updated system topology Mermaid diagram (19 routers, 8 Cloud Run Jobs, SSI Job node), API README with 13 SSI endpoint reference, SSI docs (deployment note, getting-started architecture note, configuration shared DB docs, live-monitoring WebSocket availability note), and settings manifest (12 `ssi_job` entries).
- **Phase H — Validation:**
  - Core tests: **850 passed**, 1 skipped. SSI tests: **717 passed**. UI type-check: 0 errors.
  - Bootstrap local reset: 7,086 cases, 7,532 source documents, all SSI tables created (site_scans, harvested_wallets, agent_sessions, pii_exposures), verify.json + verify.md generated.
  - SSI CLI local dev: `ssi investigate list` confirmed working with local store.
  - H.1/H.2 (deploy to `i4g-dev` + cloud smoke tests): deferred to next deploy cycle.

## 2026-02-26 — SSI API Consolidation: Phases D, E, G (pre-merge)

- **Phase D — UI Simplification:** Removed dual-backend proxy layer. All 4 data routes (`investigations`, `investigations/[id]`, `wallets`, `report/[id]`) now go through core via `apiFetch()`. Only 2 trigger+poll routes (`investigate`, `investigate/[id]`) retain `SSI_API_URL` conditional for local dev (core subprocess can't update in-memory task status). Removed `backend` field from response types. Updated `page.tsx` with case link, scanId tracking, queued status support, and risk score fallback chain.
- **Phase D — Types:** `ssi.ts` updated — `InvestigationResult` gets `ssi_investigation_id`, `case_id`, `pdf_report_path` fields. `InvestigationDetailResponse` uses camelCase top-level keys (`piiExposures`, `agentActions`) matching core's `CamelModel` output.
- **Phase E — WebSocket Decision:** Option B selected — defer WebSocket/SSE live monitoring to CLI/local-dev. Task polling via `GET /tasks/{task_id}` provides adequate production UX.
- **Phase G — Shared Database:** SSI now writes directly to core's SQLite DB in local dev via `SSI_STORAGE__DB_URL`. `build_engine()` in `ssi/store/sql.py` supports `db_url` override. Removed `download_report_pdf` workaround from SSI API. One-time data migration script at `ssi/scripts/migrate_to_core_db.py`.
- **Phase C.4 — Playbook Router:** `core/src/i4g/api/ssi_playbooks.py` — 6 endpoints (list, detail, create, update, delete, test-match) under `/playbooks/ssi`. File-based storage via `settings.ssi_job.playbook_dir` (env: `SSI_PLAYBOOK_DIR`). 27 tests in `tests/unit/api/test_ssi_playbooks.py`. Self-contained models (no SSI imports). Path resolution added to `runtime_overrides.py`.
- **Cleanup:** `.coverage` removed from git tracking, added to `.gitignore`. Orchestrator `scan_id` passthrough so DB record and result object share the same ID.
- **Tests:** Core 842 passed (1 skipped), SSI 717 passed. UI `tsc --noEmit` zero errors.

## 2026-02-26 — Phase B + C: SSI Database Schema & Endpoint Migration

- **`SsiStore` data access layer (`core/src/i4g/store/ssi_store.py`):** Full CRUD layer for the four SSI tables (`site_scans`, `harvested_wallets`, `agent_sessions`, `pii_exposures`) in core's Alembic-managed database. Mirrors `ssi.store.ScanStore` public API. Supports SQLite (local) and Cloud SQL backends via `build_ssi_store()` factory in `core/src/i4g/services/factories.py`.
- **Investigation history & detail (`core/src/i4g/api/ssi_investigations.py`):** 3 endpoints — `GET /investigations/ssi/history` (paginated, filterable), `GET /investigations/ssi/active` (stub), `GET /investigations/ssi/{scan_id}` (full detail with wallets, PII, agent actions).
- **Wallet search & export (`core/src/i4g/api/ssi_wallets.py`):** 3 endpoints — `GET /investigations/ssi/wallets` (cross-scan search with dedup), `GET /investigations/ssi/{scan_id}/wallets.csv`, `GET /investigations/ssi/{scan_id}/wallets.xlsx` (optional `openpyxl` dep).
- **Evidence & report downloads (`core/src/i4g/api/ssi_evidence.py`):** 3 endpoints — evidence-bundle, lea-package, report.pdf. GCS signed URL redirect for cloud, local file serving for dev.
- **Router registration order:** Wallet/evidence routers registered before `ssi_investigations` in `app.py` so static paths (`/wallets`, `/*.csv`) resolve before the `{scan_id}` catch-all. The old `GET /investigations/ssi/{task_id}` convenience alias is now shadowed; use `GET /tasks/{task_id}` for task polling.
- **Alembic migration:** `20260221_01_add_ssi_scan_tables.py` — 4 tables with idempotent guards, FKs to `cases.case_id`, and indexes on domain/status/address/token.
- **Tests:** 815 passed, 1 skipped, 0 failures. 41 store tests + 35 endpoint tests covering all new code. Phase C.4 (playbook router) deferred to next sprint.

## 2026-02-25 — Phase 3A: SSI Platform Integration (API & Triggering)

- **Core API trigger (`POST /investigations/ssi`):** New endpoint triggers SSI Cloud Run Jobs from the analyst console. Returns a task ID for polling via `GET /tasks/{task_id}`. Supports `scanType` (passive/active/full), `pushToCore`, `triggerDossier`, and `dataset` parameters. Local-dev mode fires a subprocess instead.
- **SSI `TaskStatusReporter`:** New `ssi/src/ssi/worker/task_reporter.py` posts progress updates from the SSI Cloud Run Job back to core's `TASK_STATUS` API. Uses dual-auth (OIDC + API key). No-ops when env vars absent (standalone mode).
- **`SsiJobSettings`:** New settings section in `core/src/i4g/settings/sections/jobs.py` with `job_name`, `project`, `region`, `service_account`, `core_api_url`. Override via `I4G_SSI_JOB__*` env vars.
- **Pre-merge review applied:** Fixed silent test-pass guard (critical), removed getattr chain with redundant defaults, broadened subprocess error handling to `OSError`, added `SsiInvestigationStatusResponse` model, replaced settings singleton mutation with `monkeypatch`.
- **Tests:** 738 core + 717 SSI = 1,455 passed, 0 failures.

## 2026-02-25 — IAP JWT Fix, WHOIS Hardening, SSI VPC Egress

- **IAP backend-service audience (core):** Added `settings.identity.iap_backend_audience` (`I4G_IDENTITY__IAP_BACKEND_AUDIENCE`) to `IdentitySettings`. `_verify_iap_jwt(is_iap_assertion=True)` now uses this value instead of the OAuth client ID for IAP assertion verification. This fixes the "IAP JWT present but verification failed" warning — IAP assertions carry `aud = /projects/PROJECT_NUMBER/global/backendServices/BACKEND_ID` which never matched the OAuth client ID. Bearer-path (step 3) failure logging promoted from DEBUG → WARNING for visibility. Terraform dynamically computes the audience from `module.global_lb.backend_service_ids["api"]`. New LB module output `backend_service_ids` exposes numeric IDs. 2 new unit tests added.
- **SSI VPC connector + Cloud NAT (infra):** Wired `google_vpc_access_connector.serverless` to `run_ssi_api` module and added `ssi_investigate` to `run_job_vpc_connector_overrides`. All SSI egress now routes through Cloud NAT with a static IP, fixing WHOIS port-43 connection resets and RDAP 403s caused by Cloud Run's shared egress IPs being blocked/rate-limited.
- **WHOIS non-fatal fallback (SSI):** `lookup_whois()` no longer raises `RuntimeError` when both WHOIS and RDAP fail. Returns an empty `WHOISRecord` with the domain populated. Improved logging messages include Cloud Run egress context to aid diagnosis.
- **ipinfo.io API key:** Already fully wired — `OSINTSettings.ipinfo_token` → `SSI_OSINT__IPINFO_TOKEN` → Secret Manager `ssi-ipinfo-token` → both `ssi_api_secret_env_vars` and `ssi_investigate` secret_env_vars. Secret value populated via `gcloud secrets versions add`. Added unit test for `ipinfo_token` env var override.
- **Tests:** 39 core settings tests pass (2 new); 3 SSI OSINT settings tests pass (1 new). No regressions.

## 2026-02-25 — SSI Dev: Persistence & OSINT Error Handling Fixes

- **ScanStore auto-create on PostgreSQL:** `ScanStore.__init__()` now checks for missing tables on PostgreSQL and runs `METADATA.create_all(checkfirst=True)` as a fallback when Alembic migration `20260221_01` hasn't been applied. Logs a clear warning pointing to the migration. Prevents silent data loss where `scan_store` was set to `None` in the orchestrator.
- **Orchestrator NXDOMAIN gating:** DNS, SSL, GeoIP, and urlscan.io OSINT calls are now skipped when `_check_domain_resolution()` returns `False`. Previously, these were called regardless, producing noisy errors (e.g., `SSL connection failed for frost-treasuryconnect.com: [Errno -2] Name or service not known`) and wasting API calls to urlscan.io (which returned HTTP 400 for unresolvable domains).
- **urlscan.io retry policy:** Changed `@with_retries` to only retry on `httpx.TransportError` (transport-level failures). HTTP 4xx client errors (like 400 Bad Request) are no longer retried. The error handler now logs the response body for 4xx to aid debugging.
- **SSL inspection:** Added specific `socket.gaierror` handling so DNS resolution failures are logged as "inspection skipped" rather than "connection failed". Removed `OSError` from retryable exceptions to avoid retrying DNS failures.
- **Agent session persistence:** `persist_investigation()` now bulk-inserts agent steps from `result.agent_steps` into the `agent_sessions` table. Previously only wallets and PII exposures were persisted; agent browser-interaction steps were silently dropped, leaving `agent_sessions` empty. Also wired `site_result = agent_session` in the orchestrator so the `active_result` JSON column on `site_scans` is populated after Phase 2.
- **AgentSession UUID serialization:** `AgentSession.to_dict()` now converts `UUID` and `Enum` fields to strings via a custom `dict_factory`. Previously, `dataclasses.asdict()` returned raw `UUID` objects which caused `TypeError: Object of type UUID is not JSON serializable` when SQLAlchemy tried to store the `active_result` JSON column, failing `persist_investigation()`.
- **Core evidence upload endpoint:** Fixed `upload_evidence()` in `core/src/i4g/api/evidence.py` — was calling `evidence.store(storage_key, content)` but `EvidenceStorage` has no `store` method. Changed to `evidence.save(intake_id=case_id, file_name=file_name, data=content, content_type=mime_type)` and now uses the returned `StoredAttachment.storage_uri` and `checksum_sha256` for the `source_documents` row. This was the root cause of all "Failed to attach … 500 Internal Server Error" messages in SSI logs.
- **Tests:** 705 SSI + 18 core evidence/case-write tests pass, zero failures.

## 2026-02-25 — IAP JWT Audience Mismatch Investigation

- **Finding:** The "IAP JWT present but verification failed" warning in `fastapi-gateway` logs is caused by an audience format mismatch, **not** a misconfigured env var. All OIDC audience env vars (`I4G_IDENTITY__AUDIENCE`, `SSI_INTEGRATION__IAP_AUDIENCE`, `I4G_IAP_CLIENT_ID`) correctly point to the OAuth client ID.
- **Root cause:** The IAP-signed JWT assertion (`X-Goog-IAP-JWT-Assertion`) injected by the LB has `aud = /projects/PROJECT_NUMBER/global/backendServices/BACKEND_SERVICE_ID`. Core's `_verify_iap_jwt(is_iap_assertion=True)` checks against `settings.identity.audience` (= OAuth client ID). Different formats → always fails. This affects all callers through the LB (UI and SSI alike).
- **Current behavior:** Auth falls through to API key (step 4 in `require_token`), so requests authenticate — but caller identity is lost (`"service"` instead of the SA email).
- **Fix (task 3.3):** Add `settings.identity.iap_backend_audience` for the backend-service audience string; use it in `_verify_iap_jwt(is_iap_assertion=True)`. No SSI changes needed. Promote Bearer-path (step 3) failure logging from DEBUG → WARNING to confirm whether step 3 also fails.
- **SQL 500 fix:** The `prefix_with("OR IGNORE")` issue was already resolved in the working tree and is included in this session's commits.

## 2026-02-25 — SSI Dev Deployment Fixes: OIDC Auth + CloudSQL Backend

- **Legacy HTTP bridge OIDC auth:** Added `_get_oidc_token()` helper (follows `core/worker/jobs/intake.py` pattern) and `_build_auth_headers()` method. The legacy HTTP bridge now injects an OIDC identity token as `Authorization: Bearer` when the target `core_api_url` is HTTPS. This allows the SSI Cloud Run service to authenticate to the core API behind IAP.
- **CloudSQL backend for ScanStore:** Extended `build_engine()` in `ssi/store/sql.py` to support `storage.backend = "cloudsql"`. Uses `google.cloud.sql.connector.Connector` with pg8000 and IAM auth — same pattern as core. New `_build_cloudsql_engine()` factory reads `cloudsql_instance`, `cloudsql_database`, `cloudsql_user`, `cloudsql_enable_iam_auth` from `StorageSettings`.
- **StorageSettings expanded:** Added `cloudsql_instance`, `cloudsql_database`, `cloudsql_user`, `cloudsql_password`, `cloudsql_enable_iam_auth` fields (env prefix `SSI_STORAGE__`).
- **Dev settings updated:** `config/settings.dev.toml` changed `storage.backend` from `"sqlite"` to `"cloudsql"` and `integration.push_to_core` from `false` to `true`.
- **Infra (dev):** Added `SSI_STORAGE__CLOUDSQL_*` env vars to `ssi_api_env_vars` in `terraform.tfvars`. Granted `roles/cloudsql.client` and `roles/cloudsql.instanceUser` to the SSI service account.
- **Root causes:** (1) Cases not showing on `/cases` page: the legacy HTTP bridge sent plain HTTP to IAP-protected core API → 403. (2) Investigation history lost on restart: ScanStore used ephemeral SQLite on Cloud Run's filesystem.
- **Tests:** 724 core + 701 SSI unit tests pass.

## 2026-02-24 — SSI Phase 2: Production Readiness (2.1–2.4)

- **2.1 Evidence delivery:** Added `GET /investigations/{id}/evidence-bundle` (ZIP download) and `GET /investigations/{id}/lea-package` (LEA-ready signed ZIP with chain-of-custody manifest). GCS-backed storage returns signed URL redirects; local falls back to direct file serving.
- **2.2 GCS evidence upload:** New `EvidenceStorageClient` in `ssi/evidence/storage.py` with local and GCS backends. Orchestrator uploads evidence directory to GCS after packaging when `SSI_EVIDENCE__STORAGE_BACKEND=gcs`. Factory function `build_evidence_storage_client()` reads from settings.
- **2.3 Core case creation (end-to-end):** Added `POST /cases`, `PATCH /cases/{id}`, `POST /cases/{id}/entities/batch`, `POST /cases/{id}/indicators/batch`, and `POST /cases/{id}/evidence` to core API. The SSI integration bridge creates a case, attaches evidence, stores classification, and creates entity/indicator records. Cases now write to both `cases` and `scam_records` tables so the dashboard join works. Descriptive case titles built from URL domain + taxonomy intent (e.g., "Investment Scam — example.com"). `push_to_core` defaults to `True`.
- **2.4 Redis task store:** Replaced in-memory `_TASKS` dict with pluggable `TaskStore` (in-memory or Redis). New `TaskStoreSettings` with `SSI_TASK_STORE__BACKEND`, `SSI_TASK_STORE__REDIS_URL`, `SSI_TASK_STORE__KEY_PREFIX`, `SSI_TASK_STORE__DEFAULT_TTL_SECONDS` env vars. Singleton factory `build_task_store()`.
- **Bug fixes:** Fixed camelCase key mismatch in the SSI integration bridge (`caseId` vs `case_id`); fixed test DB isolation (test file rewrote with `monkeypatch` + `tmp_path`); added GDPR export/delete endpoints to core cases router.
- **Tests:** 724 core unit tests pass (1 skipped); 701 SSI unit tests pass. 11 new tests for case write endpoints; 11 new tests for task store.

## 2026-02-22 — SSI: Phase 8 Complete — Testing, Hardening & Documentation

- **8A Testing:** Created HTML test fixtures (`tests/fixtures/scam_sites/`), expanded `conftest.py` with shared fixtures + custom markers. Added 24 integration tests across 3 files: `test_e2e_pipeline.py` (4 tests — full pipeline, scan store persistence, NXDOMAIN graceful degradation, full scan type), `test_api_integration.py` (8 tests — health, submit, status, task tracking), `test_wallet_extraction.py` (12 tests — BTC/ETH/TRX/SOL extraction, no false positives, validator API). All 575 existing unit tests preserved.
- **8B Hardening:** `BudgetExceededError` and `ConcurrentLimitError` exceptions in `ssi/exceptions.py`. `CostTracker.check_budget()` with budget gates between investigation phases (partial results preserved on budget exceeded). Concurrent investigation limit in API routes (thread-safe counter, HTTP 429, configurable `max_concurrent_investigations`). `RetryingLLMProvider` in `ssi/llm/retry.py` (exponential backoff, retryable HTTP 429/5xx). `@with_retries` decorator in `ssi/osint/__init__.py` applied to all OSINT modules. Security audit: sanitized API error responses (no internal details), log messages use `type(exc).__name__`. 14 hardening-specific tests in `test_phase8b_hardening.py`.
- **8C Documentation:** Updated `architecture.md` (system diagram, wallet extraction phase, hardening section). Updated `developer_guide.md` (project tree, key entry points, integration tests, hardening section, Playwright→zendriver). Created `playbook_authoring.md` (schema, step types, templates, URL matching, testing). Created `batch_scheduling.md` (campaign runner, Cloud Run Jobs, Cloud Scheduler, API batch, cost/concurrency). Created `api_reference.md` (all endpoints, request/response schemas, 429 handling, status values). GitBook SSI section (10 pages) done in prior session.
- **Test suite:** 599 tests pass (575 unit + 24 integration).
- **Files changed:** `ssi/{src/ssi/{exceptions.py, monitoring/__init__.py, investigator/orchestrator.py, settings/config.py, api/routes.py, llm/{retry.py, factory.py}, osint/{__init__.py, dns_lookup.py, ssl_inspect.py, geoip_lookup.py, virustotal.py, urlscan.py}}, tests/{conftest.py, integration/{test_e2e_pipeline.py, test_api_integration.py, test_wallet_extraction.py}, unit/test_phase8b_hardening.py, fixtures/scam_sites/{register.html, deposit.html, phishing.html}}, docs/{architecture.md, developer_guide.md, playbook_authoring.md, batch_scheduling.md, api_reference.md}}`, `planning/ssi-awh/04_roadmap.md`.

## 2026-02-22 — SSI: Phase 7 Complete — Evidence & Reporting Enhancements

- **PDF evidence appendices (A–F):** PDF reports now embed all text-based evidence artifacts as appendix pages with bidirectional anchor links. Appendix A: Screenshot, B: DOM Snapshot, C: Investigation JSON (`model_dump` minus bulky fields, capped 300 lines), D: Network Activity (HAR summary — stats table, domain breakdown, first 30 requests), E: Wallet Manifest (re-generated from model data at render time), F: STIX 2.1 IOC Bundle. Each appendix has `page-break-before`, stable `id` anchor, and "↑ Back to Evidence Artifacts" back-link.
- **Template link fixes:** Page Analysis screenshot changed from plain-text `screenshot.png` to `[screenshot.png](#appendix-screenshot)`. Evidence Artifacts table now links every row to its appendix; Investigation Summary always shown (removed stale `report_path` condition). Agent Video marked as `*(video — see evidence ZIP)*`.
- **Wallet manifest in evidence ZIP:** `_write_wallet_manifest()` added to orchestrator; generates `wallet_manifest.json` with per-wallet metadata and aggregate stats. Included in evidence ZIP with chain-of-custody entry.
- **STIX wallet indicators:** `crypto_wallet` pattern updated from `artifact:payload_bin` to `cryptocurrency-wallet:address` for proper TIP ingestion. `_create_wallet_indicator_sdo()` added with rich metadata (token, network, confidence). Infrastructure SDO description now mentions wallet count.
- **PII exposure model:** Added `PiiExposure` model to `InvestigationResult`. Both `report.md.j2` and `leo_report.md.j2` render PII exposure tables with field type, label, page URL, required/submitted status.
- **Wallet export endpoints:** `GET /investigations/{scan_id}/wallets.xlsx` and `.csv` for per-investigation wallet export via `WalletExporter`.
- **LEA report enhancements:** Added Section 4 (Cryptocurrency Wallet Addresses & Blockchain Intelligence) with recommended actions, Section 3 (PII Collection Map + Exposure Detail), and Section 9 (Evidence Package Contents with chain-of-custody manifest).
- **Evidence Bundle Download task:** Created future-work roadmap item for web app signed URLs, evidence bundle ZIP endpoint, and LEA package endpoint.
- **Test coverage:** 67 Phase 7 tests in `test_phase7_evidence_reporting.py` across 8 test classes; 561 total tests passing.
- **Files changed:** `ssi/src/ssi/{reports/pdf.py, evidence/stix.py, investigator/orchestrator.py, models/investigation.py, api/investigation_routes.py}`, `ssi/templates/{report.md.j2, leo_report.md.j2}`, `ssi/tests/unit/{test_phase7_evidence_reporting.py, test_stix.py}`, `planning/ssi-awh/04_roadmap.md`.

## 2026-02-22 — Infra: Dev/Prod Parity & Shared Module Refactor

- **Shared `secret_manager` module refactored:** Updated `modules/security/secret_manager/` to accept a `secrets` map variable with `for_each` loop and `auto {}` replication. Replaced single-secret interface (`secret_id` + `region`) with multi-secret map. Outputs `secret_ids` and `secret_names` maps.
- **Dev SSI secrets:** Replaced 4 inline `google_secret_manager_secret` resources with `module.ssi_secrets` using the shared module.
- **Prod SSI secrets:** Added identical `module.ssi_secrets` block to prod `main.tf` (4 secrets: proxy, VirusTotal, urlscan, ipinfo) with `env = "prod"` labels.
- **SSI API parity:** Added `ssi_api_enabled` variable + `count` guard to dev (matching prod pattern). Added GCS bucket merge to prod `run_ssi_api` module. Both envs now use `merge(var.ssi_api_env_vars, { SSI_EVIDENCE__GCS_BUCKET = ... })` and conditional `SSI_API_URL` in console.
- **Prod `terraform.tfvars` completed:** Added 10 missing SSI API env vars (GCS prefix, auth, browser, proxy, monitoring, cost, integration). Added 4 `ssi_api_secret_env_vars`. Added full `ssi_investigate` job config with 13 env vars + 4 secret_env_vars.
- **Bucket hardening:** Added `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"` to prod `ssi_evidence` bucket (matching dev).
- **`SSI_JOB__SCAN_TYPE` env var:** Added to both dev and prod `ssi_investigate` job configs (default `"full"`).
- **PII-vault migration:** Updated `pii-vault/dev` and `pii-vault/prod` to use the new `module.tokenization_secrets` with the `secrets` map interface. Updated `cloud_run.tf` IAM and secret references accordingly.
- **Files changed:** `modules/security/secret_manager/{main,variables}.tf`, `environments/app/{dev,prod}/{main.tf,terraform.tfvars,variables.tf}`, `environments/pii-vault/{dev,prod}/main.tf`, `environments/pii-vault/dev/cloud_run.tf`.

## 2026-02-22 — SSI: Phase 6 Complete — GCP Deployment, Bug Fixes & SDK Migration

- **Phase 6 GCP Deployment:** Updated both Dockerfiles (ssi-api, ssi-job) with Chromium for zendriver, CJK fonts, GCP dep caching layer, healthcheck. Added Terraform resources for Secret Manager (proxy, VirusTotal, urlscan, ipinfo), expanded IAM roles for `sa-ssi`, dynamic GCS bucket injection. Expanded `settings.dev.toml` with 12 sections. Added 33 settings tests.
- **Post-Deploy Bug Fixes:** (1) WHOIS: added retry with backoff + RDAP HTTP fallback for environments where TCP port 43 is blocked. (2) Cloud Logging: added JSON-structured `_CloudFormatter` for Cloud Run (severity parsing). (3) Orchestrator: fixed misleading "Ollama not available" message — now names the actual LLM provider with diagnostic context.
- **SDK Migration:** Migrated `gemini_provider.py` from deprecated `vertexai.generative_models` SDK to `google-genai` unified SDK (`google.genai`). Replaced `vertexai.init()` + `GenerativeModel()` with `genai.Client(vertexai=True)`. Updated `pyproject.toml` dependency from `google-cloud-aiplatform` to `google-genai>=1.0.0,<2.0`. Deduplicated response parsing into shared `_parse_response()` helper.
- **Pre-merge cleanup:** Fixed type hints (gemini_provider, whois_lookup, jobs.py), added missing docstrings on nested helpers, removed dead code line in orchestrator, removed redundant `urlparse` re-imports, tightened Dockerfile permissions (`chmod 755`), fixed pyproject.toml section comment formatting.
- **Roadmap:** Phase 6 fully checked off. Added Phase 7 task for PDF report evidence embedding (screenshots/DOM inline for print-friendly law enforcement reports).

## 2026-02-19 — SSI: Phase 5C/5D Complete — Console UI & Navigation

- **SSI Backend Endpoints:** Added `investigation_routes.py` with `GET /investigations` (paginated list, domain/status filters), `GET /investigations/{id}` (full detail: scan + wallets + PII + agent actions), `GET /wallets` (cross-investigation wallet search by address/token). Wired router into `ssi/api/app.py`.
- **TypeScript Types:** Created `ui/apps/web/src/types/ssi.ts` with comprehensive SSI type definitions (scan summaries, investigation detail, wallets, PII exposure, agent actions, WebSocket events, scan types).
- **API Proxies:** Added 3 Next.js API route proxies: `investigations/route.ts`, `investigations/[id]/route.ts`, `wallets/route.ts` — all forwarding to `SSI_API_URL`.
- **WebSocket Hook:** Created `use-investigation-monitor.ts` — React hook for real-time investigation monitoring via `/ws/monitor/{id}` and `/ws/guidance/{id}`, with snapshot handling, screenshot updates, keepalive, auto-reconnect.
- **Console SSI Pages:** Moved SSI into `(console)` route group (authenticated):
  - `/ssi` — Investigate page with scan type selector (passive/active/full), step progress tracker, risk badge, PDF download
  - `/ssi/investigations` — Server component list page with status filter pills, investigation cards
  - `/ssi/investigations/[id]` — 3-tab detail view (Recon, Live Monitor, Results)
  - `/ssi/wallets` — Client-side wallet search with address/token filters
- **Navigation:** Extended `NavItem` interface with optional `children` for sub-navigation. SSI nav expands to show Investigate / Investigations / Wallets when the section is active.
- **Auth Migration:** Removed `/ssi` from `PUBLIC_PREFIXES` in `middleware.ts`. Deleted the old standalone `app/ssi/` route (now served by `(console)/ssi/`).
- **Files created:** `ssi/src/ssi/api/investigation_routes.py`, `ui/apps/web/src/types/ssi.ts`, `ui/apps/web/src/app/api/ssi/{investigations,investigations/[id],wallets}/route.ts`, `ui/apps/web/src/lib/use-investigation-monitor.ts`, `ui/apps/web/src/app/(console)/ssi/{layout,page}.tsx`, `ui/apps/web/src/app/(console)/ssi/investigations/{page,loading,[id]/page}.tsx`, `ui/apps/web/src/app/(console)/ssi/wallets/page.tsx`.
- **Files modified:** `ssi/src/ssi/api/app.py`, `ui/apps/web/src/app/(console)/navigation.tsx`, `ui/apps/web/middleware.ts`.
- **Files removed:** `ui/apps/web/src/app/ssi/{page,layout}.tsx` (replaced by console version).

## 2026-02-18 — SSI: GCP Deployment, Gemini Integration, Web UI & PDF Reports

- **LLM Provider Abstraction:** Created pluggable LLM layer at `ssi/src/ssi/llm/` with `LLMProvider` ABC, `OllamaProvider`, and `GeminiProvider` implementations, plus a `create_llm_provider()` factory. Both `browser/llm_client.py` and `classification/classifier.py` refactored to use the abstraction instead of direct Ollama HTTP calls.
- **Gemini Integration:** `GeminiProvider` uses `google-cloud-aiplatform` (Vertex AI) with system instruction support, `response_mime_type="application/json"` for JSON mode, and token usage tracking. Configured via `SSI_LLM__PROVIDER=gemini`, `SSI_LLM__GCP_PROJECT`, `SSI_LLM__GCP_LOCATION` env vars.
- **PDF Reports:** Added `ssi/src/ssi/reports/pdf.py` using markdown→HTML→WeasyPrint pipeline with professional CSS styling (A4, page numbers, risk-colored headers, styled tables). Orchestrator generates PDF alongside markdown when `report_format` is `"pdf"` or `"both"`. Added `pdf_report_path` field to `InvestigationResult`.
- **Web UI:** Created built-in web UI at `ssi/src/ssi/api/web.py` with Jinja2 templates (`index.html`, `status.html`). Provides URL submission form, auto-refreshing status page, risk score display, and PDF download button. Served by the same FastAPI instance.
- **Docker & Build:** Created `ssi/scripts/build_image.sh` following core's pattern for building/pushing to Artifact Registry. Added `push-api` and `push-job` Makefile targets. Updated both Dockerfiles with WeasyPrint system dependencies.
- **Terraform:** Added SSI resources to `infra/environments/app/dev/`: service account `sa-ssi` with Vertex AI/Storage/Logging roles, Cloud Run service `ssi-api`, Cloud Run job `ssi-investigate`, GCS bucket `i4g-dev-ssi-evidence` (180-day lifecycle). SSI API uses `allUsers` invoker for initial dev access. Mirrored to `infra/environments/app/prod/` with production patterns: `ssi_api_enabled` toggle (default `false`), jobs disabled, `i4g-prod-ssi-evidence` bucket (365-day lifecycle, no force-destroy). Shared modules (`modules/run/service`, `modules/run/job`) are already generic — no module changes required.
- **Settings:** Added `config/settings.dev.toml` for GCP environment. Updated `settings.default.toml` with `gcp_project` and `gcp_location` fields.
- **Deps:** Added `markdown` and `weasyprint` to `pyproject.toml`.
- **Files created:** `ssi/src/ssi/llm/{__init__,base,factory,gemini_provider,ollama_provider}.py`, `ssi/src/ssi/reports/pdf.py`, `ssi/src/ssi/api/web.py`, `ssi/src/ssi/api/web_templates/{index,status}.html`, `ssi/config/settings.dev.toml`, `ssi/scripts/build_image.sh`.
- **Files modified:** `ssi/src/ssi/{browser/llm_client,classification/classifier,investigator/orchestrator,models/investigation,api/app,settings/config}.py`, `ssi/{pyproject.toml,Makefile,config/settings.default.toml}`, `ssi/docker/{ssi-api,ssi-job}.Dockerfile`, `infra/environments/app/{dev,prod}/{locals,main,variables,terraform}.tf{,vars}`.

## 2026-02-14 — Fix: IAP user identity not forwarded to API (BUG)

- **Root cause:** The console SSR calls the API through the IAP load balancer (`api.intelligenceforgood.org`). IAP authenticates the console's Cloud Run SA (not the browser user), so the API sees the SA's identity. The API-key fallback path hard-codes `username: "service"`, creating a phantom account. Forwarding `X-Goog-IAP-JWT-Assertion` doesn't work because the second IAP hop strips/replaces it.
- **Fix (UI):** `auth-helpers.ts` — `getIapHeaders()` now decodes the incoming IAP JWT assertion from the browser request (already verified by IAP at the LB), extracts the user's email, and sends it as `X-I4G-Forwarded-User` alongside the service-to-service Bearer token.
- **Fix (API):** `auth.py` — Added `_maybe_resolve_forwarded_user()` helper. When a request is authenticated via Bearer token, IAP JWT, or API key, and `X-I4G-Forwarded-User` is present, the API uses the forwarded email as the principal (resolving role from the accounts table). The override only applies when the authenticated identity is a service account, not an end-user hitting the API directly.
- **Fix (API):** `_verify_iap_jwt()` now accepts `is_iap_assertion=True` to use the IAP-specific signing-key endpoint (`_IAP_CERTS_URL`) instead of the default OIDC certs.
- **Terraform:** Added `I4G_IDENTITY__AUDIENCE = try(var.iap_clients["api"].client_id, "")` to the FastAPI Cloud Run env vars in both `dev` and `prod` environments.
- **Files changed:** `ui/apps/web/src/lib/server/auth-helpers.ts`, `core/src/i4g/api/auth.py`, `infra/environments/app/dev/main.tf`, `infra/environments/app/prod/main.tf`.
- **Deploy required:** Both `i4g-console` and `fastapi-gateway` images must be rebuilt and deployed for this to take effect.

## 2026-02-14 — WS-5 RBAC & Role Enforcement (COMPLETE)

- **F30 (Role checking):** Created `Role` enum (user/analyst/admin/leo) in `roles.py` with `has_role()` hierarchy check. `require_role()` now checks actual role from `accounts` table instead of granting admin to all.
- **F31 (Role wiring):** Option (a) — `_resolve_role()` in `auth.py` looks up `accounts.role` on every request via `AccountStore`. Auto-provisions new users with default role `analyst`. Deactivated accounts get 403.
- **F32 (Route-level auth):** Applied `require_role("admin")` to campaigns create/update, task update. Applied `require_role("analyst")` to detokenize. List endpoints remain authenticated-only.
- **F33 (UI role-aware):** Created `AuthProvider` + `useAuth()` hook with `hasRole()` and `isAdmin`. Navigation filters items by `minRole`; Campaigns and User Management are admin-only. User identity badge shown in sidebar.
- **F34 (Role management API):** `GET /accounts/me`, `GET /accounts` (admin), `PUT /accounts/{email}/role` (admin, blocks self-demotion), `PUT /accounts/{email}/deactivate` (admin, blocks self-deactivation).
- **F35 (Audit logging):** Role changes and account deactivation write audit entries to `review_actions` table with action types `role_change` and `account_deactivated`.
- **F36 (Row-level security):** "Team visibility" model — all authenticated users can view cases; `_enforce_assignment()` restricts annotate/feedback/decision actions to the assigned analyst or admins.
- **New table:** `accounts` (email PK, role, display_name, is_active, created_at, updated_at) added to `sql.py`.
- **Feature Completeness Sprint WS-5: ALL 7 ITEMS COMPLETE. 69 new tests, 635 total passing.**

## 2026-02-14 — WS-3 Classification & Risk Scoring (COMPLETE)

- **F15 (Risk Scoring):** Added `risk_weight` field to all items in `definitions.yaml` (intents 5-10, techniques 4-9, actions 6-9). Added dedicated `risk_score` Numeric(5,1) column + `taxonomy_version` Text column to `cases` table with index `idx_cases_risk_score`. Fixed `classifier.py` to key risk_weights by taxonomy code (e.g. `INTENT.IMPOSTER`) instead of label text. Risk scores now compute correctly via formula `sum(confidence × weight) × 2.5`, capped at 100.
- **F16 (Feedback Endpoint):** Enhanced `POST /reviews/{id}/feedback` to apply corrected classification to both `review_queue` and `cases` tables. Added `apply_feedback_classification()` and `get_case_text()` methods to `ReviewStore`.
- **F17 (Golden Dataset Pipeline):** Feedback writes to `golden_candidates.json` for curator review (manual promotion, not automatic). Decision: curator reviews candidates before they enter `golden_examples.json`.
- **F18 (Regression Tests):** Expanded `golden_examples.json` from 1 to 12 examples covering all 9 intent types. Created `test_classification_regression.py` with 15 tests validating dataset health, taxonomy weights, risk scoring formula, and model round-trips.
- **F19 (UI Classification Display):** Added Classification card with risk score badge and `ClassificationBadges` component to case detail page (`cases/[id]/page.tsx`). Fetches taxonomy data in parallel with case data.
- **F20 (Taxonomy Version Header):** Added `X-Taxonomy-Version` response header to `GET /taxonomy` endpoint. Exposed header via CORS `expose_headers`.
- **F21 (Sweeper Metrics):** Added `SweeperMetrics` dataclass tracking classified/error counts, intent distribution, and batch timing. Metrics reported to `TaskStatusReporter` and structured logging.
- **Bug fixes:** Fixed Pydantic v2 migration issue — sweeper used `result.dict()` instead of `result.model_dump()`. Re-enabled risk_score assertion in existing test (was disabled due to missing weights).
- **Feature Completeness Sprint WS-3: ALL 7 ITEMS COMPLETE. 566 unit tests passing.**

---

## Conventions Reference (from archived entries)

These conventions were established during earlier sprints and remain in effect:

- **CamelModel:** All new API response models must inherit from `CamelModel` (`from i4g.api.camel import CamelModel`). JSON output is automatically camelCase; Python code uses snake_case field names. Request models remain `BaseModel`.
- **CLI calling convention:** All CLI callee functions use `def func(*, param1: type, param2: type)` keyword-only signatures. Do not construct `SimpleNamespace` or `argparse.Namespace` objects — pass kwargs directly.
- **`dialect_insert()` helper:** Use `from i4g.store.sql import dialect_insert` for cross-dialect upserts (INSERT…ON CONFLICT).
- **Review queue statuses:** `new` → `in_review` → `awaiting_input` → `accepted` / `rejected` / `closed`.
- **Builtin generics:** 100% of production files use builtin generics (`dict`, `list`, `X | None`). No legacy `Dict`/`List`/`Optional`.
- **SSI architecture:** Single gateway (~20 routers), shared Cloud SQL, one Cloud Run Job. See `archive/ssi_development_summary.md`.

## 2026-03-19 — Copilot System Structural Cleanup

- **Slimmed all product repo instructions:** Replaced bloated 16-point `copilot-instructions.md` in `ui/`, `ssi/`, `infra/`, `planning/`, `docs/`, and `mobile/` with focused, repo-specific-only content (20–40 lines each). Removed ~500 lines of duplicate shared context from product repos.
- **Removed deprecated stubs:** Deleted `core/.github/general-coding.instructions.md`, `core/.github/architecture-cheatsheet.instructions.md`, and `core/.github/pre-merge-review.instructions.md` (backward-compat stubs that are now unused).
- **Fixed stale cross-references:** Updated all remaining references to `core/.github/` shared files to point to `copilot/.github/shared/` (canonical location) across `core/`, prompt files, and the pre-merge checklist.
- **Removed orphaned guide:** Deleted `docs/book/guides/copilot-workflow-guide.md` (deprecated, not in SUMMARY, content superseded by `copilot/docs/`).
- **Updated repo template:** Added `Coding Standards` section to `copilot/.github/repo-templates/copilot-instructions.template.md`.
- **Fixed cookbook typo:** "Sprint Wraup" → "Sprint Wrapup".
- **Entry point:** `copilot/docs/README.md` is the single entry point to the full Copilot intelligence system.

## 2026-03-19 — Documentation Revamp Sprint

Executed Phase 0, Phase 1, Phase 2.3 / 2.4, and Phase 5 of the doc revamp sprint defined in `planning/proposals/doc_revamp_plan.md`.

**Phase 0 — Hot Fixes (actively misleading content corrected):**

- Archived `planning/prd_prototype.md` → `planning/archive/prd_prototype_streamlit.md` (ARCHIVED banner added; original file now redirects to archive)
- Removed stale Streamlit reference from `planning/mobile/prd.md` (line: "remain on web/Streamlit" → "web-only (analyst console)")
- Added ARCHIVED banner to `core/docs/cookbooks/azure_legacy_data.md` (Azure migration complete 2025)
- Added consolidation-pending cross-reference banner to `core/docs/policies/detokenization_sop.md` (pii_vault.md does not yet contain SOP content; consolidation deferred)
- Fixed broken link in `core/docs/design/architecture.md`: `storage_architecture.md` → `storage.md`
- Rewrote stale guiding objective in `core/docs/design/architecture.md`: "Maintain feature parity with the retired Azure stack" → "Extend and differentiate" direction
- Archived `planning/architecture/visualization_strategy.md` → `planning/archive/visualization_strategy_deferred.md` (arch-viz repo deferred; inline Mermaid is current approach)
- Added pending-documentation note to `core/docs/testing/README.md`
- Added change-log reference note to `core/docs/release/README.md`
- Added ARCHIVED banner to `planning/archive/feature_completeness_plan.md` (sprint concluded Feb/Mar 2026)

**Phase 1 — System Narrative (created):**

- Created `planning/architecture/system_narrative.md` — 8 sections covering: Mission and Scope, Component Inventory (table of all deployed components), System Integration Map (Mermaid diagram), Data Ownership, Authentication and Identity Topology, Deployment Environments, Repository Map, Version and Release Policy
- Written from code and config (pyproject.toml, app.py, Terraform, settings.toml, Dockerfiles) — not from existing docs
- Includes verification-needed banners for items that require confirmation in code

**Phase 2 — Architecture and Integration Documents (created/in progress):**

- Created `planning/architecture/integration_contracts.md` — documents all 8 cross-service integration contracts: UI→Core proxy (auth headers, catch-all route), UI→SSI (eCX direct, investigations through core), Core→SSI (OIDC trigger), SSI→Core (push results, live events, guidance poll), TIFAP→Core (internal DB, no HTTP), Scheduler→Jobs (cron inventory), Ingestion pipeline sequence
- Created `planning/architecture/doc_audit_matrix.md` — complete inventory of ~90 documents across all repos with Tier, Status, Issues, and Owner for each

**Phase 5 — Governance and Sustainability (created):**

- Created `copilot/.github/shared/tdd-template.md` — 11-section template for new and existing TDDs; required sections include architecture diagram, component index, key design decisions, API surface, data model, config reference, environment behavior, development workflow
- Created `copilot/.github/shared/doc-governance.instructions.md` — documentation governance policy: definition of done (PR checklist), ownership matrix by tier, staleness detection (Last Verified convention + 90-day rule), quarterly review cadence, new component checklist
- Created `planning/architecture/adr/` directory with README and first 5 ADRs:
  - ADR-001: Azure to GCP migration (2025)
  - ADR-002: FastAPI + Pydantic v2 as core API framework (2025)
  - ADR-003: SSI as a separate Cloud Run service, not embedded in core (2025)
  - ADR-004: PII vault — Fernet encryption + audit-logged decryption (March 2026)
  - ADR-005: Chroma vs. pgvector for vector storage (2025, under review)

**Remaining sprint work (for next session):**

- ~~Phase 2.1: Fix `core/docs/design/architecture.md` — add SSI to topology diagrams, add TIFAP + PII vault sections, Last Verified date~~ **DONE 2026-03-20**
- ~~Phase 2.2: Restructure `core/docs/development/tdd.md` as master TDD with subsystem index~~ **DONE 2026-03-20**
- ~~Phase 3: Component doc repairs (core design docs, SSI doc validation, UI architecture rewrite, infra docs creation)~~ **DONE 2026-03-20** (all items confirmed present from prior session)
- ~~Phase 4: End-user GitBook coherence pass~~ **DONE 2026-03-20**

## 2026-03-20 — Phases 2.2, 3, 4: Doc sprint completion

**Phase 2.2 — TDD restructure:**

- `core/docs/development/tdd.md` (v3.0 → v3.1): Removed ~800 lines of legacy appended content (API samples, OAuth code, DB schemas, CI/CD YAML, deployment scripts, test examples, disaster recovery). Master TDD sections 1–13 retained as the clean subsystem index.
- Updated all 13 subsystem Last Verified dates from `?` to `March 2026`.

**Phase 3 — Component doc repairs (audit results):**

- `core/docs/development/glossary.md` — already has SSI, TIFAP, Fraud Taxonomy, and Infrastructure sections (confirmed)
- `ui/docs/ui_architecture.md` — already has API Proxy Layer, Authentication Flow, and State Management sections (confirmed)
- `infra/docs/README.md` — already indexes service_catalog, scheduler_inventory, module_reference (confirmed)
- `infra/docs/service_catalog.md`, `scheduler_inventory.md`, `module_reference.md` — all exist with March 2026 Last Verified dates (confirmed)
- `ssi/docs/ops_runbook.md` — exists with March 2026 Last Verified (confirmed)
- `core/docs/api_reference.md` — exists (confirmed)
- No new files needed; all Phase 3 items were completed in the prior doc session.

**Phase 4 — GitBook coherence pass:**

- Created `docs/book/guides/admin/index.md` — Admin Guide landing page linking CLI, Scheduled Reports, Partner Feed
- Fixed `docs/book/SUMMARY.md` — Admin Guide entry now links to `guides/admin/index.md` (was bare text, no file path)
- All other SUMMARY.md page references verified: all files exist across overview/, guides/, architecture/, api/, ssi/, security/

## 2026-03-21 — ML Platform Phase 0, Sprint 1

- **infra/** — New Terraform modules: `modules/bigquery/dataset/`, `modules/vertex_ai/endpoint/`. Stack `stacks/ml/` composing BigQuery dataset (9 tables), Vertex AI endpoints (dev + prod), GCS bucket, service account, cross-project IAM. Environment `environments/ml/`. Bootstrap script `bootstrap/create_ml_project.sh`.
- **ml/** — New repository scaffold: `src/ml/` package with data, training, serving, registry, monitoring sub-packages. `TrainingConfig` + `FeatureDefinition` Pydantic models with unit tests. Config system (`ml.config.get_settings()`).
- **core/** — `analyst_labels` Alembic migration (FK → cases, indexed). `MlPlatformSettings` section with `inference_backend`, `platform_base_url`, `platform_auth_method`, `fallback_to_llm`. `MLPlatformClient` async httpx client. `build_inference_client()` factory routing. Unit tests for settings + factory.
- **docs/** — Settings manifest updated with `ml.*` fields.
- **planning/** — Task plan `tasks/ml_platform_phase0.md` with Sprint 1 tasks checked off.

## 2026-03-24 — ML Phase 2: Sprint 5 Dataflow/Beam + Entity Extraction Factory

- **planning/** — Updated `tasks/ml_phase2_training_maturity.md`: rewrote Sprint 5 from Spark/Dataproc to Dataflow/Beam (architecture decision: co-occurrence aggregations + connected components don't need Spark GraphX; Beam + NetworkX is simpler, cheaper, and consistent with existing GCP-native stack). Added Dataflow IAM + Cloud Scheduler items to Manual Steps Checklist. Added Documentation Updates entry for Sprint 5. Added Developer Bootcamp Exercises section (post-build onboarding material for new contributors).
- **ml/** — Renamed `ComputeMethod.SPARK` → `ComputeMethod.DATAFLOW` in `src/ml/data/features.py` (forward-compatible with Sprint 5 graph features).
- **core/** — Added `build_entity_extraction_client()` factory in `src/i4g/services/factories.py` — routes entity extraction based on `settings.ml.entity_extraction_backend` independently from classification backend. Unit tests added (4 tests pass). Task 4.6 completed.

## 2026-03-24 — ML Phase 2: Archive + Bootcamp Exercises

- **planning/** — Archived Phase 2 task plan to `archive/ml_platform_phase2_summary.md`. Extracted incomplete tasks (Vizier sweep, NER E2E deployment, graph features validation, manual steps) to `tasks/ml_phase2_deferred.md`. Created `tasks/ml_bootcamp_exercises.md` tracking 9 developer onboarding exercises.
- **ml/** — Created `docs/bootcamp/` with 9 guided exercises covering the full ML platform lifecycle: data flow, local training, pipeline submission, evaluation/promotion, serving deployment, monitoring/retraining, adding capabilities, graph features, and Looker Studio dashboards. Updated `docs/README.md` with bootcamp index.

## 2026-03-25 — ML Platform: Phase 3 Implementation (Sprints 1–7)

Implemented all code deliverables for ML Phase 3: Advanced Capabilities. 5 PRD deliverables (champion/challenger A/B routing, batch prediction, Feature Store, risk scoring + document similarity, cost-aware routing) have code committed across `ml/`, `core/`, and `infra/`.

**Repos affected:** `ml/`, `core/`, `infra/`, `planning/`

**ml/ — key changes:**

- **Sprint 1 (Champion/Challenger A/B Routing):** `routing.py` — `TrafficSplitConfig`, `load_traffic_config()`, `route_prediction()` with deterministic/random split; `variant` + `routing_reason` columns in prediction log
- **Sprint 2 (Batch Prediction):** `serving/batch.py` — BigQuery read → model inference → BigQuery write with progress logging; `scripts/run_batch_prediction.py` Cloud Run Job entry point; `docker/batch-prediction.Dockerfile`
- **Sprint 3 (Feature Store):** `data/feature_store.py` — Vertex AI Feature Store sync + in-memory cache with TTL; `serving/features.py` — `compute_inline_features()` with Feature Store → inline fallback
- **Sprint 4 (Risk Scoring):** `serving/predict.py` — `predict_risk_score()` XGBoost regressor with 0–1 clamping; `data/datasets.py` — `create_risk_dataset_version()`; `training/evaluation.py` — `evaluate_regression()` (MSE, MAE, RMSE, Spearman ρ); `registry/promotion.py` — risk scoring eval gate; `containers/train-xgboost/train.py` — dual classifier/regressor support
- **Sprint 5 (Document Similarity):** `serving/embeddings.py` — sentence-transformer embedding; `serving/similarity.py` — FAISS index build/search with BigQuery persistence; `POST /predict/similar-cases` route
- **Sprint 6 (Cost-Aware Routing):** `routing.py` — `select_cheapest_model()`, quality-gated cost optimization; `COST_AWARE_ROUTING` env var; `analytics_variant_comparison` BQ table
- **Sprint 7 (Docs):** Architecture doc updated with 5 new sections; new runbooks for batch prediction and Feature Store
- Scripts: `scripts/submit_pipeline.py` — Vertex AI pipeline submission utility; `scripts/trigger_retraining.py` — Cloud Run Job retraining trigger
- **Refactored:** Standalone scripts `submit_pipeline.py` and `trigger_retraining.py` consolidated into `i4g-ml` CLI — `ml.training.submission` library + `ml.cli.retrain.run()` function; standalone scripts deleted
- **Tests:** 333 passing, 7 skipped, 0 failures (fixed: mock patching for local imports, XGBoost DMatrix segfaults, Spearman tied-values edge case)

**core/ — 4 files:**

- `MLPlatformClient.score_risk()` and `.find_similar_cases()` — risk scoring + similarity endpoint integration
- `risk_scoring_backend` and `similarity_backend` settings (default: `"llm"`)
- `build_risk_scoring_client()` and `build_similarity_client()` factories
- 12 unit tests passing (4 new)

**infra/ — 2 files (stacks/ml/):**

- 11 new Terraform variables (challenger, risk model, Feature Store, embedding, cost-aware routing)
- Cloud Run serving env vars updated (dev + prod)
- Memory bumped 2Gi → 4Gi on both serving environments
- `prediction_log` schema: `variant` + `routing_reason` columns
- 3 new BigQuery tables: `batch_predictions`, `features_case_embeddings`, `analytics_variant_comparison`
- 3 new Cloud Run Jobs: `batch-prediction`, `feature-store-sync`, `embedding-refresh`
- 2 new Cloud Scheduler Jobs: weekly feature store sync, weekly embedding refresh
- Vertex AI Feature Store: `google_vertex_ai_featurestore.ml_features`, entity type + IAM

**Remaining manual steps:** terraform apply, BigQuery schema migrations, model deployment, E2E smoke tests, exit criteria validation.

## 2026-04-02 — Entity type normalization & UI labels

Unified entity type handling across the stack: canonical definitions in `core/src/i4g/utils/entity_types.py`, normalization at all write paths, and user-friendly display labels in the UI.

**core/ — 5 files:**

- `entity_types.py` — rewritten as single source of truth: `ENTITY_TYPE_LABELS`, `CANONICAL_ENTITY_TYPES`, updated normalization map, removed `expand_entity_type()` / `_REVERSE_MAP`
- `intelligence.py` — new `/entities/type-labels` endpoint; dashboard widget uses `count_entity_stats` instead of fetching full lists; graph seed normalization
- `bootstrap/local/steps.py` — fixed golden bundle path; normalizes entity types at ingest time
- `entity_extract.py` — normalizes entity types before persistence
- `analytics_aggregation.py` — safety-net normalization for legacy data

**ui/ — 9 files:**

- New `entity-types.ts` — label + color utilities matching core definitions
- Entity explorer, detail panel, filter sidebar, watchlist — display labels instead of raw type IDs
- Network graph — split seed into type dropdown + value input, dynamic legend, fetch entity types from API
- Classification badges — taxonomy code formatting with tooltips
- Tests updated to match new UI controls

## 2026-04-03 — Entity lifecycle statuses, threat entity types, KPI accuracy

Added entity lifecycle status tracking, threat entity type filtering for the Active Threats KPI, and first_seen_at-based KPI counting to prevent bootstrap data inflation.

**core/ — 6 files:**

- `entity_types.py` — new `THREAT_ENTITY_TYPES` constant (14 actionable threat types, excludes contextual NER)
- `intelligence.py` — Active Threats widget filters by `THREAT_ENTITY_TYPES` instead of counting all entities
- `analytics_aggregation.py` — `_compute_entity_status()` lifecycle engine (active → declining → dormant → resolved, sticky flagged); `_refresh_entity_stats` writes status; KPI new-indicators/entities use `first_seen_at` over `created_at`
- `analytics_store.py` — `count_entity_stats` and `_entity_filters` accept `entity_types` filter
- `bootstrap/local/steps.py` — reads `manifest.json` bundle date for `first_seen_at`/`last_seen_at` on entities and indicators
- `test_analytics_aggregation.py` — 8 new tests covering lifecycle transitions, resolved status, and first_seen_at KPI behavior

**docs/ — 18 files:**

- New `threat_entity_types.md` guide explaining threat vs contextual entities
- `impact_dashboard.md` — expanded Active Threats, New Indicators, and entity lifecycle documentation
- `entity_explorer.md` — added Status column and lifecycle status table
- Removed sprint labels and internal source references across all changed files
- `SUMMARY.md` — added Threat Entity Types entry

**planning/ — 1 file:**

- `change_log.md` — this entry

## 2026-04-03 — Remove Azure and Legacy System References

Removed all traces of the retired Azure infrastructure and legacy system from the codebase. The platform no longer depends on any Azure services; all historical data has been migrated to GCP.

**Deleted files:**

- `core/src/i4g/cli/azure/` — entire Azure CLI subcommand module (blob-to-gcs, search-export, search-to-vertex)
- `core/scripts/migration/` — all 10 Azure migration scripts (azure_blob_to_gcs.py, azure_search_export.py, audit_db_tables.py, etc.)
- `core/scripts/infra/add_azure_secrets.py` — Secret Manager helper for Azure credentials
- `core/scripts/etl/clean_legacy_azure.py` — legacy Azure bundle cleaner
- `core/docs/cookbooks/azure_legacy_data.md` — archived Azure cookbook

**core/ — 4 files edited:**

- `src/i4g/cli/app.py` — removed azure_app import and registration
- `src/i4g/cli/__init__.py` — removed "azure" from `__all__`
- `pyproject.toml` — removed `azure-identity`, `azure-search-documents`, `azure-storage-blob`, `pyodbc` dependencies
- `requirements.txt` — regenerated without Azure/pyodbc packages

**core/docs/ — 4 files edited:**

- `cookbooks/README.md` — removed azure_legacy_data link
- `cookbooks/bootstrap_environments.md` — removed legacy bundle structure section and Azure references
- `cookbooks/prepare_bootstrap_bundles.md` — removed Azure export section and legacy steps; renumbered
- `development/bundle_sources_and_coverage.md` — removed `legacy_azure` bundle entry

**core/tests/ — 1 file edited:**

- `tests/unit/settings/test_settings_env_overrides.py` — updated GCS test URI from legacy_azure path to golden bundle path

**docs/ — 4 files edited:**

- `book/security/secrets-reference.md` — removed "Azure Migration Secrets" section (stale D62 secrets)
- `book/guides/admin/cli.md` — removed `i4g azure` command reference
- `book/config/settings.md` — removed legacy alias mention
- `book/architecture/evidence-storage.md` — removed "legacy" qualifier from flat path fallback
- `book/api/sdk_endpoint_coverage.md` — "Legacy search" → "Superseded"
- `config/README.md` — removed legacy alias mention

**infra/ — 1 file edited:**

- `README.md` — removed `add_azure_secrets.py` reference and Azure troubleshooting section

**ssi/ — 1 file edited:**

- `src/ssi/browser/agent_controller.py` — removed "instead of Azure Blob Storage" from docstring

**planning/ — 2 files edited:**

- `architecture/doc_audit_matrix.md` — updated azure_legacy_data.md status from ARCHIVED to DELETED
- `change_log.md` — this entry

**Not touched (intentional):**

- `planning/architecture/adr/adr-001-azure-to-gcp-migration.md` — retained as historical decision record
- `planning/change_log.md` historical entries — retained as changelog history
- `planning/archive/` files — retained as archived history
- `ml/` BigQuery `--use_legacy_sql=false` flags — BigQuery standard SQL flag, not Azure-related
- `infra/modules/run/service/` "legacy v1" references — Cloud Run API version terminology, not Azure-related
