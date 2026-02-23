# SSI–AWH Merge: Summary & Archive

> **Created**: February 22, 2026
> **Status**: Archive — merge cycle complete
> **Context**: Documents the consolidation of the Agentic Wallet Harvester (AWH) into the Scam Site Investigator (SSI), completed February 2026.

---

## Why the Merge Happened

SSI (Scam Site Investigator) and AWH (Agentic Wallet Harvester) were independent tools with complementary capabilities. SSI performed deep OSINT reconnaissance, fraud classification, and evidence packaging but lacked wallet extraction. AWH extracted crypto wallet addresses from scam sites using vision-based browser automation but lacked OSINT, classification, evidence packaging, and database storage. Merging them created a unified product that investigates scam sites end-to-end: passive recon → active agent interaction → wallet extraction → intelligence synthesis.

---

## What AWH Was

AWH was a **vision-based agentic browser automation system** that navigated crypto scam sites, registered throwaway accounts, found deposit pages, and extracted cryptocurrency wallet addresses.

**Core capabilities:**

- **Browser engine**: zendriver (CDP-based, inherently undetected Chrome)
- **LLM**: Anthropic Claude (Sonnet + Haiku) with a dual-model cost strategy — Haiku for routine states, Sonnet for complex ones
- **State machine**: 8-state finite state machine (INIT → LOAD_SITE → FIND_REGISTER → FILL_REGISTER → SUBMIT_REGISTER → CHECK_EMAIL → NAVIGATE_DEPOSIT → EXTRACT_WALLETS → COMPLETE)
- **Browser strategies**: 4-tier click and type strategies with fuzzy matching fallback, overlay dismissal (cookie banners, chat widgets), screenshot optimization (CSS zoom, downscaling, MD5 dedup)
- **DOM Inspector**: Pre-LLM DOM scanning with three-tier confidence scoring (≥75 direct, ≥40 assisted, <40 LLM fallback) — skipped LLM calls 40–60% of the time
- **Wallet extraction**: JS regex patterns for 6+ blockchain formats + coin tab discovery + LLM verification against a 26-pair token-network allowlist
- **Human-in-the-loop**: WebSocket dashboard + console guidance when the agent got stuck
- **Identity**: Faker MCP server for throwaway registration data
- **Infrastructure**: Azure VM + Blob Storage + Docker + SmartProxy/Decodo residential proxies
- **Output**: Per-site JSON + XLSX spreadsheet

**Key source files**: `controller.py` (1,841 lines), `browser_manager.py` (1,672 lines), `page_analyzer.py` (~400 lines), `dom_inspector.py` (~350 lines).

**Limitations**: Azure-only, no OSINT, no fraud classification, no evidence packaging, no database, no API, single-threaded, Claude-only (expensive), no CAPTCHA handling, playbook system unimplemented.

---

## Feature Comparison (Key Differentiators)

| Capability            | SSI                                                 | AWH                          | Merged                                                 |
| --------------------- | --------------------------------------------------- | ---------------------------- | ------------------------------------------------------ |
| Browser Automation    | Playwright (detectable)                             | zendriver (undetected)       | Dual-engine: zendriver (active) + Playwright (passive) |
| LLM Provider          | Pluggable: Ollama, Gemini                           | Claude only                  | Pluggable: Ollama (local), Gemini Flash (GCP)          |
| Passive Recon (OSINT) | Full pipeline (WHOIS, DNS, SSL, GeoIP, VT, urlscan) | None                         | SSI's full pipeline                                    |
| Wallet Extraction     | None                                                | Core capability              | AWH's pipeline, ported to SSI                          |
| Fraud Classification  | Five-axis taxonomy + risk score                     | None                         | SSI's classifier                                       |
| Evidence Packaging    | ZIP + SHA-256 + STIX + LEA report + PDF             | Per-site JSON + XLSX         | SSI's pipeline, extended with wallet data              |
| Human-in-the-Loop     | None                                                | WebSocket + console guidance | AWH's guidance, integrated into Next.js UI             |
| Data Storage          | Local filesystem / GCS                              | Azure Blob + local JSON      | SQLite / PostgreSQL + GCS                              |
| Deployment            | Docker → GCP Cloud Run                              | Docker → Azure VM            | GCP Cloud Run (aligned with i4g platform)              |

---

## Key Merge Decisions

