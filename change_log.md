# Planning Change Log (active items only)

Last updated: 22 Feb 2026

This log keeps only decisions that affect future development. Older history lives in `archive/change_log_2025-12-14.md`.

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

## 2026-02-12 — WS-10 Documentation & Planning Alignment (COMPLETE)

- **E67 (Roadmap):** Updated `roadmap.md` — removed stale "Phases 5-6 remaining", added full history of completed consolidation, debt remediation (Round 1), and quality elevation (Round 2) work streams. Marked IAP JWT auth milestone as done.
- **E68 (Broken link):** Fixed two dead links to `data_reset_bootstrap_plan.md` in `change_log.md` — file was completed and removed without being archived.
- **E69 (PubSub):** Replaced PubSub "Task Queue" with Cloud Run Jobs + Cloud Scheduler in `system_topology.py` and `data_pipeline.py`. PubSub was never used; actual async work is Cloud Run Jobs triggered by Scheduler.
- **E70 (Azure SQL):** Removed "Legacy / External" Azure SQL cluster and sync edge from `system_topology.py`. All historical Azure data captured in an import bundle; Azure functionality fully retired.
- **E71 (Placeholder text):** Removed "(Replace the placeholder...)" editorial instructions from `system-topology.md`, `security-model.md`, `data-pipeline.md`. Cleaned placeholder instructions from `architecture/README.md`.
- **E72 (Duplicate book.json):** Deleted redundant outer `docs/book.json`. HonKit uses `docs/book/book.json` (confirmed via `.gitbook.yaml` root + `package.json` scripts).
- **E73 (require_role):** Verified `require_role("admin")` exists in `core/src/i4g/api/auth.py`. Doc reference is accurate — no change needed.
- **E74 (Empty dir):** Removed empty `arch-viz/src/shared/` directory.
- **Quality Elevation Plan Round 2: ALL 10 WORK STREAMS COMPLETE (74 items).**

## 2026-02-12 — WS-7 UI Code Quality & Deduplication (COMPLETE)

- **E43 (SDK mock data):** Extracted ~580 lines of mock data and `createMockClient()` from `packages/sdk/src/index.ts` into `packages/sdk/src/__fixtures__/index.ts`. SDK now ~715 lines.
- **E44 (resolveApi helpers):** Already consolidated in `lib/server/api-client.ts` — no changes needed.
- **E45 (formatDate):** Consolidated 5 duplicate `formatDate()` definitions into `apps/web/src/lib/format.ts`.
- **E46 (getTaxonomyDescription):** Consolidated into `apps/web/src/lib/taxonomy.ts`, re-exported from `search-types.ts`.
- **E47 (ClassificationBadges):** Extracted duplicated classification badge blocks into `apps/web/src/components/classification-badges.tsx`.
- **E48 (SectionLabel):** Created `<SectionLabel>` component in `@i4g/ui-kit`, replaced 13 inline instances in case-intake-form and cases page.
- **E49 (@i4g/config):** Deleted unused `packages/config/` directory.
- **E50 (@i4g/types):** Added `packages/types/src/domain.ts` re-exporting all major SDK types (Dashboard, Search, Cases, Classification, Dossiers, Analytics, Intake, Client).
- **E51 (z.any()):** Replaced all 5 `z.any()` occurrences with `z.unknown()` in SDK schemas and `account-list-service.ts`.
- **E52 (Native inputs):** Created `<Textarea>` component in `@i4g/ui-kit`. Replaced native date/number inputs with `<Input>` in account-list-console and dossiers page. Replaced native textareas with `<Textarea>` in case-intake-form, discovery-search-form, and campaign-form.
- All SDK tests (22) and web app tests (26) pass. `pnpm format` clean.

## 2026-02-12 — WS-6 UI Performance & Bundle Optimization (COMPLETE)

- **E38 (Recharts):** `AnalyticsCharts` loaded via `next/dynamic` (import renamed to `nextDynamic` to avoid collision with route segment `export const dynamic`). `ssr: false` removed since the page is a Server Component; Recharts still lazy-loads via dynamic import.
- **E39 (React.memo):** Wrapped 6 list-item / sub-components in `React.memo`: `SearchResultCard`, `SearchHistoryList`, `SavedSearchesList`, `SearchFilterSidebar`, `DiscoveryResultCard`, `DiscoverySearchForm`.
- **E40 (Dynamic imports):** 6 heavy client components now loaded via `next/dynamic` with loading skeletons: `AnalyticsCharts`, `DiscoveryPanel`, `AccountListConsole`, `CaseIntakeForm`, `SearchHistoryList`, `SavedSearchesList`.
- **E41 (DiscoveryPanel):** Decomposed from 733→290 lines by extracting `discovery-types.ts` (135 lines), `discovery-search-form.tsx` (267 lines), `discovery-result-card.tsx` (145 lines).
- **E42 (use-search-state):** Split into 3 files: `use-entity-filters.ts` (90 lines), `use-saved-search.ts` (96 lines), with the main hook composing them. Entity filter state owned by parent hook, actions delegated to sub-hook.
- `pnpm build` passes cleanly.

