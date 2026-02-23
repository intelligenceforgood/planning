# SSI Roadmap: Next Development Cycle

> **Created**: February 22, 2026
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

## Carry-Forward Items (Previous Cycle)

These tasks were incomplete at the end of the merge cycle:

| #   | Task                                                                     | Source   |
| --- | ------------------------------------------------------------------------ | -------- |
| C1  | Unit tests for each browser strategy tier                                | Phase 1A |
| C2  | Four-tier decision cascade (full Playbook → DOM → text → vision → human) | Phase 1D |
| C3  | Ollama vision support for local dev (Gemma 3 12B / Qwen3-VL 8B)          | Phase 1D |
| C4  | Dual-model routing (cheap model for routine, escalation for stuck)       | Phase 1D |
| C5  | Integration tests against fixture sites with wallet displays             | Phase 2  |
| C6  | Batch scheduling docs (cron pattern)                                     | Phase 5E |
| C7  | `ssi job batch` Cloud Run Job variant (reads manifest from GCS)          | Phase 5E |
| C8  | ≥80% code coverage on new modules                                        | Phase 8A |

---

## Phase 1: Local Testing & Validation (1–2 weeks)

**Goal**: Validate the merged product against real scam sites before scaling up.

| #   | Task                         | Description                                                                                          |
| --- | ---------------------------- | ---------------------------------------------------------------------------------------------------- |
| 1.1 | Test against 20+ scam URLs   | Cover phishing, fake shops, tech support, crypto, romance scam types                                 |
| 1.2 | Validate evidence packages   | Confirm reports are readable, STIX bundles import into threat intel tools, ZIP manifests are correct |
| 1.3 | Measure agent reliability    | Track success rate of end-to-end funnel traversal across scam types                                  |
| 1.4 | Test CAPTCHA handling        | Verify detection and graceful degradation (reCAPTCHA, hCaptcha, Turnstile)                           |
| 1.5 | Benchmark performance        | Measure investigation time and token usage per scam type                                             |
| 1.6 | Test batch mode              | Run `ssi investigate batch` against a curated URL list                                               |
| 1.7 | Document failure modes       | Identify sites where the agent fails (anti-bot, complex JS, CAPTCHAs)                                |
| 1.8 | Refine prompts               | Tune LLM prompts based on failure analysis                                                           |
| 1.9 | Complete carry-forward C1–C8 | Address all items from the carry-forward table above                                                 |

**Exit criteria**: ≥70% of submitted URLs successfully traversed; evidence quality is LEA-acceptable.

---

## Phase 2: Production Readiness (2–3 weeks)

**Goal**: Close the gaps needed for production-grade evidence delivery.

| #   | Task                            | Description                                                                                                                                                                                                                                                                  |
| --- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1 | Evidence Bundle Download        | `GET /investigations/{id}/evidence-bundle` — ZIP with PDF + all artifacts the PDF references but cannot inline. `GET /investigations/{id}/lea-package` — signed ZIP with PDF, LEO report, all evidence, chain-of-custody, STIX. Requires GCS upload + signed URL generation. |
| 2.2 | GCS Evidence Links in Reports   | Upload evidence artifacts to GCS in dev/prod; render clickable signed URLs in PDF instead of filenames                                                                                                                                                                       |
| 2.3 | Core Case Creation (end-to-end) | Add `POST /cases` to core API, wire `CoreBridge.push_investigation()`, make every investigation create a case, back-reference core case ID in SSI scan records                                                                                                               |
| 2.4 | Redis-backed task queue         | Replace in-memory task tracking with Redis (shared with core)                                                                                                                                                                                                                |
| 2.5 | `prod` environment deployment   | Terraform apply to `i4g-prod`, smoke test, monitoring alerts                                                                                                                                                                                                                 |

---

## Phase 3: Platform Integration (2–3 weeks)

**Goal**: Wire SSI into the i4g platform for end-to-end analyst workflows.

