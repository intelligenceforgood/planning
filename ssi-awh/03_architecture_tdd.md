# Merged SSI + AWH — Architecture & Technical Design Document

> Technical design for the consolidated Scam Site Investigator + Wallet Harvester product.
> This document covers the implementation stack, data schema, API design, and deployment model.

## 1. System Overview

The merged product is a **three-phase automated scam site investigation system**:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Analyst / Public User                          │
│                     Next.js UI (console + /ssi page)                     │
└───────────┬──────────────────────┬───────────────────────┬───────────────┘
            │ Submit URL           │ Monitor progress       │ Download evidence
            ▼                      ▼                        ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          SSI FastAPI Service                              │
│                          (Cloud Run / localhost:8100)                     │
│                                                                          │
│  POST /investigate          GET /investigate/{id}     GET /report/{id}   │
│  POST /investigate/batch    WS  /ws/monitor/{id}      GET /wallets/{id}  │
└───────────┬──────────────────────┬───────────────────────┬───────────────┘
            │                      │                        │
            ▼                      ▼                        ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────────────────┐
│ Phase 1          │  │ Phase 2           │  │ Phase 3                      │
│ Passive Recon    │  │ Active Interaction│  │ Intelligence Synthesis       │
│                  │  │                   │  │                              │
│ • WHOIS/RDAP     │  │ • State Machine   │  │ • Fraud Classification       │
│ • DNS            │  │   (zendriver)     │  │ • Evidence Packaging         │
│ • SSL/TLS        │  │ • DOM Inspector   │  │ • Report Generation          │
│ • GeoIP          │  │ • LLM Agent       │  │ • STIX 2.1 Bundle           │
│ • VirusTotal     │  │ • Wallet Extract  │  │ • Wallet Manifest            │
│ • urlscan.io     │  │ • Identity Vault  │  │ • PII Collection Map         │
│ • Screenshots    │  │ • Playbook Engine │  │                              │
│ • DOM/HAR        │  │ • Human Guidance  │  │                              │
└────────┬────────┘  └────────┬─────────┘  └────────────┬─────────────────┘
         │                     │                          │
         ▼                     ▼                          ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          Data Layer                                       │
│                                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Relational   │  │ Evidence     │  │ Vector   │  │ PII Vault        │  │
│  │ SQLite / PG  │  │ FS / GCS    │  │ Chroma / │  │ (Isolated)       │  │
│  │              │  │              │  │ Vertex   │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────┘  └──────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Technology Stack

### 2.1 Runtime Stack

| Layer                 | Local                                    | Dev (GCP)                                 | Prod (GCP)                                 |
| --------------------- | ---------------------------------------- | ----------------------------------------- | ------------------------------------------ |
| **Python**            | 3.11+ (conda `i4g-ssi`)                  | Cloud Run container                       | Cloud Run container                        |
| **API**               | FastAPI + uvicorn (port 8100)            | Cloud Run Service                         | Cloud Run Service                          |
| **Browser (Active)**  | zendriver + Chromium (headless)          | Cloud Run Job (gVisor)                    | Cloud Run Job (gVisor)                     |
| **Browser (Passive)** | Playwright + Chromium                    | Cloud Run Job                             | Cloud Run Job                              |
| **LLM (text)**        | Ollama (Llama 3.3)                       | Vertex AI Gemini 2.0 Flash                | Vertex AI Gemini 2.0 Flash                 |
| **LLM (vision)**      | Ollama (Gemma 3 12B / Qwen3-VL 8B)       | Vertex AI Gemini 2.0 Flash                | Vertex AI Gemini 2.0 Flash                 |
| **LLM (escalation)**  | —                                        | Vertex AI Gemini 2.5 Pro                  | Vertex AI Gemini 2.5 Pro                   |
| **Relational DB**     | SQLite (`data/ssi_store.db`)             | Cloud SQL PostgreSQL 15                   | Cloud SQL PostgreSQL 15                    |
| **Evidence Storage**  | Local FS (`data/evidence/`)              | GCS bucket                                | GCS bucket                                 |
| **Vector Store**      | Chroma (local)                           | Vertex AI Search                          | Vertex AI Search                           |
| **PII Vault**         | SQLite (isolated file)                   | Isolated Cloud SQL instance               | Isolated Cloud SQL instance                |
| **Proxy**             | Decodo residential (premium acct)        | Decodo residential (premium acct)         | Decodo residential (premium acct)          |
| **Secrets**           | `.env.local`                             | GCP Secret Manager                        | GCP Secret Manager                         |
| **Config**            | `settings.local.toml` + `SSI_*` env vars | `settings.dev.toml` + env vars            | `settings.prod.toml` + env vars            |
| **IaC**               | N/A                                      | Terraform (`infra/environments/app/dev/`) | Terraform (`infra/environments/app/prod/`) |