## 2026-02-12 — WS-1 Security Hardening II (COMPLETE)

- **E1 (CORS):** CORS origins now configurable via `settings.api.cors_origins` (default `["*"]`). Cloud envs override via `I4G_API__CORS_ORIGINS`.
- **E2 (Auth):** Removed hardcoded `_API_TOKENS` dict. Cloud envs now use Google IAP JWT verification (`X-Goog-IAP-JWT-Assertion`), with `settings.api.key` fallback for service-to-service. Local env keeps `disable_auth=true`. **⚠️ Temp: all authenticated Cloud users get admin role — full RBAC deferred.**
- **E3 (API key leak):** Removed `NEXT_PUBLIC_API_KEY` from all server-side files. Deduplicated `resolveApiBase`/`resolveApiKey` into shared `api-client.ts`.
- **E4 (tfplan):** Removed binary from git; added bare `tfplan` to `.gitignore`.
- **E5 (allUsers):** Removed from Cloud Run invoker in dev + prod. IAP service agent + SAs already handle access. **⚠️ Temp: any user in Google Workspace groups gets full access — proper RBAC deferred.**
- **E6 (Cloud SQL):** Standardized prod fastapi user to truncated `.iam` suffix (matching all other services).
- **E7 (Proxy logs):** Removed `console.log` URL leaks; sanitized error logging.
- All 330 unit tests pass (3 xfail unchanged).

## 2026-02-12 — WS-5 Core Code Organization (COMPLETE)

- Completed E31.
  - Split `src/i4g/settings/config.py` into section modules under
    `src/i4g/settings/sections/` (`basic.py`, `ml.py`, `jobs.py`) plus
    shared root detection in `sections/_paths.py`.
  - Moved validator-heavy logic into `src/i4g/settings/runtime_overrides.py`.
  - `config.py` now focuses on source loading + top-level `Settings`
    orchestration and dropped from 1,500 lines to 359 lines.
  - Preserved compatibility for tests that import private helpers by keeping
    `_detect_project_root()` / `_env_project_root()` wrappers in `config.py`.
  - Validation: `pytest tests/unit/settings` (27 passed) and
    `pytest tests/unit` (332 passed, 1 warning).
- Completed E32, E33, E36, and E37.
  - Extracted review-search coercion/parsing helpers to `i4g.api.review_search_utils`.
  - Added missing package initializers: `src/i4g/reports/__init__.py`,
    `src/i4g/worker/__init__.py`, and `src/i4g/llm/prompts/__init__.py`.
  - Removed legacy `_coerce_bool` re-export adapter from `intake_job_runner.py`.
  - Eliminated deferred circular import in `task_status.py` by introducing
    shared in-memory store module `i4g.task_status_store` used by both API and worker code.
- Completed E34 and E35:
  - Used `pyupgrade --py311-plus` to modernize all 187 production files to
    builtin generics (`dict`, `list`, `tuple`, `set`, `X | None`, `X | Y`)
    and `collections.abc` for ABCs (`Iterable`, `Sequence`, `Iterator`,
    `Mapping`, `MutableMapping`, `Callable`). Used `autoflake` to strip
    now-unused typing imports.
  - Result: **100% of production files use builtin generics**, zero legacy
    `Dict`/`List`/`Optional`/`Tuple`/`Set` remain.
  - Reduced `# type: ignore` from 29 → 17. Removed 12 via explicit typed
    locals (store/sql.py), value narrowing (reports/dossier_uploads.py,
    api/reports.py), and assert guards (services/account_list/exporters.py).
    Remaining 17 are legitimate (optional imports, protobuf \_pb, monkey-
    patching, Pydantic introspection, Alembic).
- **All WS-5 items complete (E31–E37). All acceptance criteria met.**
- Validation: `pytest tests/unit` → 332 passed, 1 warning.

## 2026-02-15 (session 4)

- **WS-10 Dev/Prod Parity — DONE (15/15 items).**
  - D92 (IAP unification): Migrated prod from per-service IAP to LB-based IAP matching dev. Both environments now use `module.global_lb` + `google_iap_web_backend_service_iam_binding` with `internal-and-cloud-load-balancing` ingress.
  - D93 (networking): Added egress IP, NAT, VPC connector to prod.
  - D88 (console parity): Removed `console_enabled` toggle; console is always deployed. Added `min_instances`, `resource_limits`, `I4G_IAP_CLIENT_ID`.
  - Custom domains unchanged for now: dev keeps `*.intelligenceforgood.org`, prod domains left empty until cutover.
  - Removed unused variables: `iap_manage_clients`, `iap_secret_replication_locations`, `console_enabled`.
  - Added `iap_clients` variable to prod with sentinel/validation pattern.
  - Outputs aligned: both envs now have `serverless_egress_ip`, `global_lb_ip`, simplified `iap`.
  - `terraform validate` passes for both dev and prod.

## 2026-02-15 (session 3)

