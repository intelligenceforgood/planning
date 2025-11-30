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
- _Design spike_: `planning/milestone3_hybrid_search.md` captures the architecture, API contracts, UI requirements, and delivery plan for this milestone.
- [ ] **Hybrid Retriever**: Update `src/i4g/api/review.py` to query both Vertex AI and SQL.
- [ ] **Analyst Dashboard**: Add "Structured Search" filters (e.g., "Find all cases with Crypto Wallet X") to the Streamlit/Next.js UI.
- [ ] **Entity Taxonomy Expansion**: Add browser agent, IP address, ASN, and future indicators through configuration so new signals can ship without code changes.

### Milestone 4: Agentic LEA Evidence Dossiers (Weeks 7-8)
**Objective**: Produce export packages that law enforcement can adopt directly.
- [ ] **Agentic Report Blueprint**: Define the toolchain for charts, graphs, maps, and PDF assembly (ReportGenerator + notebook helpers + agent orchestration).
- [ ] **Thresholding & Case Bundling**: Implement logic to group cases by dollar loss, geography, or cross-border signals so only prosecutable dossiers ship.
- [ ] **Template Extensibility**: Ensure new visualization/report widgets can be plugged in (e.g., geo heatmaps, loss timelines) without modifying the agent harness.
- [ ] **Diagram Sync**: Begin migrating architecture/data-flow diagrams to Figma/Miro and link them from `proto/docs/architecture.md` and the TDD.

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
1.  Implement `HybridSearchService` + Review API plumbing per `planning/milestone3_hybrid_search.md`, including scoring, deduplication, and audit logging.
2.  Expose the `/reviews/search/schema` endpoint + saved-search schema updates so the Streamlit/Next.js filters can stay in sync with backend capabilities.
3.  Prototype the analyst UI structured-filter components (Streamlit + Next.js) using the schema endpoint, then integrate them with saved searches and search history.
