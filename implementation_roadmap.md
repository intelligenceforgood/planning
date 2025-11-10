# Implementation Roadmap (Milestone 3 Draft)

_Last updated: 10 Nov 2025_

This roadmap translates the gap analysis and future-state architecture into actionable workstreams. It assumes a single technical contributor (Jerry) with volunteer support for documentation/testing as available.

## 1. Workstreams Overview

| Stream | Description | Key Outputs |
|---|---|---|
| **Identity & Access** | Stand up OIDC auth, roles, and security rules | Auth service, Streamlit + FastAPI integration, IAM policies |
| **Ingestion & Data Pipelines** | Replace Azure ingestion jobs with GCP-native flows | Cloud Run jobs, scheduler configs, Firestore/AlloyDB data loaders |
| **Retrieval & RAG** | Implement chosen retrieval backend + LLM pipeline | Vector store, LangChain orchestration, evaluation harness |
| **Frontend & UX** | Deliver victim intake UI + analyst dashboard parity | Streamlit feature parity, FastAPI endpoints, docs site updates |
| **Security & Observability** | IAM hardening, secrets, logging/monitoring | Terraform modules, alerting policies, PII vault enforcement |
| **Documentation & Ops** | Author runbooks, migration guides, comms plan | Updated docs, migration checklists, volunteer onboarding |

## 2. Timeline Snapshot (12-week plan @ ~10 hrs/week)

```
Weeks 1-3: Identity & Access foundation, Cloud Run baseline, planning artifacts
Weeks 4-6: Retrieval PoCs + decision, architecture diagrams, IAM hardening
Weeks 7-9: Ingestion pipelines, retrieval integration, reporting automation
Weeks 10-12: Frontend parity, observability, IAM cleanup, migration rehearsal & docs freeze
```

> NOTE: This pacing assumes the accelerated progress from early Milestone 2 continues; revisit after retrieval decisions if scope shifts.

## 3. Detailed Tasks by Stream

### 3.1 Identity & Access
- Implement Google Identity Platform auth flows (victim + analyst) via OIDC.
- Configure Streamlit + FastAPI to verify tokens and enforce roles.
- Define Firestore security rules for `/cases`, `/pii_vault`, `/analysts`.
- Terraform IAM: create dedicated service accounts, grant least-privilege roles.
- Stretch: Evaluate authentik deployment on Cloud Run for future OSS control.

### 3.2 Ingestion & Data Pipelines
- Catalog all Azure ingestion jobs (Forms, GroupsIO, account extracts) with frequency and outputs.
- Build Cloud Run job templates with shared `ingestion` package.
- Create scheduler configs via Terraform; store credentials in Secret Manager.
- Implement logging + alerting (failure notifications, retries).
- Backfill historical data from Azure storage/SQL into GCP stores.

### 3.3 Retrieval & RAG
- Complete PoC comparison (Vertex AI Search vs AlloyDB pgvector) with evaluation dataset.
- Provision chosen retrieval store and load initial embeddings.
- Integrate LangChain pipeline with selected LLM host (Vertex AI initially).
- Add evaluation harness (quality metrics, latency, cost monitoring).
- Implement fallback path for self-hosted Ollama if required.

### 3.4 Frontend & UX
- FastAPI endpoints: victim intake, chat, report generation.
- Streamlit dashboard: case queue filters, document viewer, chat transcript, approval workflow.
- Integrate Cloud Storage signed URL flow for evidence download.
- Implement automated PDF report generator (templating, digital signature stub).
- Coordinate with docs site updates for user/analyst instructions.

### 3.5 Security & Observability
- Configure structured logging (OpenTelemetry + Cloud Logging).
- Create Cloud Monitoring dashboards and alert policies.
- Enforce Secret Manager usage, implement key rotation job.
- Penetration-test endpoints (baseline checks, OWASP top 10 review).
- Document incident response plan (who to notify, triage steps).

### 3.6 Documentation & Ops
- Update `system_review.md`, `future_architecture.md`, and runbooks as changes land.
- Write migration scripts/docs: Azure Blob → Cloud Storage, Azure SQL → AlloyDB.
- Prepare volunteer onboarding pack (roles, access requests, coding standards).
- Draft communications plan (weekly async updates, stakeholder briefs).

## 4. Dependencies & Sequencing

| Task | Depends On |
|---|---|
| Retrieval store deployment | Tech evaluation PoCs |
| Chat API release | Retrieval store + LLM pipeline |
| Streamlit parity | Auth & retrieval pipeline |
| Migration rehearsal | All pipelines + reporting complete |

## 5. Execution Notes
- Use feature flags / environment variables to toggle between Azure and GCP-backed services during transition.
- Maintain `docs/dt-ifg/change_log.md` (to be created) to track major decisions for stakeholders.
- Prefer short-lived branches; merge into `main` with CI (tests + lint).
- Plan tasks in ~10-hour weekly increments; default assumption is one primary contributor with occasional volunteer assist.

## 6. Immediate Next Actions
1. Finalize tech decisions (identity, retrieval, LLM) via PoC results.
2. Scaffold Terraform repo with project + Cloud Run modules.
3. Stand up skeleton FastAPI + Streamlit services with end-to-end auth.
4. Draft migration scripts outline for Azure data exits.

Update this roadmap as tasks complete or priorities shift.