- **WS-10 Dev/Prod Parity — DONE (13/15 items, 2 deferred as architectural decisions).**
  - D80–D87, D89–D90, D94 completed in session 2 (IAM roles, API enablements, variable restructuring, env var management).
  - D91 (outputs.tf alignment): Common outputs (6) are identical. Env-specific outputs (dev egress/LB; prod domain mappings/IAP details) documented as intentional architectural divergence. Added missing descriptions to prod domain mapping outputs.
  - D92 (IAP architecture decision): Documented as intentional. Dev uses LB-based IAP for custom domain/path routing; prod uses per-service IAP. Unification deferred to a dedicated work stream.
  - D88 (console structural differences) and D93 (networking resources) deferred — configuration differences, not parity bugs.
  - All 8 WS-10 acceptance criteria checked.
- **Database modularization — state migration recovery:**
  - Both dev and prod required `terraform state mv` after module refactoring.
  - Dev: admin group SQL user was destroyed during failed apply — will be recreated on next apply (5 adds, 2 changes, 1 destroy).
  - Prod: database + all SQL users destroyed (instance survived due to `deletion_protection = true`). Will be recreated on next apply (7 adds, 1 change). Post-apply: run Alembic migrations and re-grant in-database permissions.

## 2026-02-15 (session 2)

- **Infra modularization — database layer extracted.** Reviewed all 4 Terraform environments (app/dev, app/prod, pii-vault/dev, pii-vault/prod) for copy-paste duplication. Created two new shared modules to eliminate identical code between app/dev and app/prod:
  - **`modules/database/cloudsql`** — Cloud SQL instance + database creation. Replaces the 40-line `database.tf` that was 100% identical between dev and prod.
  - **`modules/database/users`** — Cloud SQL IAM database users (groups + service accounts) with project-level role bindings. Replaces the 130-line `database_users.tf` that was 95% identical between dev and prod. Uses declarative `iam_groups` and `service_accounts` maps with role lists.
  - Both `app/dev` and `app/prod` now use these modules. The only env-specific difference: dev retains a standalone `report_sa_service_usage` binding for `serviceUsageConsumer`.
  - All 4 environments pass `terraform validate`. State migration commands documented in module headers.
  - **pii-vault** environments were left as-is: prod is intentionally simpler (no database/Cloud Run), and dev has no prod counterpart to deduplicate against. The new modules are generic enough for vault adoption when prod gains a database.
- **Remaining duplication assessment:**
  - `locals.tf` (service accounts map) is 100% identical between app/dev and app/prod — acceptable as data definition, not logic duplication.
  - `providers.tf` and `backend.tf` are identical structurally — cannot be modularized (Terraform constraint).
  - `main.tf` has ~70% structural overlap but env-specific wiring (IAP vs LB, networking, org policy) makes modularization impractical without significant redesign.

## 2026-02-15

- **WS-7 complete.** Type Unification & Test Coverage — all 5 items (D79, D47, D55, D55b, D57) done.
  - **D79 (CamelModel):** Created `CamelModel` base class (`i4g.api.camel`) using Pydantic `alias_generator=to_camel`. All API response models in `response_models.py`, `cases.py`, `account_list.py`, `campaigns.py` now inherit from it — JSON output is automatically camelCase. SDK normalize functions removed (~100 LOC). `field_name_translation.md` updated to reflect reduced translation sites.
  - **D47 (Taxonomy consolidation):** `TaxonomyItem`/`TaxonomyAxis`/`TaxonomyResponse` now defined in exactly 1 package (`@i4g/sdk` Zod schemas). `@i4g/types` re-exports from SDK. Inline interfaces removed from taxonomy page. Stale `ui/types/taxonomy.ts` enum file deleted. Dead enum imports removed from SDK. Codegen updated to emit re-exports.
  - **D55 (SDK tests):** 22 vitest tests added for `@i4g/sdk` — covers schema validation (intake, taxonomy, search request date range, case detail), mock client (dashboard, taxonomy, analytics, cases, search, dossiers, verification, detokenize).
  - **D55b (Python unit tests):** 56 new pytest tests for previously untested modules: `utils/coerce.py` (19 tests), `utils/datetime_parse.py` (14 tests), `llm/client.py` (23 tests — provider dispatch, model resolution, error handling).
  - **D57 (Coverage thresholds):** 60% statement threshold configured for `@i4g/sdk` via `vitest.config.ts`. Current coverage: 82.74% statements.
  - Backend: 324 tests pass (up from 268). Frontend: 48 tests pass (26 web + 22 SDK).
- **CamelModel convention:** All new API response models must inherit from `CamelModel` (`from i4g.api.camel import CamelModel`). JSON output is automatically camelCase; Python code uses snake_case field names. Request models remain `BaseModel`.

## 2026-02-14

