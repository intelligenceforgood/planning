# Milestone 1 – Account List Extraction Parity

**Status:** Planning → Implementation</br>
**Date:** 25 Nov 2025

This document details the gap closure work required to port the legacy Azure Functions (`account_list_extract` and `account_list_extract_client`) into the proto stack. It decomposes Milestone 1 into concrete deliverables across services, APIs, workers, and documentation so engineering can execute confidently.

---

## 1. Goals & Success Criteria

1. **Functional Parity** – Reproduce the legacy workflow end-to-end:
   - Accept analyst requests (or scheduled jobs) for account extraction over a date range.
   - Retrieve relevant case documents (intake forms + message archives).
   - Use LLM prompts to extract financial accounts, crypto wallets, and payment handles.
   - Return normalized results plus the supporting source documents.
   - Generate scheduled reports (PDF + XLSX) and publish them to our evidence store.
2. **Platform Alignment** – Integrate with proto components:
   - Use `HybridRetriever` + structured storage rather than Azure Search.
   - Use the existing LLM provider abstraction (Ollama locally, Vertex/Gemini later).
   - Store results in Firestore/Cloud SQL (when Dual Extraction lands) and Cloud Storage, not ad-hoc drives.
3. **Security & Operability** – Enforce API auth, structured logging, and configuration through `i4g.settings`. No secrets hard-coded; prefer Secret Manager and env overrides.

Success is achieved when an analyst (or scheduled Cloud Run job) can call the new endpoint/job and receive the same type of CSV/PDF artifacts the Azure workflow produced, using only proto infrastructure.

---

## 2. Current vs Target State

| Capability | Legacy (Azure Functions) | Proto (Current) | Target in Milestone 1 |
|------------|--------------------------|------------------|------------------------|
| Search backend | Azure Cognitive Search via `SEARCH_API_URL` | HybridRetriever (SQLite + Chroma) only used by analyst review | New `FinancialEntityRetriever` built on HybridRetriever with category-specific prompts & filters |
| Entity extraction | GPT-4o via Azure OpenAI + hard-coded system prompts | No equivalent | Use LLM provider from `settings.llm` (Ollama locally, Vertex AI in cloud) with managed prompts |
| Source documents | Groups.io archives + intake forms from Azure search index | Structured store + Firestore cases + `data/` bundles | Structured store plus ingestion metadata; adapter for OCR bundles if needed |
| API auth | Custom API key validation via Azure Key Vault | FastAPI uses OAuth/in-memory tokens | Add `account_list` router using FastAPI deps (api key header validated via Secret Manager/Settings) |
| Scheduled export | Azure Function `account_list_extract_client` uploads to Google Drive folder, semi-monthly cadence | None | Cloud Run job `i4g-account-export` writing PDF/XLSX to Cloud Storage + optional Drive push |

---

## 3. Proposed Architecture

### 3.1 Service Components

```
account_list_service/
  ├── queries.py              # category definitions + prompts + filters
  ├── retriever.py           # wraps HybridRetriever w/ date + dataset filters
  ├── llm_extractor.py       # handles prompt execution + chunking + retries
  ├── models.py              # Pydantic schemas for requests/responses/entities
  ├── service.py             # orchestrates retrieval → LLM extraction → validation
  └── exporters.py           # builds CSV/XLSX/PDF + writes to storage/Drive
```

Key design points:
- **Query Catalog** – YAML/JSON-driven categories (bank, crypto, payments, plus future IP/ASN) so new signals can be added without code changes.
- **Retriever Adapter** – Accept filters (`start_time`, `end_time`, dataset type) and call `HybridRetriever.query` with tuned `top_k` per category.
- **LLM Extractor** – Uses `settings.llm`; chunking + JSON parsing similar to legacy but standardized (leveraging LangChain or direct client). Should support streaming/backoff and produce structured dicts.
- **Validation Layer** – Normalizes outputs into unified schema (`FinancialIndicator` with `item`, `type`, `number`, `source_case_id`). Deduplicate results and ensure every indicator references at least one source doc/case.
- **Storage** – Persist extraction runs (request metadata + results) in structured store / Firestore for auditability and to power Milestone 2 dual-write once SQL is ready. Artifacts (PDF/XLSX) land in the reports bucket with signed URLs stored alongside metadata.

### 3.2 API & Worker Flows

1. **FastAPI Endpoint** `POST /accounts/extract`
   - Request body: `{ "top_k": 100, "start_time": "2025-11-01T00:00:00Z", "end_time": "2025-11-15T23:59:59Z", "categories": ["bank", "crypto", "payments"] }`
   - Auth: API key header validated against Secret Manager secret (`ACCOUNT_LIST_API_KEY`).
   - Response: `{ "request_id": "acc-run-20251115", "items": [...], "sources": [...], "artifact_paths": {...} }`
   - Rate limited via existing middleware; logs all actions via `ReviewStore.log_action` or new audit hook.

2. **Cloud Run Job** `i4g-account-export`
   - Runs semi-monthly (1st & 15th) via Cloud Scheduler.
   - Calls internal service (shared module) to execute extraction.
   - Generates PDF (sources) + XLSX (items) with ReportLab/OpenPyXL analogs, uploads to Cloud Storage (`reports_bucket/account-drops/<period>/...`). Optional Drive upload flag via settings for compatibility with existing workflows.
   - Emits summary to Cloud Logging + stores run metadata in structured store for analyst UI.

