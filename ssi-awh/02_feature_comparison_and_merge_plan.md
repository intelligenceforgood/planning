# SSI ↔ AWH Feature Comparison & Merge Plan

> Side-by-side comparison of SSI (Scam Site Investigator) and AWH (Agentic Wallet Harvester),
> followed by a proposed integration path.

## 1. Feature Comparison Matrix

| Capability                 | SSI                                                                                                | AWH                                                                                     | Merged Product                                                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Browser Automation**     | Playwright (standard, detectable)                                                                  | zendriver (CDP, undetected)                                                             | zendriver preferred for stealth; Playwright fallback for passive capture                                                  |
| **LLM Provider**           | Pluggable: Ollama (local), Gemini (GCP)                                                            | Anthropic Claude only (Sonnet + Haiku)                                                  | Pluggable: Ollama (local), Gemini (GCP). **Claude dropped** — Gemini Flash matches for this use case                      |
| **LLM Usage**              | Text-based DOM → numbered elements → action decision                                               | Vision-based: screenshot → action decision                                              | **Four-tier cascade**: Playbook → DOM Inspector → Gemini text → Gemini vision → human. See `06_flexible_scan_research.md` |
| **Identity Generation**    | Vault with SSN (900–999), Stripe test cards, `@i4g-probe.net` email, UUID tracking                 | Faker MCP server: name, email, password, phone. No SSN, no cards                        | SSI vault (richer), drop MCP indirection                                                                                  |
| **Passive Recon (OSINT)**  | Full: WHOIS, DNS, SSL, GeoIP, VirusTotal, urlscan.io, HTTP headers, tech fingerprint               | None                                                                                    | SSI's full OSINT pipeline                                                                                                 |
| **Active Interaction**     | Observe→decide→act loop (20 steps, 50K token budget)                                               | State machine (8 states, 80 actions max). Batch fill, 4-tier click/type, fuzzy fallback | AWH's state machine + strategies. SSI's loop is simpler; AWH is more battle-tested                                        |
| **Wallet Extraction**      | Not implemented                                                                                    | Core capability: JS regex + LLM verification, coin tab discovery, 26-pair allowlist     | AWH's full pipeline                                                                                                       |
| **Fraud Classification**   | Five-axis taxonomy + confidence + risk score via LLM                                               | None                                                                                    | SSI's classification pipeline                                                                                             |
| **Evidence Packaging**     | ZIP + SHA-256 manifest, STIX 2.1, LEA report, investigation JSON                                   | Per-site JSON + XLSX                                                                    | SSI's evidence pipeline + AWH's wallet XLSX                                                                               |
| **Report Generation**      | Markdown + PDF (Jinja2 + WeasyPrint)                                                               | None                                                                                    | SSI's report pipeline, extended with wallet data                                                                          |
| **CAPTCHA Handling**       | Detection (reCAPTCHA, hCaptcha, Turnstile); configurable strategy (skip/wait/accessibility/solver) | None                                                                                    | SSI's detection framework                                                                                                 |
| **Anti-Detection**         | Stealth scripts, user-agent rotation, proxy rotation, randomized fingerprints                      | zendriver inherent stealth, overlay dismissal, residential proxy                        | Combine: zendriver + SSI's fingerprint rotation + proxy infrastructure                                                    |
| **Proxy**                  | Configurable via settings                                                                          | SmartProxy/Decodo residential proxies                                                   | Unified proxy config in settings                                                                                          |
| **Download Interception**  | Captures + hashes downloaded files                                                                 | None                                                                                    | SSI's download pipeline                                                                                                   |
| **HAR Recording**          | Full HAR capture + IOC extraction                                                                  | None                                                                                    | SSI's HAR pipeline                                                                                                        |
| **PII Collection Mapping** | Tracks what PII the scam site collects, at which step                                              | None                                                                                    | SSI's PII mapping                                                                                                         |
| **Human-in-the-Loop**      | None (fully autonomous)                                                                            | Web UI + console guidance when stuck                                                    | AWH's stuck handling + guidance UI                                                                                        |
| **Web Monitoring UI**      | None (relies on Next.js polling)                                                                   | Real-time WebSocket dashboard with live screenshots                                     | AWH's dashboard, integrated into Next.js UI                                                                               |
| **Data Storage**           | Local filesystem (`data/evidence/`) or GCS                                                         | Azure Blob + local JSON/XLSX                                                            | Core's polyglot persistence (SQLite/PostgreSQL + GCS)                                                                     |
| **API**                    | FastAPI on port 8100 (`/investigate`, `/report`)                                                   | None (CLI only, monitoring dashboard)                                                   | Unified FastAPI API                                                                                                       |
| **Cost Tracking**          | In-memory, basic                                                                                   | Per-call mixed-model tracking with cache awareness                                      | AWH's detailed tracking, persisted to DB                                                                                  |
| **Metrics**                | Basic                                                                                              | Detailed: strategy distribution, wasted actions, DOM inspection outcomes                | AWH's metrics framework                                                                                                   |
| **Playbook/Templates**     | None                                                                                               | Data model only (not implemented)                                                       | Implement playbook execution engine                                                                                       |
| **Configuration**          | Layered TOML + env vars (`SSI_*`), Pydantic settings                                               | Flat `.env` + python-dotenv                                                             | SSI's layered config pattern (TOML + env vars)                                                                            |
| **Deployment**             | Docker → Cloud Run (GCP), Terraform                                                                | Docker → Azure VM                                                                       | GCP Cloud Run (align with core/SSI)                                                                                       |
| **Testing**                | pytest unit tests                                                                                  | None visible                                                                            | Comprehensive test suite                                                                                                  |