- **WS-6 complete.** UI Resilience & UX Quality — all 8 items (D39, D40, D42, D45, D48, D49, D51, D58) done.
  - **D39:** 9 `error.tsx` files added across all console pages using shared `ErrorFallback` component from `@i4g/ui-kit`.
  - **D40:** 7 `loading.tsx` skeleton files added (2 pre-existing). All 9 console pages now have loading states.
  - **D42:** Storybook 8.6.15 configured for `@i4g/ui-kit` with `@storybook/react-vite`, Tailwind, and 5 component stories (Button, Card, Badge, Input, ErrorFallback).
  - **D45:** Shared `api-client.ts` with `apiFetch<T>()` consolidates auth boilerplate from 4 server services (~200 LOC of duplication removed).
  - **D48:** `dossier-list.tsx` decomposed (998→367 LOC) into `dossier-utils.ts`, `dossier-components.tsx`, `dossier-verification.tsx`. `search-experience.tsx` decomposed (1324→720 LOC) into `search-types.ts`, `search-filter-sidebar.tsx`, `search-result-card.tsx`.
  - **D49:** Campaign form migrated from raw `<input>`/`<button>` to `Input`/`Button` from `@i4g/ui-kit`.
  - **D51:** Console `layout.tsx` converted to server component; `Navigation` extracted to client component `navigation.tsx`.
  - **D58:** Dashboard "Create incident report" / "Share status snapshot" and Cases "Export status report" buttons disabled with `title="Coming soon"`.
  - All 26 existing tests pass. No new TypeScript errors introduced.

- **WS-5 complete.** CLI Refactor — both items (D22, D27) done. D22 decomposed `bootstrap/dev.py` (2064 LOC) and `bootstrap/local.py` (823 LOC) into focused sub-packages. D27 eliminated `SimpleNamespace` proxy antipattern from all CLI subcommands — 16 files refactored, all callee functions now use explicit keyword-only parameters, all Typer commands pass kwargs directly. 268 tests pass, 3 xfailed.
- **CLI function calling convention:** All CLI callee functions now use `def func(*, param1: type, param2: type)` keyword-only signatures. Do **not** construct `SimpleNamespace` or `argparse.Namespace` objects to call them — pass kwargs directly.

## 2026-02-11

- **WS-3 complete.** Store Consolidation & Factory Discipline — all 4 items (D16, D17, D18, D29) done. ~800 LOC of duplicated raw sqlite3 code removed. `structured.py`, `dossier_queue_store.py`, `intake_store.py` now unified SQLAlchemy implementations. `factories.py` simplified. Module-level `get_settings()` removed from 5 store files. `pii_backfill.py` migrated from `store._conn` to `store.list_all()`. 268 tests pass.
- **`dialect_insert()` helper:** New utility in `sql.py` for cross-dialect upserts. Use `from i4g.store.sql import dialect_insert` when writing INSERT…ON CONFLICT queries.
- **Backward-compatible aliases:** `SqlAlchemyStructuredStore`, `SqlAlchemyDossierQueueStore`, `SqlAlchemyIntakeStore` are all aliases to their unified counterparts. Existing imports continue to work.

## 2026-02-10

- **WS-2 merged and verified.** All 9 items complete, basic dev deployment confirmed.
- **Classification Zod fix:** Backend now omits `classification` key when `None` (instead of sending `null`). Compatible with both old and new SDK. SDK schema updated with `.nullable().optional()` and `.passthrough()`.
- **Entire tool integration:** Added item #16 to all 8 `copilot-instructions.md` files. Rehydration step (#1) now references `.entire/` and `.claud/` for conversation context per commit. Folders are managed by Entire tool — do not modify.
- **Coding standards refresh:** `general-coding.instructions.md` expanded with comprehensive per-language conventions. All 8 copilot instructions item #3 updated with repo-specific highlights.
- **D79 added to WS-7:** "API JSON uses inconsistent casing — need Pydantic `alias_generator` + SDK cleanup" (HIGH severity).

## 2026-02-09 (WS-2 Session)

- **WS-2: API Quality & Contract Alignment — DONE (9/9 items)**
  - **D13:** Split `review.py` (953 LOC) into 4 sub-modules + orchestrator. Backward-compatible re-exports preserved.
  - **D15:** All 13 API routers now have structured logging.
  - **D36:** SDK `searchIntelligence` now throws clear error (was calling non-existent `POST /search`).
  - **D37:** Platform client now forwards `lossBuckets` to backend. `indicatorTypes` confirmed schema-only.
  - **D32:** Added `response_model` to 43/50 endpoints (86% coverage). New `api/response_models.py` with 40+ models.
  - **D38:** Surfaced `classification_result` in `CaseDetail` and dashboard summary.
  - **D60:** `CaseDetail.status` and `priority` now use `Literal` types matching SDK Zod enums.
  - **D46:** SDK endpoint coverage doc at `docs/book/api/sdk_endpoint_coverage.md`.
  - **D61:** Field name translation reference at `docs/book/api/field_name_translation.md`.
  - Tests: 268 passed, 3 xfailed, 0 failures.

## 2026-02-09

