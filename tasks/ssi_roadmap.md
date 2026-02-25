# SSI Roadmap: Phased Implementation Plan

> **Created**: February 22, 2026
> **Updated**: February 23, 2026
> **Status**: Planning
> **Prerequisite**: SSI–AWH merge cycle complete (see `planning/archive/ssi_awh_merge_summary.md`)

---

## Current State

SSI is a three-phase scam site investigation system (passive recon → active agent interaction → intelligence synthesis) deployed to `i4g-dev` on GCP Cloud Run. The AWH merge added wallet extraction, a playbook engine, a state machine-based browser agent (zendriver), real-time WebSocket monitoring, and a Next.js analyst UI. The test suite has 599 tests (575 unit + 24 integration). All infrastructure (Terraform, Docker images, secrets, IAM) is provisioned in `i4g-dev`.

**What works today:**

- CLI: `ssi investigate url`, `ssi investigate batch`, `ssi playbook`, `ssi investigate list/show`
- API: Full REST + WebSocket endpoints on port 8100
- Browser: zendriver (active) + Playwright (passive) dual-engine
- LLM: Ollama (local), Gemini Flash (GCP), mock (tests)
- Storage: ScanStore (SQLite / PostgreSQL), evidence filesystem / GCS
- UI: Next.js pages for investigations, wallets, live monitoring, guidance

---

## Phase 0: Carry-Forward Items (week 1)

> Incomplete tasks from the SSI–AWH merge cycle. Clear these before new work.

- [x] **C1** — Unit tests for each browser strategy tier _(from Phase 1A)_
- [x] **C2** — Four-tier decision cascade: Playbook → DOM → text → vision → human _(from Phase 1D)_
- [x] **C3** — Ollama vision support for local dev (Gemma 3 12B / Qwen3-VL 8B) _(from Phase 1D)_
- [x] **C4** — Dual-model routing: cheap model for routine, escalation for stuck _(from Phase 1D)_
- [x] **C5** — Integration tests against fixture sites with wallet displays _(from Phase 2)_
- [x] **C6** — Batch scheduling docs (cron pattern) _(from Phase 5E)_
- [x] **C7** — `ssi job batch` Cloud Run Job variant (reads manifest from GCS) _(from Phase 5E)_
- [x] **C8** — ≥80% code coverage on new modules _(from Phase 8A)_

**Exit criteria**: All carry-forward items resolved or explicitly deferred with rationale.

---

## Phase 1: Local Testing & Validation (weeks 1–2)

**Goal**: Validate the merged product against real scam sites before scaling up.

### 1A — Scam-type coverage

- [x] **1.1** — Test against 20+ scam URLs covering phishing, fake shops, tech support, crypto, and romance scam types
- [x] **1.2** — Validate evidence packages — confirm reports are readable, STIX bundles import into threat intel tools, ZIP manifests are correct
- [x] **1.3** — Measure agent reliability — track success rate of end-to-end funnel traversal across scam types

### 1B — Edge cases & failure analysis

- [x] **1.4** — Test CAPTCHA handling — verify detection and graceful degradation (reCAPTCHA, hCaptcha, Turnstile)
- [x] **1.5** — Document failure modes — identify sites where the agent fails (anti-bot, complex JS, CAPTCHAs)
- [x] **1.6** — Refine prompts — tune LLM prompts based on failure analysis

### 1C — Performance & batch validation

- [x] **1.7** — Benchmark performance — measure investigation time and token usage per scam type
- [x] **1.8** — Test batch mode — run `ssi investigate batch` against a curated URL list

**Exit criteria**: ≥70% of submitted URLs successfully traversed; evidence quality is LEA-acceptable.

---

## Phase 2: Production Readiness (weeks 3–5)

**Goal**: Close the gaps needed for production-grade evidence delivery.

### 2A — Evidence delivery

- [x] **2.1** — Evidence bundle download endpoint — `GET /investigations/{id}/evidence-bundle` (ZIP with PDF + all artifacts) and `GET /investigations/{id}/lea-package` (signed ZIP with PDF, LEO report, evidence, chain-of-custody, STIX); requires GCS upload + signed URL generation
- [x] **2.2** — GCS evidence links in reports — upload evidence artifacts to GCS in dev/prod; render clickable signed URLs in PDF instead of filenames

### 2B — Core integration backbone