---

## 2. Key Integration Decisions

### 2.1 Browser Engine: zendriver vs Playwright

**Recommendation: zendriver as primary, Playwright for passive capture**

| Factor         | zendriver                          | Playwright                                                        |
| -------------- | ---------------------------------- | ----------------------------------------------------------------- |
| Stealth        | Inherently undetected (CDP)        | Detectable without extra stealth patches                          |
| Community      | Small                              | Very large (Microsoft-backed)                                     |
| Feature set    | Basic CDP operations               | Rich API: HAR, network interception, downloads, multiple contexts |
| AWH dependency | Core dependency, deeply integrated | Not used                                                          |
| SSI dependency | Not used                           | Core dependency for passive capture + HAR                         |

The merged product needs both:

- **zendriver** for active interaction (registration, deposit navigation, wallet extraction) where stealth matters
- **Playwright** for passive capture (HAR recording, screenshots, DOM snapshots, download interception) where feature richness matters

### 2.2 LLM Strategy

**Recommendation: Keep SSI's pluggable provider abstraction. Claude is dropped from the critical path — Gemini 2.0 Flash handles both text and vision.**

- **Local dev**: Ollama — Llama 3.3 (text), Gemma 3 12B or Qwen3-VL 8B (vision)
- **GCP dev/prod**: Gemini 2.0 Flash (primary for both text and vision)
- **Escalation tier**: Gemini 2.5 Pro (for complex/stuck cases)
- **Testing**: Mock provider

Research confirms Gemini Flash matches Claude at ~35x lower cost for screenshot-to-action tasks, with better structured JSON output via constrained decoding. See `07_gemini_vision_research.md`.

Adopt AWH's cost-optimization techniques:

- DOM pre-inspection (skip LLM when confidence ≥75)
- Batch fill (reduce N calls to 2 for form filling)
- Screenshot dedup (skip LLM on identical frames)
- Dual-model routing (cheap model for routine states)
- Prompt caching

### 2.3 State Machine vs Loop

**Recommendation: AWH's state machine with SSI phases as meta-states**

```
Phase 1: PASSIVE_RECON (SSI's OSINT pipeline — no LLM needed)
Phase 2: ACTIVE_INTERACTION (AWH's state machine)
  LOAD_SITE → FIND_REGISTER → FILL_REGISTER → SUBMIT_REGISTER
  → CHECK_EMAIL → NAVIGATE_DEPOSIT → EXTRACT_WALLETS
Phase 3: INTELLIGENCE (SSI's classification + evidence packaging)
```

Each phase can be run independently (passive-only mode, active-only mode, full pipeline).

### 2.4 Data Storage

**Recommendation: Extend core's `cases` table schema**

Each scanned site becomes a `case` in the core database. This piggybacks on the existing schema and enables the full analyst workflow (search, review queue, dossier generation).

New tables/columns needed:

