# SSI–eCrimeX Integration: Development Plan

> **Source PRD**: `planning/prd_ecx_integration.md`
> **Source TDD**: `ssi/docs/tdd_ecx_integration.md`
> **Created**: March 5, 2026
> **Status**: Active

---

## Phase 1 — Consume (Enrichment) · Sprint 1 of 3

**Goal:** Enrich every SSI investigation with eCX community intelligence during passive recon. SSI queries eCX for known phishing URLs, malicious domains, malicious IPs, and criminal wallet addresses — injecting community context into investigation reports and STIX bundles.

**Key Dependency:** eCX API key with module access (phish available now; other modules as granted).

### 1A · Foundation: Settings, Models & Config

- [x] Add `ECXSettings` Pydantic model to `ssi/src/ssi/settings/config.py` (`[ecx]` section)
- [x] Add `[ecx]` defaults to `config/settings.default.toml`
- [x] Add `[ecx]` overrides to `config/settings.local.toml` (with `enabled = false`)
- [x] Write unit tests for `ECXSettings` env-var overrides (`tests/unit/settings/`)
- [x] Create `ssi/src/ssi/models/ecx.py` with Pydantic models: `ECXPhishRecord`, `ECXCryptoRecord`, `ECXMalDomainRecord`, `ECXMalIPRecord`, `ECXEnrichmentResult`, `ECXSubmissionRecord`
- [x] Write unit tests for eCX Pydantic model validation
- [x] Create `ssi/config/ecx_currency_map.json` (SSI token_symbol → eCX currency code mapping)
- [x] Update docs env-var reference with all `SSI_ECX__*` variables

### 1B · API Client: ECXClient (Query Methods)

- [x] Implement `ECXClient.__init__` with base_url, api_key, attribution, timeout
- [x] Implement `_headers()` and `_request()` with `@with_retries` decorator
- [x] Implement `_normalize_keys()` for camelCase → snake_case field mapping
- [x] Implement `search_phish(url)` — POST `/phish/search`
- [x] Implement `search_domain(domain)` — POST `/malicious-domain/search`
- [x] Implement `search_ip(ip)` — POST `/malicious-ip/search`
- [x] Implement `search_crypto(address)` — POST `/cryptocurrency-addresses/search`
- [x] Implement `search_report_phishing(url)` — POST `/report-phishing/search`
- [x] Implement `_get_client()` singleton from settings
- [x] Add graceful degradation: missing API key → skip, module access denied → skip
- [x] Write unit tests for each search method (mocked HTTP)
- [x] Write unit tests for error handling (429, 5xx, timeout, unreachable)
- [x] Write unit tests for key normalization

### 1C · Enrichment Pipeline

- [x] Implement `enrich_from_ecx(url, domain, ip)` top-level enrichment function
- [x] Implement `_safe_query()` helper for isolated per-module fault tolerance
- [x] Implement `enrich_wallets_from_ecx(wallets)` for post-extraction wallet lookup
- [x] Wire `enrich_from_ecx()` into orchestrator `run_passive_recon` phase
- [x] Wire `enrich_wallets_from_ecx()` into orchestrator post-wallet-extraction step
- [x] Write unit tests for enrichment aggregation logic
- [x] Write unit tests for graceful degradation (eCX disabled, key missing, partial failures)

### 1D · Cache Layer

- [x] Create Alembic migration for `ecx_enrichments` table (enrichment_id, scan_id, query_module, query_value, ecx_record_id, ecx_data, confidence, queried_at, cache_expires_at)
- [x] Implement cache read/write in enrichment pipeline (keyed by query_type + query_value + scan_id)
- [x] Implement configurable cache TTL (`cache_ttl_hours`, default 24)
- [x] Write unit tests for cache hit/miss/expiry behavior

### 1E · Report & STIX Integration

- [x] Add "Community Intelligence (eCrimeX)" section to investigation report template
- [x] Render phish hits (eCX record ID, brand, confidence, first seen, count)
- [x] Render malicious domain hits (classification, confidence, submission count)
- [x] Render cryptocurrency hits (crime category, currency, associated sites, report count)
- [x] Render malicious IP hits (description, ASN, confidence)
- [x] Add eCX source attribution as `external_references` in STIX 2.1 indicators
- [x] Enrich wallet manifest with eCX hit status (known/unknown to community)
- [x] Write unit tests for report section rendering
- [x] Write unit tests for STIX bundle eCX references