- **Phase 3 Remediation Complete**:
  - **D21 (P0 BUG):** Fixed `_apply_environment_overrides` field name (`reports_bucket` → `report_bucket`).
  - **D31:** Fixed 18 test failures + 1 error → 268 pass, 3 xfail. Root causes: ReviewStore API change, exporter mock typo, missing tokenization mock, stale dates, type coercion.
  - **D23/D24:** Removed 9 unused deps, added 3 missing explicit deps (`sqlalchemy`, `jinja2`, `pyyaml`).
  - **D25/D35:** Removed dead entry points (`run-dataflow`, `i4g-admin`).
- **Phase 4 Complete — UI Frontend Review**:
  - Full audit of SDK, 9 console pages, ui-kit, types, formatting, tests — 26 new debt items (D36-D61).
  - Remediated 8 quick-win items: D43 (barrel drift), D44 (type exports), D50 (dead code), D52 (tsconfig pattern), D53 (color typo), D54 (duplicate tests), D56 (peer dep), D59 (dead app).
  - Fixed runtime React duplicate key error on Accounts page (smoker test runs sharing `request_id: "unused"`).
  - Verified: `pnpm format` clean, Vitest 26/26 passing, no TypeScript errors.
- **Consolidation Sprint Status:** Phases 1-4 complete. 19 of 61 debt items resolved. Phases 5-6 remaining.

## 2026-02-08

- **Consolidation Sprint Launched**: Created comprehensive 6-phase quality plan at `planning/tasks/consolidation_plan.md`.
- **Phase 1 Complete — Streamlit Retirement**:
  - Deleted `core/src/i4g/ui/` (~2,800 LOC), `core/docker/streamlit.Dockerfile`, `core/tests/adhoc/analyst_dashboard_demo.py`.
  - Removed `streamlit>=1.51.0` from `pyproject.toml` and regenerated `requirements.txt`.
  - Removed all Streamlit Terraform resources from both dev and prod (`module.run_streamlit`, `module.iap_streamlit`, variables, outputs, tfvars, IAP scripts).
  - Updated 20+ doc files across `core/docs/`, `docs/book/`, `ui/docs/`, `infra/` READMEs. Zero Streamlit references remain outside `planning/`.
  - Cleaned 3 residual Firestore references (drawio, cookbook, SVG diagram).
  - **Decisions:** Ollama/ChromaDB kept as local-dev-only (laptop-first); `dtp/` left as-is.
- **Phase 2 Complete — Design & Architecture Doc Alignment**:
  - PRD updated to v2.0, architecture.md to v2.0 (14 fixes).
  - `data_model.md` rewritten from 17-line stub to comprehensive 17-table schema reference.
  - `iam.md` updated to disclose prototype API-key auth layer vs. IAP infrastructure.
  - Fixed `storage.md`, `jobs.md`, `rag.md`, `fraud_taxonomy_tdd.md` against actual implementation.
  - `arch-viz/` diagrams corrected (Firebase Auth → IAP, Chatbot → Intake Form).
  - `roadmap.md` changed from "Paused" to "Active" with consolidation sprint progress.
  - **Action items logged:** Replace API-key auth with IAP JWT verification; wire RAG pipeline to `settings.llm.provider`.
- **UI Mockup Sprint Closed**: All 9 console pages (Dashboard, Search, Cases, Taxonomy, Analytics, Reports/Dossiers, Accounts, Campaigns, Discovery) verified as fully connected to live backend endpoints. Zero `MOCK_` constants remain in production UI source. Deleted `planning/ui_mockup_assessment.md` — sprint complete.
- **Mock Fallback Removal (Full UI Cleanup)**: Removed all runtime mock fallback paths from `ui/apps/web/src/`.
  - **`i4g-client.ts`**: Deleted `getMockClient()`, `withMockFallback()`, and all `NEXT_PUBLIC_USE_MOCK_DATA` / `NEXT_PUBLIC_ENABLE_MOCK_FALLBACK` branching. `resolveClient()` now throws if no API URL is configured.
  - **`platform-client.ts`**: Removed `createMockClient` import, the `{ ...mock, ...restClient }` spread pattern, and the mock catch-fallback in `searchIntelligence`.
  - **`account-list-service.ts`**: Deleted `MOCK_RUNS` and `MOCK_RESULT` constants. `getAccountListRuns()` and `triggerAccountListRun()` now throw instead of silently returning fake data.
  - **SDK (`@i4g/sdk`)**: `createMockClient()` retained but marked test-only via JSDoc. No production code imports it.
  - **Env files**: Removed `NEXT_PUBLIC_USE_MOCK_DATA` from `.env.example` and `.env.local`.
  - **Planning**: Updated `ui_mockup_assessment.md` with completed removal status.