- [x] **2.3** — Core case creation (end-to-end) — add `POST /cases` to core API, wire `CoreBridge.push_investigation()`, make every investigation create a case, back-reference core case ID in SSI scan records

### 2C — Infrastructure upgrades

- [x] **2.4** — Redis-backed task queue — replace in-memory task tracking with Redis (shared with core)
- [ ] **2.5** — `prod` environment deployment — Terraform apply to `i4g-prod`, smoke test, monitoring alerts

**Exit criteria**: Evidence bundles downloadable from API; case creation flows end-to-end; prod environment live.

---

## Phase 3: Platform Integration (weeks 6–8)

**Goal**: Wire SSI into the i4g platform for end-to-end analyst workflows.

### 3A — API & triggering

- [ ] **3.1** — Core API trigger — add `POST /investigations/ssi` to core API that triggers an SSI Cloud Run Job
- [ ] **3.2** — Task tracking — SSI job reports progress to core's TASK_STATUS system
- [ ] **3.3** — Auth alignment — SSI→core OIDC auth works end-to-end (not just API key fallback)

> **Investigation notes (2026-02-24):**
>
> SSI's `CoreBridge._build_auth_headers()` sends `Authorization: Bearer <oidc_token>` +
> `X-API-KEY` to `fastapi-gateway` via `https://api.intelligenceforgood.org` (IAP-protected LB).
>
> **Env var audiences match** — both `I4G_IDENTITY__AUDIENCE` and `SSI_INTEGRATION__IAP_AUDIENCE`
> resolve to the same IAP OAuth client ID (`544936845045-…iqh0h.apps.googleusercontent.com`) via
> `var.iap_clients["api"].client_id` in Terraform.
>
> **Step 2 failure (IAP assertion):** The IAP-signed JWT (`X-Goog-IAP-JWT-Assertion`) injected
> by the LB has `aud = /projects/PROJECT_NUMBER/global/backendServices/BACKEND_SERVICE_ID`.
> Core's `_verify_iap_jwt(is_iap_assertion=True)` compares against `settings.identity.audience`
> (= OAuth client ID) → audience format mismatch → "IAP JWT present but verification failed".
> This affects **all** callers through the LB (UI included), not just SSI.
>
> **Step 3 (Bearer):** The OIDC token from `id_token.fetch_id_token()` has `aud` = OAuth client ID,
> which matches `settings.identity.audience`. Verification uses default OIDC certs (not IAP certs).
> This *should* succeed — need DEBUG-level logging to confirm whether it does, or whether a
> secondary issue also blocks step 3 for SSI (and/or UI) requests.
>
> **Step 4 (API key):** Works, so all requests authenticate — but the failing OIDC path means
> caller identity is lost (authenticated as `"service"` instead of the SA email).
>
> **Fix path:**
> 1. **Step 2** — add `settings.identity.iap_backend_audience` with the backend-service audience
>    string (get value from `gcloud compute backend-services list --format='value(name,id)'`
>    or from the Terraform `global_lb` output `backend_services`). Use it in
>    `_verify_iap_jwt(is_iap_assertion=True)` instead of the OAuth client ID.
> 2. **Step 3** — add `logger.warning(...)` on failure (currently only DEBUG) to confirm whether
>    this path succeeds or also fails for SSI / UI requests.
> 3. **No SSI changes needed** — the OIDC audience is already correct.
>
> **Key files:**
> - Working reference: `ui/apps/web/src/lib/server/auth-helpers.ts` + `api-client.ts`
> - Broken path: `ssi/src/ssi/integration/core_bridge.py` (`_build_auth_headers`, `_get_oidc_token`)
> - Auth gate: `core/src/i4g/api/auth.py` (`_verify_iap_jwt`, `require_token`)
> - Infra: `infra/environments/app/dev/main.tf` (IAP client IDs, LB backend config)
> - IAP IAM: `sa-ssi` already in `fastapi_iap_access_members` (`roles/iap.httpsResourceAccessor`)

### 3B — Analyst console

- [ ] **3.4** — Analyst console UI — "Investigate URL" action in Next.js console: form submits URL, shows progress, displays results
- [ ] **3.5** — Evidence attachment — SSI evidence ZIP attaches to case records via existing evidence system

### 3C — Data model alignment

