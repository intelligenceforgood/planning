# I4G Platform Implementation Roadmap

**Status**: Living Document<br/>
**Date**: December 10, 2025

## Executive Summary
This roadmap defines the path from our current "Prototype" state to the "Production" vision outlined in `prd_production.md`. It prioritizes feature parity with the legacy DTP system, robust security (PII/Auth), and a scalable "Dual Extraction" architecture.

## Strategic Goals
1.  **Feature Parity**: Ensure all critical DTP capabilities (specifically `account_list_extract`) are fully ported and operational in `proto`.
2.  **Dual Extraction**: Implement the ingestion pipeline to write structured data to both **Vertex AI Search** (for semantic retrieval) and **Cloud SQL/AlloyDB** (for structured/analytical queries).
3.  **Production Readiness**: Harden security, auth, and infrastructure for the "Unauthed" -> "IAP" transition.
4.  **Scalability & Extensibility**: Establish a platform that supports future apps (e.g., Mobile SDKs, Partner APIs) via clean API contracts and event-driven architecture.
5.  **LEA Evidence Dossiers**: Deliver an extensible reporting pipeline (charts, maps, PDFs) so law enforcement can adopt ready-to-investigate cases, even when losses exceed seven figures or span cross-border activity.
6.  **Structured Intelligence Growth**: Continuously expand the entity taxonomy (Bitcoin IDs, bank accounts, email domains, browser agents, IP, ASN, etc.) with configuration-driven extraction so new indicators can be added without rewrites.
7.  **Modern Architecture Artifacts**: Replace ad-hoc ASCII diagrams with synced Figma/Miro artifacts to keep system, data-flow, and TDD diagrams trustworthy.

## Milestones

### Milestone 1: Parity Verification & Gap Closure (Completed – Nov 29, 2025)
**Outcome**: Confirmed the proto stack fully replaces the Azure Functions workflow, including API/worker parity, artifact generation, and analyst-console surfacing. All planning docs for this milestone are retired and tracked via the change log.
- [x] **Port `account_list_extract`**: New `i4g.services.account_list` package ships retriever/extractor/exporter orchestration, FastAPI `/accounts/extract`, and worker entrypoints consumed by the Streamlit console + CLI smokes.
- [x] **Port `account_list_extract_client`**: Artifact exports (CSV/JSON/XLSX/PDF) now mirror the legacy workflow, including optional Drive uploads, Cloud Run job wiring, and dashboard surfacing with summary/status panels.
- [x] **Legacy Cleanup**: Archived the dedicated planning docs and captured the final status in `planning/change_log.md`, leaving any residual `dtp` references tracked via the general backlog.

### Milestone 2: The "Dual Extraction" Pipeline (Weeks 3-4)
**Objective**: Implement the robust ingestion architecture for hybrid search.
- [x] **Design Schema**: SqlWriter metadata + Alembic migrations finalized; SQLite + dev schemas created during the dual-write rollout so both local + Cloud SQL environments share identical entity tables.
- [x] **Ingestion Worker**: `i4g.worker.jobs.ingest` now extracts entities, dual-writes SQL + Firestore + Vertex, records counters per backend, and persists payload/context to the ingestion retry queue for Firestore/Vertex replays.
- [x] **Backfill**: Dev run `01993af5-09ab-4ecf-b0c8-cd86702b8edd` processed 200 `retrieval_poc_dev` cases. SQL/Firestore writes reached 200/200; Vertex stopped at 155 because of the "Document batch requests/min" quota (429 ResourceExhausted). `python -m i4g.worker.jobs.ingest_retry` (batch 10) drained the 45 queued Vertex payloads once quota recovered, confirming eventual consistency.
- [x] **Documentation Refresh**: Captured the dev backfill summary, retry procedure, and Vertex quota mitigations across `planning/change_log.md`, `docs/architecture.md`, `docs/config/README.md`, and the ingestion runbook so operators know how to throttle or request higher import quotas before the next dataset.