- **Search History Integration** (`ui/`): Removed static mock fallbacks (`MOCK_HISTORY`, `MOCK_SAVED_SEARCHES`) from `reviews-service.ts`. `getSearchHistory()` and `listSavedSearches()` now return empty arrays when the backend is unreachable instead of fake data. Backend `GET /reviews/search/history` verified working with real audit entries from `ReviewStore.get_recent_actions(action="search")`. Updated `ui_mockup_assessment.md` to mark task as completed.
- **Firestore Removal (Full Workspace Cleanup)**:
  - **Assessment**: Confirmed zero Firestore client code exists anywhere in the codebase. The `google-cloud-firestore` pip dependency was completely unused. `StorageSettings.structured_backend` Literal was already `['sqlite', 'cloudsql']`.
  - **Source** (`core/src/i4g/`): Removed orphaned `firestore_project` from `_apply_environment_overrides`, removed `_ingestion_bool("enable_firestore", ...)` block, updated CLI help text in `bootstrap/dev.py`, `bootstrap/local.py`, and `settings/manifest.py`.
  - **Settings** (`core/config/`): Removed `firestore_project` and `enable_firestore` from `settings.local.toml`, `settings.default.toml`, `settings.dev_network_smoke.toml`, `settings.network_smoke.toml`.
  - **Dependencies**: Removed `google-cloud-firestore` from `pyproject.toml` and regenerated `requirements.txt` via `pip-compile`.
  - **Manifests**: Regenerated `settings_manifest.{json,yaml}` in both `core/docs/config/` and `docs/config/` via `i4g settings export-manifest --docs-repo ../docs`.
  - **Tests**: Updated `test_ingestion_retry_store.py` and `test_ingest_job_retry_helpers.py` (`backend="firestore"` → `"cloudsql"`).
  - **Docs** (`core/docs/`, `docs/`): Cleaned ~100+ references across architecture, compliance, TDD, dev guide, glossary, smoke tests, cookbooks, config README, IAM, drawio cookbook, runbooks, and fraud taxonomy docs. Replaced Firestore with Cloud SQL / PostgreSQL references.
  - **Arch-viz**: Updated `system_topology.py`, `security_model.py`, `data_pipeline.py` to use `SQL` icon instead of `Firestore`.
  - **Copilot instructions**: Updated all 7 repo-level `.github/copilot-instructions.md` files.
  - **Migration scripts**: Marked `fix_and_run.sh` and `run_migration.sh` as deprecated with `exit 1`.
  - **Intentionally untouched**: `dtp/` (legacy archive), `infra/environments/app/prod/main.tf` (Terraform state — separate deprecation task).

## 2026-02-06

- **Account List Fixes (Dev Environment)**:
  - **Config**: Renamed `REPORTS_BUCKET` to `REPORT_BUCKET` (singular) across codebase and Terraform to enforce naming conventions.
  - **GCS Access**: Fixed 403 Forbidden errors by adding `roles/storage.objectAdmin` to Cloud Run SA. Implemented robust artifact link generation (Signed URL -> Authenticated Browser Link fallback) to handle missing credentials gracefully.
  - **Reliability**: Configured explicit `gemini-2.0-flash` model for Vertex AI in `dev`. Removed silent mock fallbacks in `AccountEntityExtractor` to ensure hard failures on LLM errors.

- **Discovery Integration & Mock Removal**:
  - **Decision**: Eliminated all static mock fallbacks for Discovery.
    - Frontend (`/api/discovery/search`) now returns a `503` if `I4G_API_URL` is missing, instead of fake data.
    - Backend (`_local_discovery_search`) now raises explicit exceptions if `HybridSearchService` fails (e.g., missing artifacts), instead of returning a static mock.
  - **Goal**: Ensure developers see real integration errors in critical path rather than masking them with "Mock hits".

- **Analytics & Reporting Redesign**:
  - **Status**: Completed.
  - **Backend**: Verified `GET /analytics/overview` returns schema-compliant real data.
  - **Frontend**: Full redesign of `ui/apps/web/src/app/(console)/analytics`.
    - Aligned visual style with Case Workspace (Shell, Typography).
    - Replaced custom icons with standard `@i4g/ui-kit` Badges.
    - Added `force-dynamic` rendering and loading skeletons.
  - **Integration**: Removed static mocks; page now relies on live API data (falling back only on explicit env config).

- **Bootstrap Consolidation**:
  - **Completed**: Unified bootstrap seeding logic, eliminating the standalone properties of `seed_cases.py`.
  - **Enhancements**:
    - Integrated seeding into `i4g bootstrap` for both `local` and `dev` environments.
    - Updated `ingest-job` and `fastapi` Docker images to include mock fixtures for consistent artifact serving.
    - Added `seed_reviews` support to `dev.py` and `admin/seed.py`.
  - **Cleanup**: Deleted legacy `core/scripts/seed_cases.py`.
  - **Verification**: Confirmed parity between local and dev seeding processes.

## 2026-02-05

- **Standardization: Review Queue Statuses**:
  - **Decision**: Standardized status lifecycle across Backend, UI, and Docs to eliminate legacy/conflicting terms (active/blocked vs in_review/awaiting_input).
  - **Status Set**:
    - `new` (Triage)
    - `in_review` (Active investigation)
    - `awaiting_input` (Blocked external)
    - `accepted` (True Positive / Fraud)
    - `rejected` (False Positive / Safe)
    - `closed` (Admin/Duplicate)
  - **Impact**: Database schema migration (`review_queue.status` default=`new`), API filters update (`dashboard.py` excludes all 3 terminal states), and UI badge colors/filters updated.