- `wallet_harvests` table (linked to `case_id`) — extracted wallet addresses
- `site_interactions` table (linked to `case_id`) — agent session log (state transitions, actions, screenshots)
- `harvested_wallets` column on source_documents or as standalone table
- Extend `indicators` table to include wallet addresses as IOC type

See Section 3.3 of the Architecture/TDD doc for detailed schema.

### 2.5 Infrastructure: Drop Azure

**Decision: GCP-only (align with core/SSI)**

| AWH (Azure)              | Merged (GCP)                       |
| ------------------------ | ---------------------------------- |
| Azure Blob Storage       | GCS bucket                         |
| Azure VM + Bastion       | Cloud Run Job                      |
| Azure Firewall           | VPC Service Controls / Cloud Armor |
| Azurite (local)          | Local filesystem (align with SSI)  |
| `azure-storage-blob` SDK | `google-cloud-storage` SDK         |

The Azure portal guide and all Azure dependencies are dropped. Infrastructure-as-code via Terraform in `infra/`.

---

## 3. Merge Strategy

### 3.1 Repository Structure

The merged functionality lives in the existing `ssi/` repo, which becomes the **Scam Site Investigator + Wallet Harvester**. The `ssi` name is retained as it's already integrated into the i4g platform.

```
ssi/
  src/ssi/
    investigator/
      orchestrator.py          # Extended: passive + active + intelligence phases
    browser/
      agent.py                 # AWH's AgentController (adapted)
      browser_manager.py       # AWH's BrowserManager (zendriver, adapted)
      dom_inspector.py         # AWH's DOMInspector (ported)
      page_analyzer.py         # AWH's PageAnalyzer (adapted for pluggable LLM)
      capture.py               # SSI's passive capture (Playwright, kept)
      stealth.py               # SSI's stealth + AWH's anti-detection merged
      actions.py               # SSI's action executor (extended)
      captcha.py               # SSI's CAPTCHA detection (kept)
      har_analyzer.py          # SSI's HAR IOC extraction (kept)
      downloads.py             # SSI's download interception (kept)
    wallet/                    # NEW: AWH's wallet extraction pipeline
      extractor.py             # JS regex + LLM verification
      allowlist.py             # Token-network pair validation
      models.py                # WalletEntry, WalletHarvest
    osint/                     # SSI's OSINT modules (kept)
    identity/
      vault.py                 # SSI's vault (extended with AWH's crypto-username)
    classification/            # SSI's taxonomy classifier (kept)
    evidence/                  # SSI's evidence packaging (kept, extended)
    reports/                   # SSI's report generation (kept, extended)
    playbook/                  # NEW: AWH's playbook execution engine
      models.py                # Playbook data models (from AWH)
      matcher.py               # URL pattern matching
      executor.py              # NEW: Step execution engine
    monitoring/                # NEW: Real-time monitoring
      event_bus.py             # AWH's event bus (adapted)
      websocket.py             # WebSocket handler for UI
    models/                    # Unified data models
    llm/                       # SSI's pluggable provider (extended)
    settings/                  # SSI's layered config (extended)
    api/                       # SSI's FastAPI (extended)
```

### 3.2 What Comes from Where

| Component                 | Source  | Adaptation Needed                                                       |
| ------------------------- | ------- | ----------------------------------------------------------------------- |
| Orchestrator              | SSI     | Add active interaction phase, wallet extraction                         |
| Browser Agent (active)    | AWH     | Replace zendriver with abstraction layer, plug into SSI's LLM providers |
| Browser Capture (passive) | SSI     | Keep as-is                                                              |
| DOM Inspector             | AWH     | Port to SSI's module structure                                          |
| Page Analyzer             | AWH     | Replace Anthropic SDK with SSI's LLM abstraction                        |
| Wallet Extraction         | AWH     | Extract from BrowserManager into standalone module                      |
| Identity Vault            | SSI     | Add AWH's `generate_crypto_username()`                                  |
| OSINT Pipeline            | SSI     | Keep as-is                                                              |
| Classification            | SSI     | Keep as-is, add wallet data to classification context                   |
| Evidence Packaging        | SSI     | Add wallet manifest to evidence ZIP                                     |
| Playbook Engine           | AWH     | Implement execution logic (currently data model only)                   |
| Monitoring                | AWH     | Adapt WebSocket events for Next.js UI consumption                       |
| Config                    | SSI     | Extend with AWH's browser/proxy/cost settings                           |
| Data Storage              | Core    | Extend schema for wallets and interactions                              |
| API                       | SSI     | Extend endpoints for wallet-specific queries                            |
| UI                        | UI repo | Extend SSI page with wallet harvester controls and monitoring           |