### Milestone 3: Advanced Search & Analysis (Weeks 5-6)
**Objective**: Empower analysts with hybrid search and structured filtering.
- [x] _Design spike_: `planning/milestone3_hybrid_search.md` captures the architecture, API contracts, UI requirements, and delivery plan for this milestone. (Completed Dec 2)
- [x] **Hybrid Retriever**: `HybridSearchService` plus `/reviews/search/{schema,query}` now orchestrate Vertex AI + SQL results with scoring/audit diagnostics. Streamlit + Next.js consume the same schema payloads. (Completed Dec 2)
- [x] **Analyst Dashboard**: Streamlit’s Advanced Filters drawer and the Next.js `/search` console both support taxonomy/dataset/entity filters, saved-search parity, and smoke coverage. (Completed Dec 2)
- [x] **Entity Taxonomy Expansion**: Browser agent, IP address, ASN, loss buckets, and schema-driven examples are live in `/reviews/search/schema` and the ingestion pipeline, so new indicators can be toggled without code. (Completed Dec 1)

### Milestone 4: Agentic LEA Evidence Dossiers (Weeks 7-8)
**Objective**: Produce export packages that law enforcement can adopt directly.
- [x] **LEA Distribution UX**: Portal surfaces Drive folder/ACL previews, remote refs, and a handoff banner with one-click manifest/download links.
- [x] **Client-side Verification**: Web Crypto hash verification of downloaded artifacts with clear API fallback; test coverage (Vitest/Playwright happy path).
- [x] **Telemetry & Smoke**: StatsD counters for queue/verification plus a documented smoke that hits `/reports/dossiers` and downloads via the proxy.
- [x] **Runbooks & Env Docs**: Update analyst/LEA runbooks with portal download/verify steps and env references (`I4G_DOSSIER_BASE_PATH`, Drive IDs, IAP tokens).
- [x] **Diagram Sync**: Migrate dossier architecture flow to Figma/Miro and link from `docs/architecture.md`.

### Milestone 5: PII Vault Separation (Weeks 9-10) — Completed Dec 10, 2025
**Objective**: Isolate secrets/PII in dedicated vault projects and wire least-privileged access.
- [x] **Projects & State**: Vault projects/backends created for dev/prod with documented init/plan flows.
- [x] **KMS & Secrets**: Vault KMS ring/keys plus Secret Manager containers (`tokenization-pepper`, `pii-tokenization-key`) provisioned; rotation/runbook captured.
- [x] **Cross-Project IAM**: App runtime SAs granted secret accessor + cryptoKeyEncrypterDecrypter via WIF; bindings validated with the new verifier script.
- [x] **Token Format & Catalog**: `AAA-XXXXXXXX` scheme and prefix registry finalized in [docs/pii_vault.md](proto/docs/pii_vault.md#token-format) with normalization rules.
- [x] **Vault Data Model & Detokenization**: Records, registry, and subpoena workflow defined (KMS-gated, dual-approval, audit + alerting) in [docs/pii_vault.md](proto/docs/pii_vault.md#vault-data-model) and [docs/policies/detokenization_sop.md](proto/docs/policies/detokenization_sop.md).
- [x] **Ingestion Tokenization**: Deterministic tokenization helpers + observability landed (`tokenize_text`/`tokenize_fields`, `PiiVaultObservability`) with tests; ingestion path documented to route PII to the vault store.
- [x] **Artifact Handling**: Vault bucket layout + hash verification job plan documented with sharded paths and retention defaults.
- [x] **App Plumbing**: Cloud Run env vars map to vault secrets (per-env) with failure guidance in the smoke tests.
- [x] **Smoke**: Vault secret-access verifier and Cloud Run tokenization/detokenization round trip added to [docs/smoke_test.md](proto/docs/smoke_test.md#vault-secrets-smoke-gcp).

### Milestone 6: Production Hardening (Week 11)
**Objective**: Secure the platform for public launch.
- [ ] **Auth Enforcement**: Confirm IAP/OAuth across all surfaces; remove temporary overrides.
- [ ] **Monitoring**: Configure Cloud Logging/Monitoring alerts for error rates and PII access (FR-4).
- [ ] **Perf/Resilience**: Load test for 20+ concurrent users; capture SLOs and alert thresholds.

### Milestone 7: Production Launch (Week 12)
**Objective**: Go Live.
- [ ] **Infra Lockdown**: Re-enable `constraints/iam.allowedPolicyMemberDomains`.
- [ ] **Handover**: Final documentation and runbooks.

## Immediate Next Steps
1. Harden auth + monitoring (Milestone 6): enforce IAP/OAuth across surfaces, wire PII-access alerts, and remove temporary overrides.
2. Run vault smokes per environment: seed vault prod secrets, then execute Cloud Run tokenization/detokenization round trips in dev → prod using the new verifier script.
3. Capture performance/resilience baselines: load-test 20+ concurrent users, document SLOs, and size autoscaling/limits before launch.
