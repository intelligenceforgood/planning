# SSI + AWH Consolidation — Phased Roadmap

> Multi-phase implementation plan for merging SSI and AWH into a unified product.
> Each phase is self-contained and delivers incremental value.

## Phase Overview

| Phase | Title                             | Duration  | Dependencies |
| ----- | --------------------------------- | --------- | ------------ |
| **0** | Alignment & Planning              | 1 week    | None         |
| **1** | Port AWH Browser Engine to SSI    | 2–3 weeks | Phase 0      |
| **2** | Wallet Extraction Pipeline        | 1–2 weeks | Phase 1      |
| **3** | Data Schema & Storage Integration | 2 weeks   | Phase 1      |
| **4** | Playbook Engine                   | 1–2 weeks | Phase 1      |
| **5** | UI: Live Monitoring & Guidance    | 2 weeks   | Phases 2, 3  |
| **6** | GCP Deployment & Terraform        | 2 weeks   | Phases 3, 5  |
| **7** | Evidence & Reporting Enhancements | 1–2 weeks | Phases 2, 3  |
| **8** | Testing, Hardening & Docs         | 2 weeks   | All above    |

**Estimated total**: 13–18 weeks (3.5–4.5 months)

---

## Phase 0: Alignment & Planning (1 week)

Resolve open questions, align on technical decisions, finalize data requirements from PDF slides.

- [x] User reviews AWH analysis report and provides feedback
- [x] User provides data requirements from slides 12–17 (eCX API endpoints: `/phish`, `/mal_domain`, `/crypto`, etc.)
- [x] Review and finalize the merge plan decisions (browser engine, LLM strategy, state machine vs loop)
- [x] Decide on zendriver vs Playwright as primary active-interaction engine → **Dual engine**
- [x] Decide on LLM provider strategy → **Gemini Flash (primary), Gemini 2.5 Pro (escalation), Ollama (local). Claude dropped.**
- [x] Decide on proxy infrastructure → **Decodo premium from day one**
- [x] Confirm `ssi/` repo as the merge target (vs. a new repo) → **ssi/ confirmed, inter-repo deps OK**
- [x] ~~Create `ssi-awh` branch for consolidation work~~ → **Skipped — sole developer, no coordination overhead; working directly on main**
- [x] Install zendriver in `i4g-ssi` conda env and verify basic functionality → **zendriver 0.15.2 installed; headless smoke test passed (example.com title + body extraction). Added to `ssi/pyproject.toml` deps.**
- [x] Write `06_flexible_scan_research.md` and `07_gemini_vision_research.md` → **Done** (actual filenames: `06_browser_interaction_research.md`, `07_gemini_vs_claude_vision_research.md`)

---

## Phase 1: Port AWH Browser Engine to SSI (2–3 weeks)

Bring AWH's battle-tested browser agent (state machine, DOM Inspector, click/type strategies) into SSI's module structure.

### 1A: Browser Manager

- [x] Port `browser_manager.py` into `ssi/src/ssi/browser/zen_manager.py`
- [x] Adapt zendriver initialization to use SSI's settings (headless, proxy, timeout)
- [x] Port 4-tier click strategies (CSS → text → find → fuzzy)
- [x] Port 4-tier type strategies with readback verification
- [x] Port overlay dismissal (cookie banners, chat widgets, Google Translate)
- [x] Port screenshot optimization (CSS zoom, downscaling, MD5 dedup)
- [ ] Add unit tests for each strategy tier

### 1B: DOM Inspector

- [x] Port `dom_inspector.py` into `ssi/src/ssi/browser/dom_inspector.py`
- [x] Port three-tier confidence scoring (direct ≥75, assisted ≥40, fallback)
- [x] Port `FindRegisterDetector`, `NavigateDepositDetector`, `CheckEmailDetector`
- [x] Make confidence thresholds configurable via SSI settings
- [x] Add unit tests for each detector

### 1C: Agent Controller (State Machine)

- [x] Create `ssi/src/ssi/browser/agent_controller.py` based on AWH's `controller.py`
- [x] Define state enum (INIT → LOAD_SITE → ... → COMPLETE)
- [x] Implement state transitions with AWH's stuck detection logic
- [x] Wire DOM Inspector into pre-LLM scan flow
- [x] Implement blank page detection with progressive backoff
- [x] Implement repeated action and scroll loop detection

### 1D: Page Analyzer (LLM Integration)

- [x] Create `ssi/src/ssi/browser/page_analyzer.py`
- [x] Adapt AWH's PageAnalyzer to use SSI's pluggable LLM provider abstraction
- [x] Port conversation window management (rolling last N messages, image stripping)
- [x] Port batch fill optimization
- [ ] Implement four-tier decision cascade: Playbook → DOM Inspector → Gemini text → Gemini vision → human
- [x] Add Gemini as primary LLM provider (`ssi/src/ssi/llm/gemini_provider.py`) — text + vision
- [ ] Add Ollama vision support for local dev (Gemma 3 12B / Qwen3-VL 8B)
- [ ] Implement dual-model routing (cheap model for routine states, escalation for stuck)
- [x] Port cost tracking with mixed-model awareness