### 2.2 Key Dependencies

```toml
[project.dependencies]
# Web framework
fastapi = ">=0.115"
uvicorn = {version = ">=0.34", extras = ["standard"]}
websockets = ">=13.0"

# Browser automation
zendriver = ">=0.5"          # CDP-based undetected Chrome (active interaction)
playwright = ">=1.49"        # Feature-rich browser (passive capture, HAR)

# LLM providers
google-generativeai = ">=0.8"     # Gemini 2.0 Flash + 2.5 Pro (primary)

# OSINT
python-whois = ">=0.9"
dnspython = ">=2.7"
requests = ">=2.32"               # VirusTotal, urlscan, GeoIP APIs

# Data & models
pydantic = ">=2.10"
sqlalchemy = ">=2.0"
alembic = ">=1.14"

# Identity
faker = ">=33.0"

# Evidence & reports
jinja2 = ">=3.1"
weasyprint = ">=63.0"            # PDF generation
stix2 = ">=3.0"                  # STIX 2.1 threat intel
pillow = ">=11.0"                # Screenshot processing
openpyxl = ">=3.1"               # XLSX export

# GCP
google-cloud-storage = ">=2.18"
google-cloud-sql-connector = ">=1.12"

# Config
dynaconf = ">=3.2"               # Layered settings (TOML + env)
```

### 2.3 Browser Engine Decision: Dual-Engine Architecture

The merged product runs **two browser engines** for different purposes:

```
┌──────────────────────────────────┐
│ zendriver (CDP, undetected)       │ ← Active interaction
│ • Registration form filling       │   (stealth matters)
│ • Deposit page navigation         │
│ • Wallet extraction               │
│ • Multi-step funnel traversal     │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│ Playwright (feature-rich)         │ ← Passive capture
│ • Full-page screenshots           │   (features matter)
│ • DOM snapshots                   │
│ • HAR network recording           │
│ • Download interception           │
│ • Form field inventory            │
└──────────────────────────────────┘
```

Both engines share the same proxy configuration and stealth settings. The orchestrator decides which engine to use based on the investigation phase.

---

## 3. Data Architecture

### 3.1 Mapping to Core's Schema

The merged product extends core's existing database schema. Each scanned site is a **case** (`cases` table), enabling full integration with the analyst review queue, search, and dossier generation.