### 1F · CLI & API Endpoints

- [x] Implement CLI: `ssi ecx search phish <url>`
- [x] Implement CLI: `ssi ecx search domain <domain>`
- [x] Implement CLI: `ssi ecx search ip <ip>`
- [x] Implement CLI: `ssi ecx search crypto <address>`
- [x] Implement API: `GET /ecx/investigate/{scan_id}` — return cached eCX enrichment for an investigation
- [x] Implement API: `POST /ecx/search/phish` — ad-hoc eCX phish search
- [x] Implement API: `POST /ecx/search/domain` — ad-hoc eCX domain search
- [x] Implement API: `POST /ecx/search/ip` — ad-hoc eCX IP search
- [x] Implement API: `POST /ecx/search/crypto` — ad-hoc eCX crypto search
- [x] Write unit tests for CLI commands (mocked client)
- [x] Write unit tests for API endpoints (mocked client)

### 1G · Wallet Allowlist Expansion

- [x] Add XLM (Stellar) regex pattern to `config/wallet_allowlist.json`
- [x] Add XMR (Monero) regex pattern to `config/wallet_allowlist.json`
- [x] Add XZC (Zcoin/Firo) regex pattern to `config/wallet_allowlist.json`
- [x] Add ZEC (Zcash) regex pattern to `config/wallet_allowlist.json`
- [x] Add corresponding JS extraction patterns for browser-side wallet harvesting
- [x] Write unit tests for new wallet regex patterns (valid/invalid addresses)

### 1H · Integration Testing & Validation

- [x] Create test fixtures: `tests/fixtures/ecx_responses.py` with sample eCX API responses
- [x] Write sandbox integration tests (`tests/integration/test_ecx_sandbox.py`, `@pytest.mark.ecx_sandbox`)
- [x] Validate enrichment pipeline end-to-end with sandbox API
- [x] Run full unit test suite — zero failures (783 passed)
- [x] Run `pre-commit run --all-files` — clean pass
- [x] Update `planning/change_log.md` with Phase 1 completion

---

## Phase 2 — Contribute (Submission) · Sprint 2 of 3

**Goal:** Submit SSI investigation findings (scam URLs, wallet addresses, malicious domains, malicious IPs) back to eCX with hybrid governance (auto-submit for high-confidence, analyst review queue for medium-confidence).

**Key Dependency:** Data sharing agreement with APWG (development can proceed against sandbox).

### 2A · Client Extension: Submit Methods

- [x] Implement `ECXClient.submit_phish(url, confidence, brand, ip)` — POST `/phish`
- [x] Implement `ECXClient.submit_crypto(address, currency, confidence, crime_category, site_link, procedure)` — POST `/cryptocurrency-addresses`
- [x] Implement `ECXClient.submit_domain(domain, classification, confidence)` — POST `/malicious-domain`
- [x] Implement `ECXClient.submit_ip(ip, confidence, description)` — POST `/malicious-ip`
- [x] Implement `ECXClient.add_note(module, record_id, description)` — POST `/{module}/{id}/note`
- [x] Implement `ECXClient.update_record(module, record_id, confidence, status)` — PUT `/{module}/{id}`
- [x] Write unit tests for each submit method (mocked HTTP, validate request body construction)
- [x] Write unit tests for add_note and update_record

### 2B · Submission Database

- [x] Create Alembic migration for `ecx_submissions` table (submission_id, case_id, scan_id, ecx_module, ecx_record_id, submitted_value, confidence, release_label, status, submitted_by, submitted_at, error_message, created_at)
- [x] Add CRUD helpers for submission records in scan store or dedicated store
- [x] Write unit tests for submission record CRUD

### 2C · Submission Governance Service

- [x] Implement `ECXSubmissionService.__init__` with client, store, settings
- [x] Implement `process_investigation()` — threshold-based routing (auto-submit / queue / skip)
- [x] Implement `_auto_submit()` — submit all qualifying indicators to eCX
- [x] Implement `_queue_for_review()` — create pending submission records
- [x] Implement `_submit_with_dedup()` — check eCX before submit, update if exists, POST if new
- [x] Implement `analyst_approve(submission_id, release_label, analyst)` — approve + submit queued record
- [x] Implement `analyst_reject(submission_id, analyst, reason)` — reject queued record
- [x] Implement `retract(submission_id, analyst)` — retract a previously submitted record
- [x] Implement SSI field → eCX field mapping for phish submissions
- [x] Implement SSI field → eCX field mapping for crypto submissions (via `ecx_currency_map.json`)
- [x] Implement SSI field → eCX field mapping for malicious domain submissions
- [x] Write unit tests for governance thresholds (auto-submit, queue, skip boundaries)
- [x] Write unit tests for deduplication logic (new vs. existing, confidence comparison)
- [x] Write unit tests for approval/rejection/retraction flows
- [x] Write unit tests for field mapping (phish, crypto, domain)

