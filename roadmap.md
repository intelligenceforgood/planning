# I4G Platform Implementation Roadmap

**Status**: Living Document<br/>
**Date**: November 26, 2025

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

### Milestone 1: Parity Verification & Gap Closure (Weeks 1-2)
**Objective**: Confirm the codebase matches the "Ported" assumptions and close critical functional gaps.
- [x] **Port `account_list_extract`**: New `i4g.services.account_list` package ships retriever/extractor/exporter orchestration, FastAPI `/accounts/extract`, and worker entrypoints consumed by the Streamlit console + CLI smokes.
- [x] **Port `account_list_extract_client`**: Artifact exports (CSV/JSON/XLSX/PDF) now mirror the legacy workflow, including optional Drive uploads, Cloud Run job wiring, and dashboard surfacing with summary/status panels.
- [ ] **Legacy Cleanup**: Finalize the archiving of `dtp` references once parity is confirmed.

### Milestone 2: The "Dual Extraction" Pipeline (Weeks 3-4)
**Objective**: Implement the robust ingestion architecture for hybrid search.
- [ ] **Design Schema**: Define the SQL schema for extracted entities (Banks, Crypto Wallets, Phone Numbers).
- [ ] **Ingestion Worker**: Update `i4g.worker` to:
    1.  Extract entities via LLM.
    2.  Write to Firestore (Case View).
    3.  Write to Vertex AI Search (Semantic Index).
    4.  Write to Cloud SQL (Structured Index).
- [ ] **Backfill**: Run the new pipeline against existing `data/entities_semantic.json` data.

### Milestone 3: Advanced Search & Analysis (Weeks 5-6)
**Objective**: Empower analysts with hybrid search and structured filtering.
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
1.  Rebuild/ingest structured + vector stores so the account list retriever finds November cases; document results in `planning/change_log.md`.
2.  Provision the `account-list` Cloud Run job in `i4g-dev` (Terraform or manual), rerun the dry/full smokes, and capture artifact URLs for analysts.
3.  Kick off the Dual Extraction schema definition to unblock Milestone 2 (SQL tables, Vertex AI Search documents, and migration plan).
