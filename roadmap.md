# I4G Platform Implementation Roadmap

**Status**: Living Document<br/>
**Date**: November 30, 2025

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

**Status**: Feature-complete (Dec 6); running pilot verification and smoke cadence before closing.

### Milestone 5: Production Hardening (Week 9)
**Objective**: Secure the platform for public launch.
- [ ] **PII Vault Audit**: Verify tokenization and encryption for all PII fields (FR-1).
- [ ] **Auth Enforcement**: Enable IAP and enforce OAuth 2.0 for all endpoints (FR-2).
- [ ] **Monitoring**: Configure Cloud Logging/Monitoring alerts for error rates and PII access (FR-4).

### Milestone 6: Production Launch (Week 10)
**Objective**: Go Live.
- [ ] **Infra Lockdown**: Re-enable `constraints/iam.allowedPolicyMemberDomains`.
- [ ] **Load Testing**: Validate system against 20+ concurrent users.
- [ ] **Handover**: Final documentation and runbooks.

## Immediate Next Steps
1.  Run LEA dossier pilot verification: portal handoff banner + Drive ACL preview + Web Crypto hash check against a pilot bundle; capture sign-off and regressions.
2.  Enforce nightly dossier smoke before merges: automate `scripts/smoke_dossiers.py` + API download proxy and alert on hash mismatches or missing artifacts.
3.  Codify verification UX defaults: keep Web Crypto as the primary verifier with API fallback for headless/air-gapped reviewers; document both paths in the runbook.
4.  Prep Milestone 5 kickoff: lock the PII vault/IAP enforcement plan (align with vault/IAP lessons from Milestone 4) and carry remaining hardening items forward.