```
                            ┌──────────────┐
                            │ ingestion_   │
                            │ runs         │
                            └──────┬───────┘
                                   │ 1:N
                            ┌──────▼───────┐
                            │   cases      │ ← Each scam site = one case
                            │              │
                            │ source_type: │
                            │   "ssi_scan" │
                            └──────┬───────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                     │
    ┌─────────▼──────────┐ ┌──────▼───────┐ ┌──────────▼──────────┐
    │ source_documents   │ │ entities     │ │ indicators          │
    │                    │ │              │ │                     │
    │ • investigation.json│ │ • domain    │ │ • wallet addresses  │
    │ • screenshots      │ │ • IP addrs  │ │ • IPs / domains     │
    │ • HAR files        │ │ • registrant│ │ • URLs              │
    │ • DOM snapshots    │ │ • SSL issuer│ │ • hashes            │
    └────────────────────┘ └──────────────┘ └─────────────────────┘
              │
    ┌─────────▼──────────┐
    │ NEW: site_scans    │ ← SSI-specific investigation metadata
    │                    │
    │ • scan_type        │   (passive | active | full)
    │ • scan_status      │   (queued | running | completed | failed)
    │ • passive_result   │   (JSONB: WHOIS, DNS, SSL, GeoIP, etc.)
    │ • active_result    │   (JSONB: agent session summary)
    │ • wallet_count     │
    │ • classification   │   (JSONB: 5-axis taxonomy result)
    │ • risk_score       │
    │ • evidence_path    │
    │ • cost_usd         │
    │ • llm_calls        │
    │ • tokens_used      │
    │ • started_at       │
    │ • completed_at     │
    └────────────────────┘

    ┌────────────────────┐
    │ NEW: harvested_    │ ← Wallet addresses (core intelligence)
    │ wallets            │
    │                    │
    │ • wallet_id (PK)   │
    │ • case_id (FK)     │
    │ • scan_id (FK)     │
    │ • token_symbol     │   (BTC, ETH, USDT, etc.)
    │ • network_short    │   (btc, eth, trx, bsc, etc.)
    │ • wallet_address   │
    │ • source_label     │   (raw label from site)
    │ • extraction_method│   (js_regex | llm_verified | playbook)
    │ • confidence       │   (0.0–1.0)
    │ • harvested_at     │
    └────────────────────┘

    ┌────────────────────┐
    │ NEW: agent_sessions│ ← Detailed interaction log
    │                    │
    │ • session_id (PK)  │
    │ • scan_id (FK)     │
    │ • state            │   (current FSM state)
    │ • action_type      │   (click | type | select | scroll | ...)
    │ • selector         │
    │ • value            │
    │ • reasoning        │   (LLM's explanation)
    │ • confidence       │
    │ • strategy_used    │   (css | text | fuzzy | dom_direct)
    │ • screenshot_path  │
    │ • timestamp        │
    └────────────────────┘

    ┌────────────────────┐
    │ NEW: pii_exposures │ ← What PII the scam site collects
    │                    │
    │ • exposure_id (PK) │
    │ • scan_id (FK)     │
    │ • field_label      │   (e.g., "Social Security Number")
    │ • field_type       │   (ssn | credit_card | email | phone | ...)
    │ • collection_step  │   (which agent step captured this)
    │ • form_action_url  │   (where the form submits to)
    │ • is_required      │
    └────────────────────┘
```

### 3.2 Schema Feasibility Assessment

**Can we piggyback on the existing core schema?**

**Yes, with caveats:**

| Core Table                        | SSI Usage                                                                                                                                    | Fit                                           |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- |
| `cases`                           | Each scam site = one case. Use `source_type="ssi_scan"`, `classification`/`classification_result` for fraud taxonomy, `risk_score` for risk. | ✅ Excellent fit                              |
| `ingestion_runs`                  | Each batch scan = one ingestion run, with `source_type="ssi"`.                                                                               | ✅ Good fit                                   |
| `campaigns`                       | Group related scam sites (same scam cluster, same frontend template).                                                                        | ✅ Good fit                                   |
| `source_documents`                | Store investigation.json, screenshots, HAR, DOM as documents.                                                                                | ✅ Good fit                                   |
| `entities`                        | Store domains, IPs, registrants, SSL issuers as entities.                                                                                    | ✅ Good fit                                   |
| `indicators`                      | Store wallet addresses, malicious IPs/domains/URLs as threat indicators.                                                                     | ✅ Good fit — wallet addresses ARE indicators |
| `review_queue` / `review_actions` | Flagged sites enter analyst review.                                                                                                          | ✅ Excellent fit                              |
| `dossier_queue`                   | Generate investigation dossiers for cases.                                                                                                   | ✅ Good fit                                   |