### 1E: Identity Vault Extension

- [x] Add `generate_crypto_username()` to SSI's Identity Vault
- [x] Add password variant support (default, digits-only, alphanumeric)
- [x] Drop MCP server indirection — call Faker directly

---

## Phase 2: Wallet Extraction Pipeline (1–2 weeks)

Extract AWH's wallet extraction capability into a standalone module.

- [x] Create `ssi/src/ssi/wallet/` module
- [x] Port JS wallet regex patterns (ETH, BTC, TRX, XRP, ADA, SOL, etc.)
- [x] Port coin tab/button discovery logic
- [x] Port LLM verification step (token symbol, network metadata)
- [x] Port 26-pair token-network allowlist + expand with additional tokens
- [x] Make allowlist fully configurable via JSON file (`config/wallet_allowlist.json`)
- [x] Port opportunistic wallet capture (during state transitions)
- [x] Create `WalletEntry` and `WalletHarvest` Pydantic models
- [x] Add XLSX export utility (for standalone use)
- [x] Wire wallet extraction into EXTRACT_WALLETS state
- [x] Add unit tests for regex patterns, allowlist validation
- [ ] Add integration tests against test fixture sites with wallet displays

---

## Phase 3: Data Schema & Storage Integration (2 weeks)

Extend core's database schema and wire SSI to store results in the unified data layer.

### 3A: Schema Design & Migration

- [x] Design `site_scans` table (scan metadata, passive/active results, cost)
- [x] Design `harvested_wallets` table (token, network, address, confidence)
- [x] Design `agent_sessions` table (per-action audit trail)
- [x] Design `pii_exposures` table (what PII the scam collects)
- [x] Write Alembic migration for new tables (in core)
- [x] Validate SQLite and PostgreSQL dialect compatibility

### 3B: Store Implementation

- [x] Create `ScanStore` class following core's `StructuredStore` pattern
- [x] Implement CRUD for `site_scans`, `harvested_wallets`, `agent_sessions`, `pii_exposures`
- [x] Add factory function `build_scan_store()` in SSI
- [x] Wire orchestrator to store results after each phase

### 3C: Case Integration

- [x] Wire investigation submission to create a `case` in core's `cases` table
- [x] Map SSI classification to core's `classification_result` JSONB field
- [x] Map risk score to core's `risk_score` column
- [x] Store wallet addresses as `indicators` (IOC type: crypto_wallet)
- [x] Store domains, IPs, registrants as `entities`
- [x] Store evidence files as `source_documents`
- [x] Add unit tests for all store operations

---

## Phase 4: Playbook Engine (1–2 weeks)

Implement the playbook execution engine for known scam site templates.

- [ ] Create `ssi/src/ssi/playbook/` module
- [ ] Port `Playbook` and `PlaybookStep` models from AWH
- [ ] Port `PlaybookMatcher` (URL regex matching)
- [ ] Implement `PlaybookExecutor` — sequential step execution
- [ ] Implement template variable resolution (`{identity.email}`, `{identity.password}`, etc.)
- [ ] Implement per-step retry logic
- [ ] Implement fallback-to-LLM on step failure
- [ ] Add playbook JSON file loading (from `config/playbooks/` directory)
- [ ] Wire PlaybookMatcher into orchestrator (check before LLM agent)
- [ ] Add playbook CRUD API endpoints
- [ ] Create 2–3 sample playbooks for known scam site templates
- [ ] Add unit tests for matcher, variable resolution, step execution

---

## Phase 5: UI — Live Monitoring & Guidance (2 weeks)

### 5A: SSI Backend WebSocket

- [ ] Create `ssi/src/ssi/monitoring/` module
- [ ] Port AWH's event bus (`EventBus` class)
- [ ] Implement WebSocket endpoints (`/ws/monitor/{id}`, `/ws/guidance/{id}`)
- [ ] Emit events: `state_change`, `screenshot`, `action`, `guidance_needed`, `wallet_found`, `complete`
- [ ] Implement guidance command handler (click, type, goto, skip, continue)

### 5B: Next.js UI Extensions

- [ ] Create `/ssi/investigations` page (investigation list/history)
- [ ] Create `/ssi/investigations/{id}` page (3-tab detail view)
- [ ] Implement "Recon" tab (passive results: WHOIS, DNS, SSL, GeoIP cards)
- [ ] Implement "Live Monitor" tab (WebSocket: live screenshot + action log + guidance UI)
- [ ] Implement "Results" tab (risk score, wallets table, PII exposure, evidence downloads)
- [ ] Create `/ssi/wallets` page (wallet search/browse across all investigations)
- [ ] Create Next.js API route proxies for new SSI endpoints
- [ ] Add WebSocket hook (`useInvestigationMonitor`) for real-time events
- [ ] Update SSI page to be authenticated (remove IAP `/ssi` exclusion)
- [ ] Add "Quick Scan" toggle on same page (passive-only mode)
- [ ] Update SSI page submission form to support scan type selection (passive/active/full)
- [ ] Run `pnpm format` and verify Prettier compliance