### 2D · Pipeline Integration

- [x] Wire `ECXSubmissionService.process_investigation()` into post-investigation pipeline
- [x] Ensure submission runs after intelligence synthesis, not during
- [x] Add submission status to investigation result model
- [x] Write unit tests for end-to-end investigation → submission flow
- [x] Validate that submission failures do not block investigation completion

### 2E · API Endpoints for Submission Management

- [x] Implement `GET /ecx/submissions` — list submission queue with status filter
- [x] Implement `POST /ecx/submissions/{id}/approve` — analyst approval with release label
- [x] Implement `POST /ecx/submissions/{id}/reject` — analyst rejection
- [x] Implement `POST /ecx/submissions/{id}/retract` — retract submitted record
- [x] Add request/response models: `ECXApproveRequest`, `ECXSubmissionResponse`
- [x] Write unit tests for all submission API endpoints

### 2F · CLI: Submission Commands

- [x] Implement CLI: `ssi ecx submit <investigation-id>` — manual submission
- [x] Implement CLI: `ssi ecx status <investigation-id>` — check submission status
- [x] Implement CLI: `ssi ecx retract <submission-id>` — retract a submission
- [x] Implement CLI: `ssi ecx submissions` — list submission queue
- [x] Write unit tests for submission CLI commands

### 2G · UI: Analyst Console Changes

- [x] Investigation detail — Results tab: add eCX submission status indicator (Not submitted / Queued / Submitted / Failed)
- [x] Investigation detail — Results tab: release label input + Approve/Reject buttons for queued items
- [x] Investigation detail — Results tab: submission history (timestamp, eCX record ID, module, analyst)
- [x] Investigation list: add filter by eCX submission status
- [x] Investigation list: bulk approve/reject for submission queue (`/ssi/submissions` dedicated queue page)
- [x] Sidebar navigation: Submissions link under Scam Investigator
- [ ] Write component tests for submission UI elements

### 2H · Integration Testing & Validation

- [x] Write sandbox integration tests for submit → verify on sandbox
- [x] Write sandbox integration tests for update and add_note
- [x] Write sandbox integration tests for analyst_reject and retract
- [x] Write sandbox integration test for deduplication end-to-end
- [x] Run full unit test suite — zero failures (855 passed)
- [x] Run `pre-commit run --all-files` — clean double-pass
- [x] Update docs: submission governance guide (`ssi/docs/submission_governance.md`)
- [x] Update `planning/change_log.md` with Phase 2 completion

---

## Phase 3 — Orchestrate (Full Bidirectional) · Sprint 3 of 3

**Goal:** eCX becomes an inbound intelligence source that triggers SSI investigations automatically. Campaign correlation links SSI investigations to eCX records for cross-organizational threat intelligence.

**Key Dependency:** Phase 1 + Phase 2 stable, polling infrastructure, eCX module access for polling targets.

### 3A · Inbound Poller Service

- [ ] Implement `ECXPoller.__init__` with client, settings, investigation trigger callback
- [ ] Implement `poll_module(module)` — query eCX for new records since `last_polled_id`
- [ ] Implement `run_poll_cycle()` — iterate all configured inbound modules
- [ ] Implement polling state tracking: `last_polled_id` per module in database
- [ ] Create Alembic migration for polling state table (module, last_polled_id, last_polled_at)
- [ ] Implement configurable filtering (confidence threshold, brands, TLDs)
- [ ] Implement deduplication against existing SSI investigations
- [ ] Wire poller output to SSI investigation trigger (submit URL for investigation via standard pipeline)
- [ ] Write unit tests for poller core logic (mocked eCX responses)
- [ ] Write unit tests for polling state management
- [ ] Write unit tests for filtering and deduplication

### 3B · Deployment: Cloud Scheduler + Cloud Run Job