| #   | Task                | Description                                                                                      |
| --- | ------------------- | ------------------------------------------------------------------------------------------------ |
| 3.1 | Core API trigger    | Add `POST /investigations/ssi` to core API that triggers an SSI Cloud Run Job                    |
| 3.2 | Task tracking       | SSI job reports progress to core's TASK_STATUS system                                            |
| 3.3 | Analyst console UI  | "Investigate URL" action in Next.js console — form submits URL, shows progress, displays results |
| 3.4 | Taxonomy mapping    | SSI classification output maps to core's five-axis fraud taxonomy                                |
| 3.5 | Evidence attachment | SSI evidence ZIP attaches to case records via existing evidence system                           |
| 3.6 | Victim intake flow  | Victim-submitted scam URL optionally triggers SSI investigation                                  |
| 3.7 | Dossier enrichment  | SSI infrastructure intelligence feeds into dossier generation                                    |
| 3.8 | Shared types        | Extract common models or use SSI as a direct dependency                                          |
| 3.9 | Auth alignment      | SSI API authenticates via IAP or API key (same as core)                                          |

**Exit criteria**: Analyst can trigger investigation from console; results appear in case view; evidence is attached.

---

## Phase 4: Hardening & Scale (ongoing)

**Goal**: Production-grade reliability, security, and cost management.

| #   | Task                       | Description                                                          |
| --- | -------------------------- | -------------------------------------------------------------------- |
| 4.1 | CAPTCHA solver integration | 2Captcha / CapSolver for automated CAPTCHA solving                   |
| 4.2 | Proxy infrastructure       | Residential proxy rotation for anti-detection                        |
| 4.3 | Per-tenant rate limiting   | Per-tenant investigation limits and cost budgets                     |
| 4.4 | Retention policy           | Automated evidence retention/cleanup per `SSI_EVIDENCE__RETAIN_DAYS` |
| 4.5 | Multi-region deployment    | Geographic diversity for investigations                              |
| 4.6 | Legal review               | Legal opinion on automated interaction under CFAA / CMA              |
| 4.7 | LEA pilot                  | Partner with 1–3 law enforcement agencies for real-world testing     |

---

## Phase 5: Advanced Capabilities (future)

| #    | Task                           | Description                                                                         |
| ---- | ------------------------------ | ----------------------------------------------------------------------------------- |
| 5.1  | Blockchain analysis            | Chainalysis / Crystal / open-source integration for wallet tracing                  |
| 5.2  | Campaign linking               | Identify related scam sites via shared infrastructure (IP, hosting, registrar, SSL) |
| 5.3  | eCX API integration            | `/phish`, `/mal_domain`, `/crypto` feeds as upstream data sources                   |
| 5.4  | Multi-language support         | Test and tune LLM prompts for non-English scam sites                                |
| 5.5  | Malware sandbox                | Joe Sandbox / ANY.RUN API for downloaded file analysis                              |
| 5.6  | TAXII threat intel feeds       | Publish STIX bundles to TAXII feeds for community sharing                           |
| 5.7  | Mobile deep link investigation | Investigate scam links targeting mobile apps                                        |
| 5.8  | browser-use evaluation         | Evaluate browser-use library as agent replacement                                   |
| 5.9  | Playbook management UI         | CRUD interface for analysts to manage playbooks                                     |
| 5.10 | Public access mode             | Quick scans without auth (revisit IAP exclusion)                                    |
| 5.11 | Real-time monitoring           | Continuous monitoring of known scam infrastructure                                  |
| 5.12 | API marketplace                | Offer SSI as a service for other anti-fraud organizations                           |

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

| Phase                          | Duration  | Effort                    |
| ------------------------------ | --------- | ------------------------- |
| Phase 1 — Local testing        | 1–2 weeks | 1 engineer                |
| Phase 2 — Production readiness | 2–3 weeks | 1 engineer                |
| Phase 3 — Platform integration | 2–3 weeks | 1–2 engineers (core + UI) |
| Phase 4 — Hardening            | Ongoing   | Part-time                 |
| Phase 5 — Advanced             | Future    | TBD                       |