### 3.3 What Gets Dropped

| Component                                | Reason                                                             |
| ---------------------------------------- | ------------------------------------------------------------------ |
| Azure Blob Storage                       | Replaced by GCS / local filesystem                                 |
| Azure Portal Guide                       | Replaced by Terraform in `infra/`                                  |
| Azurite Docker Compose                   | Not needed with local filesystem                                   |
| MCP server architecture                  | Over-engineered for identity + XLSX; direct function calls suffice |
| XLSX output                              | Replaced by database storage (wallets table) + CSV/XLSX export API |
| `send_guidance.py`                       | Replaced by WebSocket guidance in Next.js UI                       |
| Separate `agentic_wallet_harvester` repo | Consolidated into `ssi/`                                           |

---

## 4. Deep Site Scraping: Technology Survey

The user's key concern is deep site scraping — navigating multi-step scam funnels, filling forms, handling CAPTCHAs, etc. Here's a survey of approaches:

### 4.1 Current Approaches

| Approach                        | Used By        | Pros                                                   | Cons                                                                              |
| ------------------------------- | -------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------- |
| **Claude vision + zendriver**   | AWH            | Best-in-class vision understanding, undetected browser | Anthropic API costs, vendor lock-in, no free tier; **superseded by Gemini Flash** |
| **LLM chat agent + Playwright** | SSI (proposed) | Pluggable LLM, rich browser API                        | LLM not smart enough for complex interactions (acknowledged)                      |

### 4.2 Open-Source Alternatives Surveyed

#### browser-use (★78.6K, MIT)

- **What**: Python library for AI browser automation using any LLM (OpenAI, Anthropic, Gemini, local)
- **How**: Playwright-based, extracts DOM → numbered elements → sends to LLM → executes actions
- **Relevance**: Very similar to SSI's approach but more mature. Supports custom tools, MCP integration, sandboxed execution.
- **Cost**: Library is free; LLM costs apply. Has a cloud offering (paid) but not required.
- **Fit**: ★★★★☆ — Could replace SSI's browser agent loop. LLM-agnostic. Active development. However, uses Playwright (detectable) and DOM-text approach (not vision).

#### LaVague (★6.3K, Apache-2.0)

- **What**: "Large Action Model" framework for AI web agents
- **How**: World Model (LLM) + Action Engine (Selenium/Playwright) + RAG-based element selection
- **Relevance**: Similar concept but seems stale (last commits ~2 years ago). Less mature than browser-use.
- **Cost**: Free (Apache-2.0). LLM costs apply.
- **Fit**: ★★☆☆☆ — Stale project, smaller community. browser-use is the better choice in this category.

#### Playwright MCP Server (Anthropic official)

- **What**: MCP server wrapping Playwright for Claude to use as a tool
- **How**: Claude calls Playwright tools (navigate, click, type, screenshot) via MCP protocol
- **Cost**: Free (open source). LLM costs apply.
- **Fit**: ★★★☆☆ — Good for Claude-based agents but ties to MCP/Claude ecosystem.

### 4.3 Hybrid Approach: AWH's Vision + Playbook System

**Recommended strategy for the merged product:**

```
URL submitted
  │
  ▼
PlaybookMatcher.match(url)
  │
  ├─ Match found ──────▶ Playbook Executor (deterministic, zero LLM cost)
  │                       │
  │                       ├─ Step succeeds → next step
  │                       └─ Step fails → fallback to LLM Agent
  │
  └─ No match ──────────▶ LLM Agent (DOM Inspector → LLM vision fallback)
                           │
                           ├─ State machine: LOAD → REGISTER → DEPOSIT → EXTRACT
                           └─ Human guidance when stuck
```

**Why this is the best approach for a non-profit with GCP credits:**