- [ ] **3.6** — Taxonomy mapping — SSI classification output maps to core's five-axis fraud taxonomy
- [ ] **3.7** — Shared types — extract common models or use SSI as a direct dependency

### 3D — Extended workflows

- [ ] **3.8** — Victim intake flow — victim-submitted scam URL optionally triggers SSI investigation
- [ ] **3.9** — Dossier enrichment — SSI infrastructure intelligence feeds into dossier generation

**Exit criteria**: Analyst can trigger investigation from console; results appear in case view; evidence is attached.

---

## Phase 4: Hardening & Scale (weeks 9–12+)

**Goal**: Production-grade reliability, security, and cost management.

### 4A — Anti-detection & resilience

- [ ] **4.1** — CAPTCHA solver integration — 2Captcha / CapSolver for automated CAPTCHA solving
- [ ] **4.2** — Proxy infrastructure — residential proxy rotation for anti-detection

### 4B — Operational controls

- [ ] **4.3** — Per-tenant rate limiting — per-tenant investigation limits and cost budgets
- [ ] **4.4** — Retention policy — automated evidence retention/cleanup per `SSI_EVIDENCE__RETAIN_DAYS`
- [ ] **4.5** — Multi-region deployment — geographic diversity for investigations

### 4C — Legal & pilot

- [ ] **4.6** — Legal review — legal opinion on automated interaction under CFAA / CMA
- [ ] **4.7** — LEA pilot — partner with 1–3 law enforcement agencies for real-world testing

**Exit criteria**: CAPTCHA solving operational; proxy rotation active; at least one LEA pilot underway.

---

## Phase 5: Advanced Capabilities (future)

**Goal**: Extend SSI with intelligence enrichment, external feeds, and analyst tooling.

### 5A — Intelligence enrichment

- [ ] **5.1** — Blockchain analysis — Chainalysis / Crystal / open-source integration for wallet tracing
- [ ] **5.2** — Campaign linking — identify related scam sites via shared infrastructure (IP, hosting, registrar, SSL)
- [ ] **5.3** — eCX API integration — `/phish`, `/mal_domain`, `/crypto` feeds as upstream data sources

### 5B — Coverage expansion

- [ ] **5.4** — Multi-language support — test and tune LLM prompts for non-English scam sites
- [ ] **5.5** — Malware sandbox — Joe Sandbox / ANY.RUN API for downloaded file analysis
- [ ] **5.6** — Mobile deep link investigation — investigate scam links targeting mobile apps

### 5C — Distribution & sharing

- [ ] **5.7** — TAXII threat intel feeds — publish STIX bundles to TAXII feeds for community sharing
- [ ] **5.8** — Public access mode — quick scans without auth (revisit IAP exclusion)
- [ ] **5.9** — API marketplace — offer SSI as a service for other anti-fraud organizations

### 5D — Tooling & agent evolution

- [ ] **5.10** — browser-use evaluation — evaluate browser-use library as agent replacement
- [ ] **5.11** — Playbook management UI — CRUD interface for analysts to manage playbooks
- [ ] **5.12** — Real-time monitoring — continuous monitoring of known scam infrastructure

---

## Decision Points

| Decision              | When    | Options                                                |
| --------------------- | ------- | ------------------------------------------------------ |
| CAPTCHA strategy      | Phase 4 | External solver service vs. graceful skip (current)    |
| Dedicated GCP project | Phase 4 | Stay in `i4g-dev` (recommended) vs. split to `ssi-dev` |
| Malware analysis      | Phase 5 | Joe Sandbox API vs. ANY.RUN vs. in-house               |
| browser-use adoption  | Phase 5 | Replace custom agent vs. keep custom + cherry-pick     |

---

## Resource Estimates

| Phase                           | Duration    | Effort                    |
| ------------------------------- | ----------- | ------------------------- |
| Phase 0 — Carry-forward         | Week 1      | 1 engineer                |
| Phase 1 — Local testing         | Weeks 1–2   | 1 engineer                |
| Phase 2 — Production readiness  | Weeks 3–5   | 1 engineer                |
| Phase 3 — Platform integration  | Weeks 6–8   | 1–2 engineers (core + UI) |
| Phase 4 — Hardening & scale     | Weeks 9–12+ | Part-time                 |
| Phase 5 — Advanced capabilities | Future      | TBD                       |