**New tables needed** (not available in core's current schema):

| New Table           | Reason                                                                                                                                                                                              |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `site_scans`        | SSI-specific scan metadata (passive/active results, cost, timing). Core's `cases` table doesn't have fields for scan-specific data like LLM cost, agent session stats, etc.                         |
| `harvested_wallets` | Crypto wallet addresses are the primary intelligence output. While they could be stored as `indicators`, a dedicated table enables richer metadata (token, network, extraction method, confidence). |
| `agent_sessions`    | Detailed per-action log for the browser agent. This is investigation-specific audit trail data that doesn't fit core's generic schema.                                                              |
| `pii_exposures`     | Maps what PII the scam site collects, at which step. This is a unique SSI capability.                                                                                                               |

**Migration strategy**: Add new tables via Alembic migration in core. SSI reads/writes through core's `StructuredStore` pattern (session factory from `factories.py`).

### 3.3 Evidence Storage Layout

```
data/evidence/{case_id}/
  ├── investigation.json         # Full structured result
  ├── report.md                  # Human-readable report
  ├── report.pdf                 # PDF version
  ├── leo_evidence_report.md     # Law enforcement summary
  ├── stix_bundle.json           # STIX 2.1 IOC bundle
  ├── wallet_manifest.json       # All extracted wallet addresses
  ├── evidence.zip               # All artifacts + SHA-256 manifest
  ├── passive/
  │   ├── screenshot.png         # Full-page screenshot
  │   ├── dom.html               # DOM snapshot
  │   ├── network.har            # HAR recording
  │   ├── ssl_cert.json          # SSL certificate details
  │   ├── whois.json             # WHOIS/RDAP record
  │   ├── dns.json               # DNS records
  │   └── geoip.json             # IP geolocation
  └── active/
      ├── session_log.json       # Agent action-by-action log
      ├── screenshots/
      │   ├── 01_load_site.png
      │   ├── 02_find_register.png
      │   ├── 03_fill_register.png
      │   ├── ...
      │   └── NN_extract_wallets.png
      └── wallets/
          └── extraction_detail.json  # Per-wallet extraction metadata
```

---

## 4. API Design

### 4.1 Extended SSI API Endpoints

```
# Investigation lifecycle
POST   /investigate                    # Submit URL for investigation
POST   /investigate/batch              # Submit batch of URLs
GET    /investigate/{id}               # Poll investigation status
GET    /investigate/{id}/wallets       # Get extracted wallets for an investigation
DELETE /investigate/{id}               # Cancel a running investigation

# Reports & evidence
GET    /report/{id}/pdf                # Download PDF report
GET    /report/{id}/evidence           # Download evidence ZIP
GET    /report/{id}/stix              # Download STIX bundle
GET    /report/{id}/wallets.xlsx       # Download wallet manifest as XLSX

# Real-time monitoring (WebSocket)
WS     /ws/monitor/{id}               # Live investigation monitoring
                                       # Events: state_change, screenshot, action,
                                       #         guidance_needed, wallet_found, complete

# Human guidance (WebSocket)
WS     /ws/guidance/{id}              # Send guidance to stuck agent
                                       # Commands: click, type, goto, skip, continue

# Wallet intelligence
GET    /wallets                        # Search across all harvested wallets
GET    /wallets/{address}              # Lookup a specific wallet address
GET    /wallets/stats                  # Aggregated stats (top tokens, networks)

# Playbook management
GET    /playbooks                      # List registered playbooks
POST   /playbooks                      # Create a new playbook
GET    /playbooks/{id}                 # Get playbook details
PUT    /playbooks/{id}                 # Update a playbook
DELETE /playbooks/{id}                 # Delete a playbook

# Health
GET    /health                         # Service health check
```

### 4.2 Investigation Request Model

```python
class InvestigateRequest(BaseModel):
    url: str                           # Target URL (required)
    scan_type: ScanType = "full"       # passive | active | full
    playbook_id: str | None = None     # Force a specific playbook
    enable_wallet_extraction: bool = True
    enable_classification: bool = True
    enable_evidence_package: bool = True
    callback_url: str | None = None    # Webhook on completion
    priority: int = 0                  # Queue priority
    notes: str = ""
```

### 4.3 Investigation Response Model

```python
class InvestigationStatus(BaseModel):
    investigation_id: str
    case_id: str                       # Core case ID (for analyst console linkage)
    url: str
    status: str                        # queued | passive_recon | active_interaction |
                                       # classifying | packaging | completed | failed
    current_state: str | None          # FSM state (e.g., FILL_REGISTER)
    progress_pct: int                  # 0–100
    wallets_found: int
    risk_score: float | None
    classification: str | None
    started_at: datetime | None
    completed_at: datetime | None
    cost_usd: float
    error_message: str | None
```

---

## 5. Investigation Pipeline Detail

### 5.1 Orchestrator Flow

```python
async def investigate(url: str, scan_type: ScanType) -> InvestigationResult:
    """Three-phase investigation pipeline."""

    # Create case in core DB
    case = await create_case(url, source_type="ssi_scan")
    scan = await create_site_scan(case.case_id, scan_type)

    # Phase 1: Passive Recon (always runs)
    if scan_type in ("passive", "full"):
        passive = await run_passive_recon(url)
        await store_passive_results(scan, passive)
        await store_entities(case, passive)         # domains, IPs, registrants
        await store_indicators(case, passive)       # IOCs from recon

    # Phase 2: Active Interaction (if requested)
    if scan_type in ("active", "full"):
        # Check playbook first
        playbook = playbook_matcher.match(url)
        if playbook:
            active = await run_playbook(url, playbook, fallback=run_agent)
        else:
            active = await run_agent(url)

        await store_active_results(scan, active)
        await store_wallets(case, scan, active.wallets)
        await store_agent_session(scan, active.session_log)
        await store_pii_exposures(scan, active.pii_map)

    # Phase 3: Intelligence Synthesis (always runs)
    classification = await classify(case, passive, active)
    await update_case_classification(case, classification)

    evidence = await package_evidence(case, passive, active, classification)
    report = await generate_report(case, passive, active, classification)

    return InvestigationResult(case=case, scan=scan, evidence=evidence, report=report)
```

### 5.2 Active Interaction State Machine

```
                    ┌─────────────┐
                    │    INIT     │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  LOAD_SITE  │ ← Navigate, dismiss overlays, screenshot
                    └──────┬──────┘
                           │
                    ┌──────▼──────────┐
                    │  FIND_REGISTER  │ ← DOM Inspector (≥75 → direct, ≥40 → assisted)
                    └──────┬──────────┘  ← LLM fallback if <40
                           │
                    ┌──────▼──────────┐
                    │  FILL_REGISTER  │ ← Generate identity, batch fill via LLM
                    └──────┬──────────┘  ← 4-tier type strategies + verification
                           │
                    ┌──────▼───────────┐
                    │ SUBMIT_REGISTER  │ ← Click submit, check for errors
                    └──────┬───────────┘  ← Opportunistic wallet scan
                           │
                    ┌──────▼─────────────────┐
                    │ CHECK_EMAIL_VERIFICATION│ ← DOM-only (zero LLM calls)
                    └──────┬─────────────────┘
                           │
               ┌───────────┼───────────────┐
               │ email required            │ no email needed
               ▼                           ▼
        ┌──────────┐              ┌────────────────┐
        │ SKIPPED  │              │NAVIGATE_DEPOSIT│ ← DOM Inspector + LLM
        └──────────┘              └───────┬────────┘
                                          │
                                  ┌───────▼────────┐
                                  │EXTRACT_WALLETS │ ← JS regex + coin tab discovery
                                  └───────┬────────┘  ← LLM verification
                                          │
                                  ┌───────▼────────┐
                                  │   COMPLETE     │
                                  └────────────────┘
```

At any state, stuck detection can trigger → `GUIDANCE_NEEDED` → human intervention via WebSocket.

### 5.3 Four-Tier Decision Cascade

Each interaction step uses the cheapest strategy that can resolve the current state:

```
Step needed (e.g., "find the Register button")
  │
  ├─ Tier 1: Playbook ($0)
  │   Known site template? → Execute deterministic step
  │
  ├─ Tier 2: DOM Inspector ($0)
  │   AWH's three-tier confidence scoring:
  │   • ≥75 confidence → direct action (no LLM)
  │   • ≥40 confidence → assisted (narrow candidate set for LLM)
  │   • <40 → fall through to Tier 3
  │
  ├─ Tier 3: Gemini Flash text (~$0.0001/step)
  │   DOM extraction → numbered elements → LLM picks action
  │   Works for most form fills, navigation, etc.
  │
  ├─ Tier 4: Gemini Flash vision (~$0.0002/step)
  │   Screenshot → LLM analyzes visual layout → action
  │   For: overlays, dynamic UIs, canvas-rendered content, error states
  │
  └─ Fallback: Human guidance ($0)
      WebSocket notification → analyst intervenes
```

**Cost target: <$0.01 per full investigation.** See `06_flexible_scan_research.md` for detailed analysis.

### 5.5 LLM Provider Abstraction

```python
class LLMProvider(ABC):
    """Abstract base for LLM providers."""

    @abstractmethod
    async def analyze_page(
        self,
        screenshot: bytes | None,
        page_text: str,
        context: AgentContext,
        system_prompt: str,
    ) -> AgentAction:
        """Analyze page state and return next action."""

    @abstractmethod
    async def classify(
        self,
        investigation_data: dict,
        taxonomy_prompt: str,
    ) -> ClassificationResult:
        """Classify site using fraud taxonomy."""

    @abstractmethod
    async def batch_fill(
        self,
        screenshot: bytes,
        form_context: str,
        identity: dict,
    ) -> list[AgentAction]:
        """Generate all form-fill actions in one call."""


class OllamaProvider(LLMProvider):     # Local dev: Llama 3.3 (text), Gemma 3 12B / Qwen3-VL 8B (vision)
class GeminiProvider(LLMProvider):     # GCP dev/prod: Gemini 2.0 Flash (primary), 2.5 Pro (escalation)
class MockProvider(LLMProvider):       # Testing
```

### 5.6 Playbook Execution Engine

```python
class PlaybookExecutor:
    """Execute deterministic scripted flows for known site templates."""

    async def execute(
        self,
        url: str,
        playbook: Playbook,
        browser: BrowserManager,
        identity: dict,
        fallback_agent: AgentController | None = None,
    ) -> ActiveInteractionResult:
        """Execute playbook steps sequentially.

        For each step:
        1. Resolve template variables ({identity.email}, etc.)
        2. Execute action (click, type, navigate, wait, extract)
        3. Verify success (optional: screenshot comparison)
        4. On failure: retry N times, then fallback to LLM agent if configured
        """
```

Playbooks are stored as JSON files (or in DB) and matched by URL regex pattern. They eliminate LLM costs for known scam site templates — a critical optimization for a zero-budget non-profit.

---

## 6. Configuration

### 6.1 Settings Schema Extension

Extend SSI's existing settings with AWH-specific sections:

```toml
# config/settings.default.toml

[llm]
provider = "ollama"                    # ollama | gemini | mock
model = "llama3.3"                     # Text model
model_vision = "gemma3:12b"            # Vision model (local: gemma3 or qwen3-vl)
model_cheap = ""                       # Optional cheaper model for routine states
model_escalation = ""                  # Gemini 2.5 Pro for hard cases (cloud only)
max_tokens = 1024
vision_enabled = true                   # Enable vision-based page analysis
prompt_cache_enabled = true

[browser]
headless = true
engine = "zendriver"                   # zendriver (active) | playwright (passive)
page_load_timeout = 45
action_timeout = 15
page_zoom = 0.75
chrome_binary = ""

[browser.stealth]
randomize_fingerprint = true
rotate_user_agent = true

[browser.proxy]
enabled = true
host = ""                              # Decodo residential proxy (premium account)
port = 0
username = ""
password = ""

[browser.dom_inspector]
enabled = true
direct_threshold = 75
assisted_threshold = 40

[browser.cost]
screenshot_resize_width = 1280
max_context_messages = 6

[wallet]
extraction_enabled = true
allowed_token_networks = "config/wallet_allowlist.json"  # Expanded + configurable JSON file

[agent]
max_actions_per_site = 80
stuck_thresholds = {FIND_REGISTER = 8, FILL_REGISTER = 15, SUBMIT_REGISTER = 10, CHECK_EMAIL_VERIFICATION = 3, NAVIGATE_DEPOSIT = 10, EXTRACT_WALLETS = 20}
max_repeated_actions = 3
enable_batch_fill = true
enable_opportunistic_wallet_scan = true

[playbook]
enabled = true
playbook_dir = "config/playbooks"      # Directory of playbook JSON files

[monitoring]
websocket_enabled = true
screenshot_broadcast = true
event_retention_hours = 24

[osint]
# Existing SSI OSINT settings (unchanged)
virustotal_api_key = ""
urlscan_api_key = ""
ipinfo_token = ""

[evidence]
storage_backend = "local"              # local | gcs
gcs_bucket = ""
local_dir = "data/evidence"

[identity]
default_locale = "en_US"
rotate_per_session = true
email_domain = "i4g-probe.net"

[api]
host = "0.0.0.0"
port = 8100

[integration]
core_api_url = ""                      # i4g core API for case creation
core_api_key = ""
```

---

## 7. UI Design

### 7.1 Page Structure

Single authenticated page with progressive disclosure:

```
/ssi                          ← Investigation page (authenticated — quick scan toggle + full pipeline)
/ssi/investigations           ← Investigation list/history
/ssi/investigations/{id}      ← Investigation detail (3-tab view)
/ssi/wallets                  ← Wallet search/browse
/ssi/playbooks                ← Playbook management (Phase 8+)
```

The `/ssi` page is **authenticated** (no longer excluded from IAP middleware). It includes a "Quick Scan" toggle for passive-only mode on the same page. Public access can be revisited later if needed.

### 7.2 Investigation Detail Page (3-Tab View)

```
┌─────────────────────────────────────────────────────────────┐
│ Investigation: https://scam-example.com                      │
│ Status: ● Active Interaction (FILL_REGISTER)    Cost: $0.12  │
├─────────────┬──────────────────┬────────────────────────────┤
│  Recon      │  Live Monitor    │  Results                    │
├─────────────┴──────────────────┴────────────────────────────┤
│                                                              │
│  [Tab: Recon]                                                │
│  ┌────────────────────┐  ┌─────────────────────────────┐    │
│  │ WHOIS              │  │ DNS Records                 │    │
│  │ Registrar: ...     │  │ A: 1.2.3.4                  │    │
│  │ Created: ...       │  │ MX: ...                     │    │
│  └────────────────────┘  └─────────────────────────────┘    │
│  ┌────────────────────┐  ┌─────────────────────────────┐    │
│  │ SSL Certificate    │  │ GeoIP                       │    │
│  │ Issuer: Let's...   │  │ US / Cloudflare / AS13335   │    │
│  └────────────────────┘  └─────────────────────────────┘    │
│                                                              │
│  [Tab: Live Monitor]                                         │
│  ┌──────────────────────┐  ┌───────────────────────────┐    │
│  │ Live Screenshot       │  │ Action Log                │    │
│  │ [real-time image]     │  │ • Clicked "Register"      │    │
│  │                       │  │ • Typed email: test@...    │    │
│  │                       │  │ • Typed password: ****     │    │
│  │                       │  │ • Clicked "Submit"         │    │
│  └──────────────────────┘  └───────────────────────────┘    │
│  ┌──────────────────────────────────────────────────────┐    │
│  │ ⚠ Agent needs guidance                               │    │
│  │ [Continue] [Skip] [Click: ___] [Type: ___] [Go to]   │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  [Tab: Results]                                              │
│  ┌────────────────────────────────────────────────────┐      │
│  │ Risk Score: 87/100  Classification: Investment Scam│      │
│  ├────────────────────────────────────────────────────┤      │
│  │ Wallets Found (3)                                  │      │
│  │ BTC  │ bc1q...xyz  │ Bitcoin network               │      │
│  │ USDT │ TRx7...abc  │ Tron network                  │      │
│  │ ETH  │ 0x4f...def  │ Ethereum network              │      │
│  ├────────────────────────────────────────────────────┤      │
│  │ PII Collected by Site                              │      │
│  │ • Email (step 2)  • Full Name (step 2)             │      │
│  │ • Phone (step 3)  • SSN (step 4) ⚠                 │      │
│  ├────────────────────────────────────────────────────┤      │
│  │ [Download PDF] [Download Evidence ZIP] [View STIX] │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### 7.3 WebSocket Communication

The Next.js UI communicates with the SSI backend via:

1. **REST API** (via Next.js API route proxies) for investigation lifecycle
2. **WebSocket** (direct to SSI backend) for real-time monitoring

```typescript
// Frontend WebSocket handling
interface MonitorEvent {
  type:
    | "state_change"
    | "screenshot"
    | "action"
    | "guidance_needed"
    | "wallet_found"
    | "progress"
    | "complete"
    | "error";
  investigation_id: string;
  timestamp: string;
  data:
    | StateChangeData
    | ScreenshotData
    | ActionData
    | GuidanceData
    | WalletData;
}

// Guidance commands sent from UI to backend
interface GuidanceCommand {
  type: "click" | "type" | "goto" | "skip" | "continue";
  value?: string; // selector for click, text for type, URL for goto
  reason?: string; // human's reasoning
}
```

---

## 8. Deployment Architecture

### 8.1 GCP Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GCP Project (i4g-dev)                 │
│                                                              │
│  ┌──────────────────┐     ┌──────────────────────────┐      │
│  │ Cloud Run Service │     │ Cloud Run Job             │      │
│  │ ssi-api           │     │ ssi-investigation         │      │
│  │ (FastAPI + WS)    │────▶│ (Browser + LLM + OSINT)  │      │
│  └────────┬─────────┘     └────────────┬─────────────┘      │
│           │                             │                     │
│  ┌────────▼──────────────────────────────▼────────────────┐  │
│  │                   VPC Network                          │  │
│  │                                                        │  │
│  │  ┌────────────┐  ┌─────────────┐  ┌───────────────┐   │  │
│  │  │ Cloud SQL  │  │ GCS Bucket  │  │ Secret Manager│   │  │
│  │  │ (Postgres) │  │ (evidence)  │  │ (API keys)    │   │  │
│  │  └────────────┘  └─────────────┘  └───────────────┘   │  │
│  │                                                        │  │
│  │  ┌────────────────┐  ┌─────────────────────────┐      │  │
│  │  │ Vertex AI      │  │ Artifact Registry       │      │  │
│  │  │ (Gemini API)   │  │ (Docker images)         │      │  │
│  │  └────────────────┘  └─────────────────────────┘      │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ IAP (Identity-Aware Proxy) — protects SSI API           │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 8.2 Terraform Resources (New)

Add to `infra/environments/app/dev/`:

```
ssi_cloud_run.tf          # SSI API Cloud Run service
ssi_cloud_run_job.tf      # SSI investigation Cloud Run job
ssi_gcs.tf                # Evidence GCS bucket
ssi_secrets.tf            # OSINT API keys, proxy credentials
ssi_iam.tf                # sa-ssi service account + roles
```

### 8.3 Docker Images

Two container images (same pattern as core):

```
# SSI API server
docker/ssi-api.Dockerfile
  → python:3.11-slim-bookworm
  → FastAPI + uvicorn
  → No browser dependencies

# SSI investigation job
docker/ssi-job.Dockerfile
  → python:3.11-slim-bookworm
  → Chromium + zendriver + Playwright
  → OSINT libraries
  → WeasyPrint (PDF generation)
```

---

## 9. Testing Strategy

| Level           | Scope                                                                 | Tools                         |
| --------------- | --------------------------------------------------------------------- | ----------------------------- |
| **Unit**        | Models, DOM Inspector, wallet regex, playbook matcher, identity vault | pytest                        |
| **Integration** | LLM provider calls, DB operations, evidence packaging                 | pytest + fixtures             |
| **Browser**     | Page capture, form fill, wallet extraction (against test sites)       | pytest + zendriver/Playwright |
| **API**         | Endpoint contracts, WebSocket events                                  | pytest + httpx + websockets   |
| **E2E**         | Full investigation pipeline (against controlled test scam sites)      | pytest + Docker Compose       |

### 9.1 Test Infrastructure

A set of **controlled test scam sites** (static HTML files served locally) enables repeatable browser testing without hitting real scam sites:

```
tests/fixtures/sites/
  ├── simple_registration/     # Basic form + deposit page
  ├── multi_step_funnel/       # 3-page registration flow
  ├── email_verification/      # Requires email (should be skipped)
  ├── captcha_protected/       # Has reCAPTCHA (test detection)
  ├── wallet_display/          # Various wallet display patterns
  └── broken_site/             # 404s, timeouts, blank pages
```

---

## 10. Security Considerations

| Concern                           | Mitigation                                                                         |
| --------------------------------- | ---------------------------------------------------------------------------------- |
| Running untrusted code in browser | gVisor sandbox on Cloud Run, Chromium sandboxing                                   |
| PII exposure                      | Identity Vault uses invalid SSN ranges, test credit cards, controlled email domain |
| Scam site retaliation             | Residential proxy rotation, fingerprint randomization                              |
| Evidence integrity                | SHA-256 chain-of-custody manifest in every evidence ZIP                            |
| API access control                | IAP on Cloud Run, API key for service-to-service                                   |
| Sensitive OSINT keys              | GCP Secret Manager, never in code/config                                           |
| Legal (CFAA/CMA)                  | Automated interaction with scam sites requires legal review (flagged in SSI PRD)   |