3. **Analyst Console Integration**
   - Add sidebar action “Generate Account List” that hits the API endpoint (immediate run) and links to latest reports stored in Cloud Storage.
   - Surfaces structured results inside dashboard filters, setting the stage for Milestone 3 hybrid search enhancements.

### 3.3 Extensibility Hooks

- **Indicator Registry** – Entities are keyed by `indicator_type` (bank_account, crypto_wallet, payment_handle, ip_address, browser_agent, asn, etc.). Config file controls prompts + query strings + heuristics.
- **Tool Plugins** – Agentic reporting (Milestone 4) can register new exporters (maps via `folium`, charts via `altair`, etc.) without touching extraction core.
- **Diagram Links** – Architecture + data-flow diagrams for this service will live in Figma/Miro. Markdown docs will link out rather than embedding ASCII.

---

## 4. Implementation Breakdown

1. **Service Skeleton (Day 1)**
   - Create `i4g/services/account_list/` package with Pydantic models, query catalog, and stubbed service class.
   - Wire settings + dependency injection (LLM client, retriever, storage).

2. **Retriever + LLM Integration (Day 2-3)**
   - Build `FinancialEntityRetriever` using HybridRetriever with dataset + date filters.
   - Implement `AccountEntityExtractor` that runs prompts per category, handles chunking/backoff, and validates JSON outputs.

3. **FastAPI Router (Day 3-4)**
   - Add `/accounts` router with API key dependency + request validation.
   - Unit tests covering happy path + auth errors.

4. **Artifact Exporters (Day 4-5)**
   - Port PDF/XLSX generation (ReportLab/Pandas) into shared utility (no Google Drive dependency yet; write to Cloud Storage/reports dir, optional Drive upload via service account JSON if configured).
   - Provide signed URL helper for analyst UI.

5. **Cloud Run Job + Scheduler (Day 5-6)**
   - Add `i4g.worker.jobs.account_export` entrypoint (mirrors legacy schedule) plus Terraform wiring + script updates.
   - Job uses same service as API but writes run summary to structured store and logs to Cloud Logging.

6. **Docs & Change Log (Day 6)**
   - Update `planning/roadmap.md`, `gap_analysis.md`, and `proto/docs/architecture.md` to reflect new component.
   - Add ADR-style note to `planning/change_log.md` summarizing Milestone 1 implementation.

### 4.1 Progress Checkpoint (26 Nov 2025)

- ✅ Service package (`i4g.services.account_list`) in place with retriever, extractor, exporter, and orchestrator.
- ✅ FastAPI router `/accounts/extract` with API-key guard and `AccountListRequest/Result` validation.
- ✅ Cloud Run job entrypoint (`i4g.worker.jobs.account_list`) plus smoke-test instructions (local + GCP).
- ✅ Streamlit console wired with Account List form/results and optional Vertex search panel auto-hide.
- ✅ Manual smoke (`tests/adhoc/account_list_export_smoke.py`) proving the exporter path and artifacts (CSV/JSON/XLSX/PDF).
- ✅ Dev Cloud Run smoke (27 Nov) produced populated XLSX/PDF artifacts via the mock extractor with data baked into the new smoker image.
- 🚧 Remaining items: prod-grade dataset validation and Drive/GCS promotion hardening in Cloud Run.

---

## 5. Open Questions / Risks

1. **Data Sources** – Need confirmation on where the Groups.io + intake content now resides (Firestore? Cloud Storage?). For planning we assume ingestion pipeline stored them in structured store. Action: verify with current data dumps under `data/bundles` and Firestore schema.
2. **LLM Provider Limits** – Local dev uses Ollama (LLama3) which may produce inconsistent JSON. Plan to wrap responses with robust parsing + optional `json_mode` when Vertex AI is available.
3. **Google Drive Dependency** – Legacy workflow delivered files to a Drive folder. Recommend replacing with Cloud Storage + signed URLs; Drive upload remains optional to avoid managing service account keys.
4. **API Key Management** – Need decision on whether to keep simple static key (Secret Manager) or tie into Identity-aware proxy sooner. For Milestone 1 we can accept key-based auth with rotation via CLI.

---

## 6. Next Actions

1. **Structured data validation** – Run targeted queries (HybridRetriever + manual inspection) to confirm bank/crypto/payment cases exist for November range; document findings + gaps in `planning/change_log.md`.
2. **Dev Cloud Run smoke** – Execute the `account-list` job in `i4g-dev` (dry run, then full export), capture artifact URLs, and add notes to the change log. Update Terraform/env vars if additional configuration surfaced.
3. **Analyst console polish** – Add artifact link list + status table fed by API responses to streamline analyst review; file any follow-up UI issues needed for Milestone 2.
4. **Docs sync** – Extend `proto/docs/architecture.md` and `planning/roadmap.md` with the new account list service topology, marking Milestone 1 deliverables as implemented.

Once these steps begin, update the TODO tracker and change log accordingly.