## 2026-02-03

- **Case Workspace Implementation**:
  - **Backend**: Implemented `GET /cases/{id}` endpoint in `core.api.cases` serving structured mock data (Phase 1).
  - **Frontend**: Created `cases/[id]` detailed view with timeline, artifacts, and graph components.
  - **Integration**: Connected Case List "Open Case" button to the new view; full end-to-end data flow verified.

## 2026-02-02

- **Dashboard Backend & Build Stability**:
  - **Backend (Analytics)**: Implemented real analytics queries in `core` (Detection Rate, SLA, Trend lines) leveraging `i4g.store.sql`, replacing static mock responses.
  - **Frontend (Build)**: Resolved a critical build failure in `ui/apps/web` where a stale `.next` cache was serving legacy "Trafficking" taxonomy data, causing Zod schema validation errors.
- **Performance & UX (Cold Starts)**:
  - **Infrastructure**: Updated `infra/environments/app/dev/main.tf` to set `min_instances = 1` for `fastapi-gateway` and `i4g-console`. This prevents scale-to-zero latency (~15s) for the initial request.
  - **UX**: Added `ui/apps/web/src/app/(console)/search/loading.tsx` to provide an immediate skeleton UI response while data fetches, fixing the "unresponsive click" perception during page transitions.

## 2026-01-05

- **Performance Optimization (Classification Sweeper)**:
  - **Job Architecture**: Implemented asynchronous `classification-sweeper` Cloud Run Job to decouple ingestion from LLM latency.
  - **Stability Fixes**:
    - Updated `FraudClassifier` to handle empty JSON responses from LLM (treating them as valid "Unspecified" results rather than failures).
    - Fixed batch sizing logic to align fetch/classify/ensure-campaign steps.
    - Added Markdown code-block stripping to JSON parser for better LLM output resilience.
  - **Result**: Reduced classification error rate from ~35% (synchronous) to <0.2% (asynchronous/batched).

## 2026-01-04

- **Fraud Taxonomy (Phase 5)**:
  - **Database Schema**: Added `campaigns` table and updated `cases` table to store structured `FraudClassificationResult` (JSON) and link to campaigns.
  - **Campaign Logic**: Implemented `CampaignService` to map classification results (intents, actions, etc.) to campaigns based on taxonomy criteria.
  - **Integration**: Completed backend integration for persisting classification results and linking them to campaigns.

## 2026-01-02

- **Dev Environment Stabilization**:
  - **IAM**: Granted `roles/serviceusage.serviceUsageConsumer` to `sa-report` to fix 403 errors during report generation.
  - **Configuration Cleanup**: Removed all legacy `STORAGE__CLOUDSQL` variables from code and documentation. Standardized on `APP__CLOUDSQL` and `PII__CLOUDSQL`.
  - **Job Specs**: Fixed `seed_reviews` job in `dev.py` to explicitly use `sa-report` (was defaulting to `sa-ingest`).
  - **Local Verification**: Updated `settings.local.toml` to use the developer's active account (`jerry@...`) for Cloud SQL verification, aligning with local ADC credentials.

## 2025-12-31

- **Search & Infrastructure Fixes**: Resolved multiple "500 Internal Server Error" issues in `fastapi-gateway`.
  - **Backend (Vertex AI)**: Updated `VertexVectorStore` to robustly handle `struct_data` from Vertex AI Search. Implemented `MessageToDict` with a fallback for `MapComposite` objects (which lack `DESCRIPTOR`) to prevent `AttributeError` and JSON serialization crashes.
  - **Backend (ReviewStore)**: Added missing `ensure_placeholder_review` method to `SqlAlchemyReviewStore` to fix crashes in the search audit logging flow.
  - **Infrastructure**: Verified that `TOKENIZATION` environment variables were correctly renamed to `PII` in Terraform (`infra/environments/app/dev/main.tf`), resolving Cloud SQL connection failures.

## 2025-12-28

- **PII Vault Implementation**:
  - **Schema Isolation**: Separated PII Vault schema from main application schema. Created `VAULT_METADATA` in `sql.py` and a dedicated Alembic environment (`migrations_vault/`, `alembic_vault.ini`) to manage the `pii_tokens` table independently.
  - **Infrastructure**: Provisioned Cloud SQL instance `i4g-vault-dev-db` and KMS key ring `pii-vault-keyring` via Terraform.
  - **Migration**: Generated and applied initial schema migration for PII Vault. Verified isolation (only `pii_tokens` table exists in the vault DB).

- **OCR & Ingestion**:
  - Added PDF support to OCR pipeline via `pypdfium2`.
  - Added error handling for corrupt files in `tesseract.py` to prevent job crashes.
  - Added `--ingest-dry-run` flag to `i4g bootstrap dev` to allow testing extraction logic without DB writes.

