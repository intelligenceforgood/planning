# Planning Change Log (active items only)

Last updated: 28 Feb 2026

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2026-02-28.md` (and before that, `archive/change_log_2025-12-14.md`).

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

- **CoreBridge OIDC auth:** Added `_get_oidc_token()` helper (follows `core/worker/jobs/intake.py` pattern) and `_build_auth_headers()` method. CoreBridge now injects an OIDC identity token as `Authorization: Bearer` when the target `core_api_url` is HTTPS. This allows the SSI Cloud Run service to authenticate to the core API behind IAP.
- **CloudSQL backend for ScanStore:** Extended `build_engine()` in `ssi/store/sql.py` to support `storage.backend = "cloudsql"`. Uses `google.cloud.sql.connector.Connector` with pg8000 and IAM auth — same pattern as core. New `_build_cloudsql_engine()` factory reads `cloudsql_instance`, `cloudsql_database`, `cloudsql_user`, `cloudsql_enable_iam_auth` from `StorageSettings`.
- **StorageSettings expanded:** Added `cloudsql_instance`, `cloudsql_database`, `cloudsql_user`, `cloudsql_password`, `cloudsql_enable_iam_auth` fields (env prefix `SSI_STORAGE__`).
- **Dev settings updated:** `config/settings.dev.toml` changed `storage.backend` from `"sqlite"` to `"cloudsql"` and `integration.push_to_core` from `false` to `true`.
- **Infra (dev):** Added `SSI_STORAGE__CLOUDSQL_*` env vars to `ssi_api_env_vars` in `terraform.tfvars`. Granted `roles/cloudsql.client` and `roles/cloudsql.instanceUser` to the SSI service account.
- **Root causes:** (1) Cases not showing on `/cases` page: CoreBridge sent plain HTTP to IAP-protected core API → 403. (2) Investigation history lost on restart: ScanStore used ephemeral SQLite on Cloud Run's filesystem.
- **Tests:** 724 core + 701 SSI unit tests pass.

## 2026-02-24 — SSI Phase 2: Production Readiness (2.1–2.4)

- **2.1 Evidence delivery:** Added `GET /investigations/{id}/evidence-bundle` (ZIP download) and `GET /investigations/{id}/lea-package` (LEA-ready signed ZIP with chain-of-custody manifest). GCS-backed storage returns signed URL redirects; local falls back to direct file serving.
- **2.2 GCS evidence upload:** New `EvidenceStorageClient` in `ssi/evidence/storage.py` with local and GCS backends. Orchestrator uploads evidence directory to GCS after packaging when `SSI_EVIDENCE__STORAGE_BACKEND=gcs`. Factory function `build_evidence_storage_client()` reads from settings.
- **2.3 Core case creation (end-to-end):** Added `POST /cases`, `PATCH /cases/{id}`, `POST /cases/{id}/entities/batch`, `POST /cases/{id}/indicators/batch`, and `POST /cases/{id}/evidence` to core API. `CoreBridge.push_investigation()` creates a case, attaches evidence, stores classification, and creates entity/indicator records. Cases now write to both `cases` and `scam_records` tables so the dashboard join works. Descriptive case titles built from URL domain + taxonomy intent (e.g., "Investment Scam — example.com"). `push_to_core` defaults to `True`.
- **2.4 Redis task store:** Replaced in-memory `_TASKS` dict with pluggable `TaskStore` (in-memory or Redis). New `TaskStoreSettings` with `SSI_TASK_STORE__BACKEND`, `SSI_TASK_STORE__REDIS_URL`, `SSI_TASK_STORE__KEY_PREFIX`, `SSI_TASK_STORE__DEFAULT_TTL_SECONDS` env vars. Singleton factory `build_task_store()`.
- **Bug fixes:** Fixed camelCase key mismatch in CoreBridge (`caseId` vs `case_id`); fixed test DB isolation (test file rewrote with `monkeypatch` + `tmp_path`); added GDPR export/delete endpoints to core cases router.
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