### 5C: Navigation & Layout

- [ ] Add SSI sub-navigation: Investigate / Investigations / Wallets
- [ ] Update sidebar navigation with new SSI sub-routes
- [ ] Ensure all new pages work in both light and dark mode

> **Note**: Playbook management UI deferred to post-Phase 8 (JSON files in repo first).

---

## Phase 6: GCP Deployment & Terraform (2 weeks)

### 6A: Docker Images

- [ ] Update `ssi-api.Dockerfile` (add WebSocket support / dependencies)
- [ ] Update `ssi-job.Dockerfile` (add zendriver + Chromium + wallet extraction deps)
- [ ] Verify both images build and run locally
- [ ] Push to Artifact Registry

### 6B: Terraform

- [ ] Add/update `ssi_cloud_run.tf` — SSI API Cloud Run service
- [ ] Add/update `ssi_cloud_run_job.tf` — SSI investigation job (with zendriver)
- [ ] Add/update `ssi_gcs.tf` — evidence GCS bucket
- [ ] Add/update `ssi_secrets.tf` — OSINT API keys, proxy credentials
- [ ] Add/update `ssi_iam.tf` — `sa-ssi` service account roles
- [ ] Plan and apply to `i4g-dev`
- [ ] Smoke test: submit investigation via API on dev

### 6C: Configuration

- [ ] Create `config/settings.dev.toml` with GCP-specific settings
- [ ] Verify env var overrides work (`SSI_*` double-underscore nesting)
- [ ] Add settings unit tests for new config sections (wallet, agent, playbook, monitoring)

---

## Phase 7: Evidence & Reporting Enhancements (1–2 weeks)

- [ ] Extend evidence ZIP to include `wallet_manifest.json`
- [ ] Extend STIX 2.1 bundle to include wallet addresses as indicators
- [ ] Extend Markdown report template with wallet extraction section
- [ ] Extend PDF report with wallet table
- [ ] Extend LEA evidence report with wallet and blockchain intelligence section
- [ ] Add PII exposure section to reports (what the scam site collects)
- [ ] Update `investigation.json` schema with wallet and active interaction data
- [ ] Add CSV/XLSX export endpoint for wallet data (`GET /report/{id}/wallets.xlsx`)
- [ ] Add unit tests for evidence packaging with wallet data

---

## Phase 8: Testing, Hardening & Documentation (2 weeks)

### 8A: Testing

- [ ] Create controlled test scam site fixtures (HTML files)
- [ ] Write E2E test: full investigation pipeline against test fixtures
- [ ] Write integration test: API → DB → evidence storage round-trip
- [ ] Write browser test: form fill → wallet extraction against test fixtures
- [ ] Verify all existing SSI tests still pass after merge
- [ ] Target ≥80% code coverage on new modules

### 8B: Hardening

- [ ] Implement per-investigation cost budget (abort if exceeded)
- [ ] Implement concurrent investigation limit (protect against resource exhaustion)
- [ ] Add retry logic for LLM API failures (exponential backoff)
- [ ] Add retry logic for OSINT API failures
- [ ] Verify all error states produce clean, actionable error messages
- [ ] Security review: ensure no PII leaks in logs, no API keys in error messages

### 8C: Documentation

- [ ] Update `ssi/docs/architecture.md` with merged architecture
- [ ] Update `ssi/docs/developer_guide.md` with new setup instructions (zendriver, etc.)
- [ ] Update `ssi/docs/user_guide.md` with new features (wallet extraction, monitoring, playbooks)
- [ ] Update `planning/prd_scam_site_investigator.md` to reflect consolidated scope
- [ ] Update `planning/ssi/ssi_next_steps.md` to mark completed items
- [ ] Add `ssi/docs/playbook_authoring.md` — guide for creating new playbooks
- [ ] Update `docs/book/` (mdBook) with SSI wallet harvester content
- [ ] Update API reference docs with new endpoints

---

## Post-Merge Future Work (Not in This Roadmap)

These items are tracked for future phases:

- [ ] Redis-backed task queue (replace in-memory tracking)
- [ ] Blockchain analysis integration (Chainalysis / Crystal / open-source)
- [ ] Campaign linking (identify related scam sites)
- [ ] CAPTCHA solver integration (2Captcha / CapSolver)
- [ ] Multi-language scam site support (non-English)
- [ ] Malware sandbox integration (Joe Sandbox / ANY.RUN)
- [ ] TAXII threat intel feeds
- [ ] Mobile deep link investigation
- [ ] browser-use library evaluation for agent replacement
- [ ] Multi-threaded/concurrent site processing
- [ ] `prod` environment deployment
- [ ] eCX API integration (`/phish`, `/mal_domain`, `/crypto` feeds as upstream data sources)
- [ ] Playbook management UI (CRUD interface for analysts)
- [ ] Public access mode for quick scans (revisit IAP exclusion)