1. **Browser engine**: Dual-engine — zendriver for active interaction (stealth), Playwright for passive capture (features)
2. **LLM strategy**: Gemini 2.0 Flash (primary, ~35x cheaper than Claude), Gemini 2.5 Pro (escalation), Ollama (local dev). Claude dropped from critical path.
3. **State machine vs loop**: AWH's state machine with SSI phases as meta-states (Passive Recon → Active Interaction → Intelligence Synthesis)
4. **Data storage**: Extend core's schema (SQLite/PostgreSQL) — each scam site = one case
5. **Infrastructure**: GCP-only (drop Azure). Terraform in `infra/`.
6. **Identity**: SSI's richer vault (SSN, Stripe test cards, UUID tracking). Drop MCP server indirection.
7. **Playbooks**: Implement execution engine (AWH had data model only)
8. **Cost optimization cascade**: Playbook ($0) → DOM Inspector ($0) → Gemini text (~$0.0001) → Gemini vision (~$0.0002) → human ($0). Target: <$0.01/investigation.

---

## What Was Built (Phases 0–8)

| Phase | Title                 | Outcome                                                                                                                                                        |
| ----- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **0** | Alignment & Planning  | 10 decisions resolved: dual-engine, Gemini Flash, Decodo proxy, ssi/ repo confirmed                                                                            |
| **1** | Browser Engine Port   | zendriver manager, DOM inspector (3-tier confidence), agent controller (state machine), page analyzer (pluggable LLM), identity vault extensions               |
| **2** | Wallet Extraction     | Standalone `ssi/wallet/` module: JS regex for 6+ blockchains, coin tab discovery, LLM verification, configurable allowlist, opportunistic capture, XLSX export |
| **3** | Data Schema & Storage | 4 new tables (site_scans, harvested_wallets, agent_sessions, pii_exposures), Alembic migration, ScanStore CRUD, case integration with core                     |
| **4** | Playbook Engine       | Playbook models, URL matcher, sequential executor with template variables, per-step retry, LLM fallback, CRUD API, 2–3 sample playbooks                        |
| **5** | CLI, Monitoring & UI  | Full CLI parity (batch, resume, events), EventBus + WebSocket, Next.js pages (investigations, wallets, 3-tab detail view, live monitor, guidance UI)           |
| **6** | GCP Deployment        | Docker images (ssi-api, ssi-job), Terraform (Cloud Run, GCS, Secrets, IAM), deployed to i4g-dev                                                                |
| **7** | Evidence & Reporting  | Wallet manifest in evidence ZIP, STIX wallet indicators, PDF/Markdown/LEA reports with wallet sections, embedded evidence appendices, XLSX export endpoint     |
| **8** | Testing & Hardening   | 599 tests (575 unit + 24 integration), cost budget enforcement, concurrent limits, retry logic (LLM + OSINT), error sanitisation, full docs update             |

**Test suite**: 599 tests passing. Test fixtures include controlled scam sites for reproducible browser testing.

---

## What Was Dropped from AWH

| Component                                    | Reason                                           |
| -------------------------------------------- | ------------------------------------------------ |
| Azure Blob Storage / Azurite                 | Replaced by GCS / local filesystem               |
| Azure Portal deployment guide                | Replaced by Terraform                            |
| MCP server architecture (Faker, XLSX writer) | Over-engineered; direct function calls           |
| XLSX as primary output                       | Replaced by database + CSV/XLSX export API       |
| `send_guidance.py`                           | Replaced by WebSocket guidance in Next.js UI     |
| Separate `agentic_wallet_harvester` repo     | Consolidated into `ssi/`                         |
| Anthropic Claude dependency                  | Replaced by pluggable LLM (Gemini Flash primary) |

---

## Remaining Items (Carried to Next Cycle)

The following items were incomplete at the end of the merge cycle and are tracked in `planning/tasks/ssi_roadmap.md`:

- Unit tests for browser strategy tiers
- Four-tier decision cascade (full implementation)
- Ollama vision support (Gemma 3 / Qwen3-VL)
- Dual-model routing
- Integration tests against fixture sites with wallets
- Batch scheduling docs + Cloud Run Job variant
- ≥80% code coverage
- 14 post-merge future work items (evidence bundles, GCS links, core case creation, Redis queue, blockchain analysis, campaign linking, CAPTCHA solver, etc.)

---

## Archived Documents

The following documents from the merge cycle are preserved in `planning/archive/` for reference:

| Document                              | Description                                                                     |
| ------------------------------------- | ------------------------------------------------------------------------------- |
| `ssi_awh_questions.md`                | 17 resolved design questions from the merge cycle                               |
| `ssi_browser_interaction_research.md` | Comprehensive browser automation survey (browser-use, LaVague, Stagehand, etc.) |
| `ssi_gemini_vs_claude_research.md`    | Gemini vs Claude vision comparison, pricing, Ollama multimodal options          |
