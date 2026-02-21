# Agentic Wallet Harvester (AWH) — Technical Analysis

> Deep-dive analysis of the `agentic_wallet_harvester` repository.
> Prepared for the SSI ↔ AWH consolidation initiative.

## 1. Purpose & Mission

AWH is a **vision-based agentic browser automation system** that investigates confirmed cryptocurrency scam websites. It autonomously:

1. Navigates to each scam site
2. Registers a throwaway account using synthetic PII
3. Finds the deposit/fund page
4. Extracts cryptocurrency wallet addresses (the scammer's receiving wallets)
5. Records all data in a structured XLSX spreadsheet and JSON artifacts

The extracted wallet addresses are the primary intelligence output — they enable blockchain tracing, exchange freezing requests, and prosecution evidence.

---

## 2. Architecture

### 2.1 Component Diagram

```
┌────────────────────────────────────────────────────────────────┐
│                      main.py (CLI)                             │
│       watch | run <file> | single <url>  [--web-ui]            │
└──────────┬──────────────────────┬──────────────────────────────┘
           │                      │
           ▼                      ▼
  ┌────────────────┐    ┌──────────────────┐
  │  TaskWatcher    │    │  Web UI Server   │ ← FastAPI + WebSocket
  │  (watcher.py)   │    │  (server.py)     │   at :8080
  └───────┬────────┘    └────────┬─────────┘
          │                      │
          ▼                      ▼
  ┌──────────────────────────────────────────┐
  │        AgentController (1,841 lines)     │
  │        Finite State Machine              │
  │                                          │
  │  ┌──────────────┐  ┌─────────────────┐  │
  │  │BrowserManager │  │  PageAnalyzer   │  │
  │  │(zendriver)    │  │  (Claude API)   │  │
  │  └──────┬───────┘  └───────┬─────────┘  │
  │         │                   │            │
  │  ┌──────┴───────┐  ┌───────┴─────────┐  │
  │  │DOMInspector   │  │Human Interaction│  │
  │  │(pre-LLM scan) │  │(console + WS)   │  │
  │  └──────────────┘  └─────────────────┘  │
  └──────────────┬───────────────────────────┘
                 │
   ┌─────────────┼─────────────┐
   ▼             ▼             ▼
┌────────┐  ┌─────────┐  ┌──────────────┐
│ Faker  │  │ XLSX    │  │ Blob Storage │
│ MCP    │  │ Writer  │  │ (Azure /     │
│ Server │  │ MCP     │  │  Azurite)    │
└────────┘  └─────────┘  └──────────────┘
```

### 2.2 State Machine

The core processing loop is a finite state machine defined in `src/agent/states.py`:

```
INIT → LOAD_SITE → FIND_REGISTER → FILL_REGISTER → SUBMIT_REGISTER
     → CHECK_EMAIL_VERIFICATION → NAVIGATE_DEPOSIT → EXTRACT_WALLETS → COMPLETE
```

Terminal states: `SKIPPED`, `ERROR`, `COMPLETE`.

### 2.3 Key Source Files

| File                                    | Lines  | Purpose                                                             |
| --------------------------------------- | ------ | ------------------------------------------------------------------- |
| `src/agent/controller.py`               | ~1,841 | State machine, orchestration, stuck detection                       |
| `src/agent/browser_manager.py`          | ~1,672 | CDP browser automation, click/type strategies, wallet JS extraction |
| `src/agent/page_analyzer.py`            | ~400   | Claude vision API calls, conversation management, cost tracking     |
| `src/agent/dom_inspector.py`            | ~350   | Pre-LLM DOM scanning with confidence scoring                        |
| `src/agent/human_interaction.py`        | ~200   | Console + WebSocket human-in-the-loop                               |
| `src/agent/metrics.py`                  | ~150   | Per-site strategy and cost metrics                                  |
| `src/web_ui/server.py`                  | ~200   | FastAPI + WebSocket monitoring server                               |
| `src/web_ui/static/index.html`          | ~635   | Single-page dark-themed monitoring dashboard                        |
| `src/mcp_servers/faker_server.py`       | ~100   | MCP tool server for synthetic identity generation                   |
| `src/mcp_servers/xlsx_writer_server.py` | ~150   | MCP tool server for wallet XLSX output                              |
| `src/infra/blob_storage.py`             | ~120   | Azure Blob Storage / Azurite abstraction                            |
| `src/models/*.py`                       | ~300   | Pydantic data models (task, action, wallet, site_result, playbook)  |

---

## 3. Technology Stack

| Layer                   | Technology                                | Purpose                                             |
| ----------------------- | ----------------------------------------- | --------------------------------------------------- |
| **Browser Automation**  | zendriver (CDP-based, undetected Chrome)  | Anti-detection Chromium automation                  |
| **LLM**                 | Anthropic Claude (Sonnet 4.5 + Haiku 4.5) | Vision-based page analysis + action decisions       |
| **MCP Protocol**        | `mcp[cli]` (Model Context Protocol)       | Tool servers for identity generation + XLSX writing |
| **Identity Generation** | Faker                                     | Throwaway registration identities                   |
| **Spreadsheet Output**  | openpyxl                                  | Structured wallet data output                       |
| **Blob Storage**        | azure-storage-blob + azure-identity       | Screenshot + result archival                        |
| **Image Processing**    | Pillow                                    | Screenshot downscaling for token cost reduction     |
| **Web UI**              | FastAPI + uvicorn + WebSockets            | Real-time monitoring dashboard                      |
| **Data Models**         | Pydantic v2                               | Input/output schemas                                |
| **Proxy**               | SmartProxy/Decodo residential proxies     | IP whitelisting evasion                             |
| **Config**              | python-dotenv                             | Environment variable loading                        |
| **Container**           | Docker + Docker Compose                   | Deployment (with Azurite sidecar)                   |

### 3.1 LLM Cost Model

The system uses a **dual-model strategy** to minimize cost:

- **Routine states** (FILL_REGISTER, SUBMIT_REGISTER, CHECK_EMAIL_VERIFICATION): Claude Haiku ($0.80/$4 per M tokens in/out)
- **Complex states** (all others): Claude Sonnet ($3/$15 per M tokens in/out)
- **Prompt caching**: Enabled for Sonnet (5-min ephemeral TTL), cache reads at 10% of input rate

### 3.2 Note on "OpenClaw"

The AWH codebase does **not** use OpenClaw. OpenClaw (`openclaw.new`) is a commercial AI assistant deployment platform for Telegram/Discord/WhatsApp — unrelated to browser scraping. AWH's actual automation approach is:

1. **Primary**: Claude vision API analyzing screenshots → deciding actions → zendriver executing them
2. **Planned (data model only)**: Playbook system (`src/models/playbook.py`) for deterministic scripted flows on known scam site templates — execution logic is not yet implemented

---

## 4. User Flow — End to End

### 4.1 Entry Points (`src/main.py`)

Three CLI modes:

| Mode     | Usage                             | Behavior                                                                           |
| -------- | --------------------------------- | ---------------------------------------------------------------------------------- |
| `watch`  | `python -m src.main watch`        | Polls `input/` for `.json` task files, processes them, moves to `input/processed/` |
| `run`    | `python -m src.main run <file>`   | Processes a single task file and exits                                             |
| `single` | `python -m src.main single <url>` | Wraps a single URL into a task and processes it                                    |

Optional `--web-ui` flag launches the FastAPI dashboard alongside the agent.

### 4.2 Per-Site Processing Flow

For each URL in a task file:

#### Step 1: LOAD_SITE

Browser navigates to the URL via zendriver. Cookie banners, chat widgets, and Google Translate overlays are auto-dismissed. Initial screenshot captured.

#### Step 2: FIND_REGISTER

DOM Inspector runs first (pre-LLM). If it finds a registration form (confidence ≥75), proceeds directly. If it finds a register link, clicks it. Below threshold, falls back to Claude vision analysis. Supports multilingual keywords (English, Chinese, Russian, Vietnamese, Thai, Spanish, Portuguese).

#### Step 3: FILL_REGISTER

Identity generated via Faker MCP server. Uses a **batch fill** optimization — sends one screenshot to Claude asking for ALL form-fill actions as a JSON array, then executes them all, followed by one verification call. Reduces LLM calls from N (one per field) to 2. Supports password variants (default, digits-only, alphanumeric) for different site requirements.

#### Step 4: SUBMIT_REGISTER

Clicks submit. DOM readback of form field values prevents Claude from confusing placeholder text with filled values. Error detection checks visible error messages, validation alerts, and `:invalid` fields.

#### Step 5: CHECK_EMAIL_VERIFICATION

Always handled by DOM Inspector with zero LLM calls. Checks for email verification text vs dashboard indicators. If email required → SKIPPED with appropriate status.

#### Step 6: NAVIGATE_DEPOSIT

DOM Inspector scans for deposit/fund links. Falls back to Claude if needed. Early-abort if deposit page is blank after retries → `BROKEN_DEPOSIT_PAGE` status.

#### Step 7: EXTRACT_WALLETS

JS pre-extraction runs first using regex patterns for wallet address formats (ETH `0x...`, TRX `T...`, BTC bech32 `bc1...`, BTC legacy `1.../3...`, XRP `r...`, ADA `addr1...`, SOL base58). Then discovers crypto coin tabs/buttons and clicks through each. Claude verifies and augments with network info.

#### Step 8: Post-processing

Wallets submitted to XLSX Writer MCP (validated against 26-pair token-network allowlist). Per-site JSON result saved locally and uploaded to Azure Blob Storage.

### 4.3 Human-in-the-Loop (Stuck Handling)

When `actions_in_state >= threshold` or the agent explicitly returns `STUCK`:

- **Web UI mode**: Emits `GUIDANCE_NEEDED` event with screenshot, context, and suggested actions. Blocks until human responds. UI renders clickable suggestion buttons.
- **Console mode**: Prints formatted alert to stdout and reads stdin. Supports `click`, `type`, `goto`, `skip`, `continue` commands.

Humans can also **interject** mid-step via the web UI without waiting for stuck detection.

### 4.4 Opportunistic Wallet Capture

During state transitions out of SUBMIT_REGISTER, CHECK_EMAIL, and NAVIGATE_DEPOSIT, a quick JS probe runs for any wallet address already visible on the page. This catches wallets before EXTRACT_WALLETS formally begins.

---

## 5. Data Models

### 5.1 Input: `HarvestTask` / `TaskFile` (`src/models/task.py`)

```python
class HarvestTask(BaseModel):
    url: str                    # Must be http:// or https://
    site_id: str | None = None  # Auto-derived from URL domain
    notes: str = ""

class TaskFile(BaseModel):
    run_id: str | None = None   # Auto-generated timestamp if omitted
    tasks: list[HarvestTask]
```

Input JSON supports both `{"tasks": [...]}` and bare `[...]` formats.

### 5.2 Output: `SiteResult` (`src/models/site_result.py`)

```python
class SiteResult(BaseModel):
    site_url: str
    site_id: str
    run_id: str
    status: SiteStatus          # completed | skipped | error | email_verification_required | ...
    wallets: list[WalletEntry]
    screenshots: list[str]      # Blob storage URLs
    error_message: str
    skip_reason: str
    actions_taken: int
    started_at: datetime | None
    completed_at: datetime | None
    llm_calls: int
    input_tokens: int
    output_tokens: int
    estimated_cost_usd: float
    metrics: dict
```

`SiteStatus` enum: `pending`, `in_progress`, `completed`, `skipped`, `needs_manual_review`, `email_verification_required`, `referral_code_required`, `broken_deposit_page`, `error`.

### 5.3 Wallet: `WalletEntry` (`src/models/wallet.py`)

```python
class WalletEntry(BaseModel):
    site_url: str
    token_label: str        # Raw label from site (e.g., "Bitcoin")
    token_symbol: str       # Mapped symbol (BTC, USDT, etc.)
    network_label: str      # Raw network from site
    network_short: str      # Mapped short code (btc, trx, eth, etc.)
    wallet_address: str
    harvested_at: datetime  # Auto-set to UTC now
    run_id: str
```

The `ALLOWED_TOKEN_NETWORKS` defines **26 approved token-network pairs**: 12 native tokens (BTC, ETH, BNB, SOL, TRX, ADA, DOGE, LTC, XRP, MATIC, DASH, BCH) + 8 USDT variants + 6 USDC variants across networks.

### 5.4 Actions: `AgentAction` (`src/models/action.py`)

```python
class AgentAction(BaseModel):
    action: ActionType  # click | type | select | key | navigate | scroll | wait | done | stuck
    selector: str       # CSS selector or text description
    value: str          # Text to type, URL to navigate, etc.
    reasoning: str      # Why Claude chose this action
    confidence: float   # 0.0–1.0
```

### 5.5 Playbook (Future): `src/models/playbook.py`

Defines a model for **deterministic scripted flows** for known site templates. Includes URL pattern matching (regex), step-by-step actions, retry logic, and fallback-to-LLM. `PlaybookMatcher` matches URLs to registered playbooks. **Data model only — execution logic not yet implemented.**

---

## 6. Browser Automation Deep Dive

### 6.1 Browser Engine: zendriver

zendriver is a CDP (Chrome DevTools Protocol) based automation library that is inherently undetected — unlike Selenium/Playwright which inject detectable markers. Additional anti-detection flags: `--disable-blink-features=AutomationControlled`, window size 1920×1080.

### 6.2 Click Strategies (4 Tiers with Fuzzy Fallback)

1. CSS `querySelector` → JS `.click()`
2. Text extraction from `:contains()` pseudo-selectors → JS text search across buttons/links
3. zendriver's `find()` (text/label matching)
4. **Fuzzy matching**: Keyword extraction from selectors (placeholder, name, id, aria-label, class) → scores all visible interactive elements by keyword overlap

### 6.3 Type Strategies (4 Tiers with Verification)

1. CSS `query_selector` → zendriver Element → clear → `send_keys` → fire `input`/`change` events → readback verify
2. zendriver `find` → same Element typing path
3. JS-only fallback: React-compatible native property setter + synthetic events
4. **Fuzzy find**: keyword extraction + scoring, then native setter

Every type action reads back the field value after typing and verifies correctness. Mismatches are tracked and injected into LLM context.

### 6.4 Overlay Dismissal

Removes: Google Translate widgets, cookie consent banners, chat widgets (Intercom, Crisp, Drift, Tawk, etc.) via `element.remove()`.

### 6.5 Wallet JS Extraction

- Scans readonly/disabled inputs, `data-clipboard-text` attributes, and visible text for regex patterns
- Discovers crypto coin tabs/buttons by scanning for known token symbols in clickable elements
- Clicks each discovered coin option and extracts the revealed wallet address

### 6.6 Screenshot Optimization

| Technique           | Savings                                                   |
| ------------------- | --------------------------------------------------------- |
| CSS zoom 0.75       | More content per screenshot                               |
| Downscale 1920→1280 | ~33% token savings                                        |
| MD5 dedup           | Skips LLM calls on identical frames                       |
| Text-only mode      | Skips image blocks for simple states (~1,200 tokens/call) |

---

## 7. Error Handling & Safety

| Mechanism                  | Behavior                                                |
| -------------------------- | ------------------------------------------------------- |
| Blank page detection       | Progressive backoff (2–5s), per-state retry limits      |
| Screenshot dedup           | MD5 hash, 5 consecutive dupes → force stuck             |
| Repeated action detection  | 3 identical actions → force stuck                       |
| Scroll loop detection      | 2 unchanged positions → inject warning to LLM           |
| Type verification          | Readback + mismatch injection into LLM context          |
| LLM error handling         | Empty/malformed response → STUCK + conversation cleanup |
| Global safety limit        | 80 actions/site max → NEEDS_MANUAL_REVIEW               |
| Per-state stuck thresholds | Configurable (e.g., EXTRACT_WALLETS=20, CHECK_EMAIL=3)  |
| Blob upload failures       | Logged, not fatal — local copies preserved              |
| MCP failures               | Falls back to hardcoded minimal identity                |
| WebSocket disconnections   | Auto-reconnect with exponential backoff                 |

---

## 8. Infrastructure & Deployment

### 8.1 Configuration (`config/settings.py`)

All config via environment variables (`.env` file):

| Category | Key Variables                                                                                         |
| -------- | ----------------------------------------------------------------------------------------------------- |
| LLM      | `ANTHROPIC_MODEL` (claude-sonnet-4-5), `ANTHROPIC_MODEL_CHEAP` (haiku), `ANTHROPIC_MAX_TOKENS` (1024) |
| Browser  | `HEADLESS` (true), `CHROME_BINARY`, `PAGE_LOAD_TIMEOUT` (45s), `PAGE_ZOOM` (0.75)                     |
| Proxy    | `SMARTPROXY_HOST` (gate.decodo.com), `SMARTPROXY_PORT` (10001)                                        |
| Azure    | `USE_AZURITE`, `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_CONTAINER`                                     |
| DOM      | `DOM_INSPECTION_ENABLED` (true), `DOM_DIRECT_THRESHOLD` (75), `DOM_ASSISTED_THRESHOLD` (40)           |
| Web UI   | `WEB_UI_HOST` (127.0.0.1), `WEB_UI_PORT` (8080)                                                       |
| Output   | `XLSX_PATH` (data/wallets.xlsx)                                                                       |

### 8.2 Docker

- **Dockerfile**: `python:3.11-slim-bookworm`, Chromium, non-root `agent` user, entrypoint `python -m src.main`
- **Docker Compose**: Two services — Azurite (Azure Storage emulator) + agent. Mounts `input/`, `output/`, `data/`. Memory 4G, 2 CPUs.

### 8.3 Azure Deployment

The repo includes an exhaustive Azure Portal guide (`azure/portal_guide.md`, 1,094 lines) for creating a secure sandbox:

- Phase 1: Resource Group → VNet (3 subnets) → NSG → VM (Standard_B2ms) → Azure Bastion
- Phase 2: Azure Firewall (Basic SKU) → Route Table → Application rules
- Phase 3: Storage Account + Blob Container → VM Managed Identity + RBAC
- Phase 4: Log Analytics → Firewall diagnostics
- Budget: ~$100 Azure credits, ~$16/day burn rate

### 8.4 Proxy Infrastructure

SmartProxy/Decodo residential proxies via IP whitelisting (no credentials in URL). Configured via `SMARTPROXY_HOST`/`SMARTPROXY_PORT`. The proxy is used to avoid IP-based blocking by scam sites.

---

## 9. Web UI Dashboard

Single-page dark-themed dashboard (`src/web_ui/static/index.html`, 635 lines):

- **Left panel**: Live screenshot (updates in real-time)
- **Right panel**: Scrolling action log with expandable detail
- **Bottom panel**: Guidance interface (appears when agent is stuck) with suggested action buttons + custom input
- **Header**: Connection badge, state badge, interject button, site URL
- **Communication**: WebSocket with auto-reconnect

Utility script `send_guidance.py` enables CLI-based guidance messages to a running agent.

---

## 10. Metrics & Cost Tracking

Per-site metrics (`src/agent/metrics.py`):

- Click/type strategy distribution (which tier succeeded)
- LLM calls by state
- Token usage series (per-call)
- Wasted actions count and type
- Screenshot sizes
- State timing
- DOM inspection outcomes (direct/assisted/fallback + LLM calls saved)
- Overlay removal count
- Estimated cost in USD (mixed-model, cache-aware)

---

## 11. Strengths

1. **Sophisticated browser automation** — 4-tier click/type strategies with fuzzy fallback
2. **Cost-optimized LLM usage** — Dual model (Sonnet/Haiku), DOM pre-inspection, batch fill, screenshot dedup, text-only mode
3. **Robust error handling** — Blank page detection, stuck handling, type verification, scroll loop detection
4. **Human-in-the-loop** — Both web UI and console modes for guidance when stuck
5. **Wallet extraction** — Combined JS regex + LLM verification with 26-pair allowlist
6. **Real-time monitoring** — WebSocket dashboard with live screenshots
7. **Opportunistic capture** — Catches wallets during state transitions, not just in EXTRACT_WALLETS

## 12. Limitations & Gaps

1. **Azure-only infrastructure** — Blob storage, deployment guide, and Docker Compose all Azure-centric
2. **No OSINT/recon capabilities** — No WHOIS, DNS, SSL, GeoIP, VirusTotal, or infrastructure intelligence
3. **No fraud classification** — No taxonomy, risk scoring, or classification pipeline
4. **No evidence packaging** — No ZIP with chain-of-custody, STIX bundles, or law enforcement reports
5. **No database** — Results are flat files (JSON + XLSX), no relational storage
6. **Playbook system unimplemented** — Data model exists but execution logic is missing
7. **No API** — CLI-only entry (the web UI is a monitoring dashboard, not a submission API)
8. **Single-threaded** — Processes one site at a time
9. **No auth/multi-tenancy** — No user management or access control
10. **zendriver vs Playwright** — zendriver has a much smaller community and ecosystem than Playwright
11. **Anthropic-only LLM** — Hardcoded to Claude, no provider abstraction or fallback
12. **CAPTCHA handling** — No explicit CAPTCHA detection or solving strategy