- [ ] Create Cloud Run Job definition for eCX poller
- [ ] Create Cloud Scheduler trigger (configurable interval, default 15 min)
- [ ] Add poller job to `scripts/build_image.sh` build targets
- [ ] Add Terraform resources for scheduler + job in `infra/`
- [ ] Add environment variables for poller job (SSI_ECX\_\_\* settings)
- [ ] Write deployment documentation
- [ ] Validate local polling via `ssi ecx poll` CLI
- [ ] Validate Cloud Run Job execution in `i4g-dev`

### 3C · Campaign Correlation

- [ ] Implement wallet-based campaign linkage (same wallet across multiple eCX records)
- [ ] Implement IP/ASN-based infrastructure clustering (shared hosting)
- [ ] Implement brand impersonation pattern detection (coordinated phishing waves)
- [ ] Feed correlation results into core's `campaigns` table
- [ ] Write unit tests for each correlation strategy
- [ ] Write unit tests for campaign record creation

### 3D · CLI: Polling Commands

- [ ] Implement CLI: `ssi ecx poll` — manual trigger for full polling cycle
- [ ] Implement CLI: `ssi ecx poll --module <module>` — poll a specific module
- [ ] Add polling status output (records found, investigations triggered, errors)
- [ ] Write unit tests for polling CLI commands

### 3E · UI: Intelligence Feed & Campaign View

- [ ] New page: eCX Intelligence Feed — live feed of new eCX submissions matching filters
- [ ] Intelligence feed: one-click "Investigate" button → trigger SSI investigation from eCX record
- [ ] Intelligence feed: configurable filters (module, brand, confidence, date range)
- [ ] Campaign view: link SSI investigations to eCX records (shared wallets, IPs, domains)
- [ ] Campaign view: timeline visualization of linked investigations
- [ ] Investigation detail — Recon tab: "Community Intelligence" card showing eCX matches
- [ ] Write component tests for intelligence feed
- [ ] Write component tests for campaign view

### 3F · Trend Dashboard

- [ ] Surface new phish submissions by brand (time series chart)
- [ ] Surface wallet address heat map (most-reported currencies)
- [ ] Surface geographic distribution of malicious infrastructure
- [ ] Write component tests for dashboard widgets

### 3G · Phase 2 Follow-ups

- [ ] Refactor `reject_submission` route to use `_require_submission_service()` factory instead of manual `ECXSubmissionService` construction (consistency with approve/retract routes)
- [ ] Replace private `_get_client` import in `ecx_routes.py` with a public accessor or route-level factory
- [ ] Write component tests for submission UI elements (deferred from Phase 2G)

### 3H · Integration Testing & Validation

- [ ] Write sandbox integration tests for polling + auto-trigger flow
- [ ] Validate campaign correlation with sandbox data
- [ ] End-to-end test: eCX new phish record → poller detects → SSI investigates → results submitted back to eCX
- [ ] Run full unit test suite — zero failures
- [ ] Run `pre-commit run --all-files` — clean pass
- [ ] Update docs: polling configuration guide, campaign correlation guide
- [ ] Update `planning/change_log.md` with Phase 3 completion

---

## Cross-Phase Tasks

These items apply across all phases and should be maintained throughout.

### Security & Compliance

- [ ] Verify API key storage: Secret Manager (GCP) or `.env.local` (local) — never in source/config
- [ ] Verify no PII in eCX submissions (strip synthetic identity data before submit)
- [ ] Verify audit trail: every eCX query and submission logged with timestamp, module, user, response
- [ ] Secure data sharing agreement with APWG before Phase 2 production launch
- [ ] Verify sandbox ↔ production isolation (base_url per environment)

### Test Stability

- [ ] Fix pre-existing flaky core rate-limit tests (`test_response_has_no_job_name_field`, `test_enqueue_with_taxonomy`) — 429/403 due to middleware state leaking between tests

### Documentation

- [ ] Update `docs/config/settings_manifest.yaml` with all `SSI_ECX__*` variables
- [ ] Update `docs/config/settings_manifest.json` with eCX settings
- [ ] Update SSI architecture docs with eCX integration diagram
- [ ] Add eCX integration section to SSI user guide

### Milestone Tracking

| Phase | Sprint | Target Completion | Status      |
| ----- | ------ | ----------------- | ----------- |
| 1     | 1      | TBD               | Not started |
| 2     | 2      | TBD               | Not started |
| 3     | 3      | TBD               | Not started |
