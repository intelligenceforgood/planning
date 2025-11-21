# Technology Stack Decisions Snapshot

_Last updated: 15 Nov 2025_

This document captures the major technology selections for the i4g platform, along with the outstanding areas that still require evaluation. Update this file whenever a decision changes or a pending item is resolved.

## Committed Decisions

| Domain | Decision | Rationale | Owner | Last Reviewed |
|---|---|---|---|---|
| Identity & Access | Launch on **Google Cloud Identity Platform** (OIDC) with role claims for victim / analyst / admin / LEO. Keep authentik as the long-term self-hosted fallback. | Fastest path to production on GCP, nonprofit pricing, integrates cleanly with Streamlit and FastAPI. Auth layer already abstracts roles so swapping providers later is viable. | Jerry | 11 Nov 2025 |
| Analyst UI | **Streamlit on Cloud Run** behind Identity Platform / IAP; reuse analyst dashboard built in proto repo. | Minimal lift to share MVP search, rapid iteration for analysts, easy to secure with Cloud Run + Identity Platform. | Jerry | 15 Nov 2025 |
| API Gateway & RAG Orchestrator | **FastAPI service on Cloud Run** with LangChain orchestration and shared `settings` package for configuration. | Aligns with existing codebase, strong async support, clean integration with Vertex AI and future self-hosted models. | Jerry | 11 Nov 2025 |
| Retrieval / Search | **Vertex AI Search (Discovery Engine)** as the managed retrieval tier for MVP. Document-level metadata carries `source` / `index_type` tags to keep datasets separable. | Managed relevance tuning, low ops burden, quick ingest from Azure exports. Evaluation showed acceptable latency and relevance for MVP. | Jerry | 15 Nov 2025 |
| LLM Inference | **Vertex AI Gemini 1.5 Pro** as primary chat/summary model. Maintain Ollama profile for offline/local testing. | High quality responses, turnkey IAM integration, consistent latency. LangChain abstraction keeps provider pluggable if we need to pivot to open models. | Jerry | 11 Nov 2025 |
| Structured Storage | **Firestore (Native mode)** for cases, queue, configuration, and PII token metadata. | Already in use, serverless, fine-grained IAM, documented tokenization pattern. | Jerry | 11 Nov 2025 |
| Unstructured Storage | **Cloud Storage buckets** per environment (`i4g-evidence-*`, `i4g-reports-*`) with lifecycle policies. | Direct replacement for Azure Blob, supports signed URLs, easy Terraform automation. | Jerry | 11 Nov 2025 |
| Ingestion & Batch | **Cloud Run Jobs orchestrated by Cloud Scheduler** with Secret Manager credentials. | Container-first approach matches existing code, no servers to manage, integrates with Workload Identity Federation. | Jerry | 11 Nov 2025 |
| Secrets & IAM | **Secret Manager + Workload Identity Federation**, dedicated service accounts (shared `sa-app` runtime plus `sa-ingest`, `sa-report`, etc.) managed via Terraform. | Eliminates long-lived keys, matches security blueprint, tested via dev CI pipeline. | Jerry | 15 Nov 2025 |
| Observability | **Cloud Logging & Monitoring with structured logs**, Error Reporting alerts, and future OpenTelemetry exporters if multi-cloud needs arise. | Native to GCP, minimal setup, already wired for Cloud Run services. | Jerry | 11 Nov 2025 |
| IaC & CI/CD | **Terraform modules** in the `infra` repo with GitHub Actions + Workload Identity Federation for plans/applies. | Keeps infrastructure reproducible, no service-account keys, already validated in dev workflows. | Jerry | 15 Nov 2025 |

## Active Evaluations & Pending Decisions

| Topic | Current Status | Next Step | Target Decision |
|---|---|---|---|
| Analytics / Warehousing | BigQuery deferred during Milestone 2. Need to confirm whether production reporting requires a warehouse or if Firestore exports + notebooks suffice. | Reassess after MVP analyst feedback; document data volume & reporting needs. | Milestone 4 planning |
| Tokenization Storage Backend | PII vault currently designed for Firestore + optional KMS. Need to evaluate whether Cloud SQL or AlloyDB is preferable for high-volume token lookups long-term. | Prototype vault service against Firestore; collect latency metrics; revisit if scale demands change. | Before production cutover |
| Volunteer-Facing Documentation Platform | Options evaluated (GitBook vs MkDocs/Docusaurus); no final pick yet. | Decide based on upcoming volunteer onboarding timeline; coordinate with public_infra_todo checklist. | Prior to public doc site launch |
| Law Enforcement Portal Delivery | Streamlit currently handles read-only reports; consider whether a lightweight Next.js or static site is required for better UX. | Validate needs with stakeholders after MVP search review. | Post-MVP review |
| Long-term Retrieval Strategy | Vertex AI Search selected for MVP; keep AlloyDB + pgvector plan on standby if we need tighter control or cost reductions. | Monitor Vertex AI Search usage & costs, log tuning/GDPR requirements. | Re-evaluate during Milestone 4 |
| Automated Reporting Workflow | DOCX/PDF generator wired into FastAPI, but signature / secure delivery plan still in progress. | Capture requirements (signatures, watermarks, delivery channel); design final workflow in Milestone 3. | Milestone 3 execution |

## Retired or Superseded Options

- **Firebase Authentication** (legacy DT-IFG implementation) — superseded by Google Identity Platform to align with OIDC-first strategy and GCP-native IAM.
- **Azure Cognitive Search** — replaced by Vertex AI Search; exports and transforms tracked in `planning/migration_runbook.md`.
- **Standalone Retrieval PoC plan (`planning/retrieval_poc_plan.md`)** — evaluation concluded with Vertex AI Search as default; future experiments will be logged directly in this decisions file or the change log.

Keep this snapshot close to `planning/change_log.md` so both documents stay consistent. When a pending item is resolved, promote it to the “Committed Decisions” table and record a matching change-log entry.