## 2025-12-26

- **Search & Save Fixes**: Resolved "401 Unauthorized" and "500 Internal Server Error" issues in Search and Saved Search flows.
  - **Backend**: Updated `VertexVectorStore` to robustly handle `struct_data` vs `json_data` from Vertex AI Search. Renamed `save_search` to `upsert_saved_search` in `ReviewStore` to match API calls and fix FK constraints.
  - **Frontend**: Patched Next.js API routes (`reviews/saved`, `intakes`) to inject IAP OIDC tokens (`Authorization: Bearer ...`) alongside App API keys (`X-API-KEY`).
  - **SDK**: Updated `@i4g/sdk` to send API keys in `X-API-KEY` header instead of `Authorization` to avoid conflict with IAP tokens.
  - **Deployment**: Rebuilt and redeployed both `fastapi-gateway` and `i4g-console` to `dev`.

## 2025-12-24

- **Infrastructure**: Added Cloud SQL (PostgreSQL 15) provisioning to Terraform (`infra/environments/app/dev/database.tf`) including database and user management.
- **Security & Auth**: Addressed "403 Forbidden" errors in `i4g-console` by fixing OIDC token generation in `auth-helpers.ts`.
  - Identified that `google-auth-library` requires explicit `audience` parameter in `getRequestHeaders` to generate tokens.
  - Updated `ui/apps/web/src/lib/server/auth-helpers.ts` to include the fix.
  - Reverted `i4g-console` ingress to `internal-and-cloud-load-balancing` for security.
- **Documentation**: Added `docs/cookbooks/cloud_sql_primer.md` and updated `docs/cookbooks/bootstrap_environments.md`.

## 2025-12-22 (Session 2)

- **Security & Auth**: Fixed "401 Unauthorized" errors in `i4g-console` by implementing IAP-aware authentication for server-side API calls.
  - Injected `I4G_IAP_CLIENT_ID` into `i4g-console` Cloud Run service via Terraform.
  - Updated `platform-client.ts`, `account-list-service.ts`, and `reviews-service.ts` to generate OIDC tokens using `google-auth-library`.
  - Rebuilt and redeployed `i4g-console` image.
  - Verified `I4G_API_KEY` is correctly set in `terraform.tfvars` to ensure FastAPI authorization.
  - Confirmed `sa-app` service account has `roles/iap.httpsResourceAccessor` on the API backend.

## 2025-12-22

- **Bootstrap Fixes**: Resolved Cloud Run job failures in `dev_bootstrap` by fixing Docker entrypoints (switched `CMD` to `ENTRYPOINT`) and updating ingestion logic to support GCS directory paths (prefixes) for bundles.
- **Report Directory Refactor**: Standardized report output directories to `data/reports/bootstrap_dev` and `data/reports/bootstrap_local` (renamed from `dev_bootstrap`/`local_bootstrap`). Updated all CLI tools and documentation to reflect this change.
- **Documentation**: Updated `docs/cookbooks/bootstrap_environments.md` with correct job names, verification commands, and bundle URI formats.

## 2025-12-19

- Fixed Cloud Run job authentication: `process-intakes` now generates OIDC tokens for service-to-service calls to the API gateway.
- Updated `i4g bootstrap dev verify` to support IAP-protected environments by injecting local identity tokens.
- Refined bootstrap documentation: separated bundle preparation into [core/docs/cookbooks/prepare_bootstrap_bundles.md](../core/docs/cookbooks/prepare_bootstrap_bundles.md) and clarified smoke test expectations.

## 2025-12-11

- Repo rename to `core/` is complete. Flip any remaining `proto` references and use `I4G_API_KIND=core` going forward.

## 2025-12-16

- Data reset/bootstrap plan established for local + dev environments. Canonical bundles live in GCS with manifests; CLI flows support wipe/import/verify across all storages. Plan completed and removed.
- Local bootstrap verification now emits a bundle manifest hash and ingestion-run summary to catch stale datasets early.
- Optional dossier signature smoke added to local bootstrap (`--smoke-dossiers`) for end-to-end verification when API is up.
- Completed the data reset/bootstrap sprint plan; all checklist items done.

## 2025-12-10

- PII vault finalized: deterministic `AAA-XXXXXXXX` tokens, sharded GCS layout, and cross-project Secret Manager/KMS bindings
  captured in [core/docs/design/pii_vault.md](../core/docs/design/pii_vault.md). Cloud Run must read pepper/key via env vars.

## 2025-12-06

- LEA dossier flow: portal download + verification parity (API proxy + Web Crypto); nightly smoke covers `/reports/dossiers`.
  Use the signature manifest contract in [core/docs/design/architecture.md](../core/docs/design/architecture.md) for any new report work.

## 2025-12-02

- Hybrid search + structured filters are baseline: Vertex AI Search + SQL dual-write with retry queue. See ingestion settings in
  `config/settings.*.toml` and the retrieval contracts in [core/docs/design/architecture.md](../core/docs/design/architecture.md).