1. **Playbooks are free**: Once a scam template is identified (many scam sites share identical frontends), a playbook handles it deterministically with zero LLM calls. This is the highest-ROI investment.
2. **DOM Inspector is free**: AWH's three-tier confidence scoring skips LLM calls ~40–60% of the time.
3. **Gemini Flash is near-free**: $0.0002/step for vision, effectively $0 on GCP nonprofit credits.
4. **Cost target: <$0.01 per full investigation** (vs. $0.18 with Claude).
5. **browser-use as potential future integration**: If the merged product outgrows the custom agent, browser-use provides a mature, LLM-agnostic framework that could be swapped in without rearchitecting.

### 4.4 CAPTCHA Considerations

CAPTCHAs remain the hardest unsolved problem. Options:

| Approach                   | Cost               | Reliability             | Legal Risk           |
| -------------------------- | ------------------ | ----------------------- | -------------------- |
| Skip (current SSI default) | Free               | N/A — gives up          | None                 |
| Wait for human (AWH-style) | Free               | 100% (human does it)    | None                 |
| Accessibility mode bypass  | Free               | Low (~10%)              | Low                  |
| 2Captcha / Anti-Captcha    | $2–3 per 1K solves | ~95%                    | Moderate TOS concern |
| CapSolver                  | $1–2 per 1K solves | ~90%                    | Moderate TOS concern |
| LLM vision attempt         | LLM call cost      | <20% for image CAPTCHAs | Low to moderate      |

**Recommendation**: Human-in-the-loop for CAPTCHAs (AWH's stuck handling). This is free and 100% reliable. Automated solving can be added later if volume demands it.

---

## 5. Data Collection Alignment

### 5.1 SSI PRD Data Tiers + AWH Additions

The merged product collects data from both SSI's three-tier framework and AWH's wallet-specific intelligence:

**Tier 1 — Passive Recon** (SSI):

- Screenshot, DOM snapshot, SSL cert, WHOIS/RDAP, DNS records, GeoIP, HTTP headers, redirect chain, technology fingerprint, external resources, form inventory, VirusTotal, urlscan.io

**Tier 2 — Active Interaction** (SSI + AWH):

- Form submissions with synthetic PII
- Multi-step funnel traversal recordings
- Agent decision reasoning logs
- Downloads (hashed, checked against VT)
- CAPTCHA detection
- HAR recording
- **NEW from AWH**: Wallet address extraction (token, network, address)
- **NEW from AWH**: Registration success/failure tracking
- **NEW from AWH**: Deposit page discovery and navigation

**Tier 3 — Intelligence Synthesis** (SSI + AWH):

- Fraud taxonomy classification
- Investigation report (JSON + Markdown + PDF)
- LEA evidence report
- STIX 2.1 bundle
- Evidence ZIP with SHA-256 manifest
- PII collection map
- **NEW from AWH**: Wallet manifest (all extracted addresses with token/network metadata)
- **NEW from AWH**: Blockchain intelligence readiness (wallet addresses ready for chain analysis)

> **Note**: Slides 12–17 describe eCX API endpoints (`/phish`, `/mal_domain`, `/crypto`, etc.) that serve as upstream data sources. The `/crypto` endpoint is directly relevant—SSI-harvested wallets should be cross-referenced against eCX's known-bad wallet database. Designed as a future integration (post-Phase 8).

---

## 6. UI Integration

### 6.1 Current State

- **SSI page** (`ui/apps/web/src/app/ssi/page.tsx`): Public page with URL submission → polling → risk score result card → PDF download
- **AWH dashboard** (`src/web_ui/static/index.html`): WebSocket-based monitoring with live screenshots, action log, and guidance interface

### 6.2 Merged UI Vision

Extend the existing SSI page in the Next.js UI with two modes:

1. **Quick Scan** (current SSI UX): Submit URL → passive recon + classification → result card
2. **Deep Investigation** (new): Submit URL → passive recon → active interaction (with live monitoring) → wallet extraction → full evidence package

**Auth decision**: The `/ssi` page is now **authenticated** (no longer excluded from IAP). Quick scan is a toggle on the same page. Public access can be revisited later.

The deep investigation mode adds:

- Live screenshot panel (WebSocket from SSI backend)
- Action log with state progression
- Human guidance interface (when agent is stuck)
- Wallet extraction results table
- Evidence download (ZIP, STIX, PDF)

This keeps the existing SSI page's simple UX for quick scans while adding depth for analysts who need the full pipeline.
