# Proposal: Sec-Gemini SDK Integration into SSI

> **Status**: ✅ IMPLEMENTED — Merged as optional enrichment provider
> **Author**: Product Management + Architecture
> **Date**: 2026-05-12
> **Audience**: Engineering Team, Lead Engineer

---

## Executive Summary

**Recommendation: CONDITIONAL GO** — integrate Sec-Gemini as an *optional enrichment provider* in SSI's Phase 1 (Passive Recon), not as a replacement for any existing capability.

Sec-Gemini is a cloud-hosted security AI agent from Google that orchestrates reconnaissance, vulnerability analysis, and reporting via an asyncio Python SDK. It provides access to Google's near-real-time threat intelligence and autonomous tool orchestration — capabilities SSI does not have today.

The integration is worth pursuing because:
1. It fills a **gap in threat intelligence correlation** that SSI's current OSINT modules don't cover (CVE/vuln lookup, email security posture, infrastructure fingerprinting via AI reasoning).
2. The SDK is **asyncio-native Python** — a natural fit for SSI's stack.
3. The integration surface is **small and well-bounded** — one new provider module, one config section, ~300 lines of production code.
4. It can be **feature-flagged and optional** — zero impact on existing investigations when disabled.

The integration is *conditional* because:
- Sec-Gemini is in **trusted tester** phase — not GA. API stability and pricing are not guaranteed.
- Sessions are **ephemeral** (7-day data expiry) — SSI must extract and persist all results locally.
- Latency is **non-deterministic** — the agent runs autonomously and may take 30s–5min per prompt.

---

## 1. What is Sec-Gemini?

### 1.1 Core Capabilities

Sec-Gemini is a **security AI meta-harness** that:
- Orchestrates multiple security tools autonomously (DNS, WHOIS, SSL, HTTP headers, vulnerability lookup, email security checks)
- Uses Google's near-real-time threat intelligence data
- Supports custom tools via BYOT (Bring Your Own Tools) using the MCP protocol
- Accepts custom "skills" (markdown instructions) to define analysis workflows
- Provides an asyncio Python SDK (`sec-gemini`) for programmatic access

### 1.2 Architecture

```
Client (SDK) → Firestore (state) → Job Dispatcher → Cloud Tasks → Job Worker (Cloud Run)
```

- **Execution model**: Prompt → server-side agent execution → stream results back
- **Data handling**: Ephemeral (Firestore cache, 7-day auto-expiry, encrypted at rest)
- **Auth**: API key from `secgemini.google/keys`
- **Privacy**: Supports logging suppression (`--disable-logging` / `never_log` entitlement)

### 1.3 Available Tools (Built-in)

| Category | Tools | SSI Overlap |
|----------|-------|-------------|
| Network | `dns_lookup`, `whois_lookup`, `ssl_check`, `check_email_security`, `http_headers`, `fetch_http`, `tcp_port_check`, `ping`, `traceroute` | **High** — SSI has DNS, WHOIS, SSL already |
| Vulnerability | `lookup_vulnerability` | **None** — SSI doesn't have this |
| File/Shell | `read_file`, `write_file`, `bash`, `python_exec` | N/A (BYOT only) |

### 1.4 SDK API Surface

```python
from sec_gemini import SecGemini

async with SecGemini(api_key="KEY") as client:
    session = await client.sessions.create()
    await session.prompt("Analyze the security posture of example.com")
    async for msg in session.messages.stream():
        if msg.get("message_type") == "MESSAGE_TYPE_RESPONSE":
            result = msg["content"]
    await session.delete()
```

Key characteristics:
- All methods are `async`
- `session.prompt()` is fire-and-forget; results come via `session.messages.stream()`
- Sessions persist server-side; client can disconnect and reconnect
- Files can be uploaded for context (7-day expiry)
- Custom skills (markdown) can be uploaded to guide agent behavior

---

## 2. Fit Analysis: Sec-Gemini × SSI

### 2.1 Capability Gap Matrix

| SSI Capability | Current State | Sec-Gemini Adds | Value |
|----------------|---------------|-----------------|-------|
| WHOIS/RDAP | ✅ Native (`whois_lookup.py`) | Redundant | None |
| DNS resolution | ✅ Native (`dns_lookup.py`) | Redundant | None |
| SSL inspection | ✅ Native (`ssl_inspect.py`) | Redundant | None |
| GeoIP | ✅ Native (`geoip_lookup.py`) | Redundant | None |
| VirusTotal | ✅ Native (`virustotal.py`) | Redundant | None |
| urlscan.io | ✅ Native (`urlscan.py`) | Redundant | None |
| CT Log lookup | ✅ Native (`ctlog_lookup.py`) | Redundant | None |
| Email security posture | ❌ Not implemented | SPF/DKIM/DMARC/MX analysis | **High** |
| Vulnerability correlation | ❌ Not implemented | CVE lookup + exploit status | **High** |
| Infrastructure fingerprinting | ⚠️ Partial (HTTP headers in HAR) | AI-reasoned tech stack ID | **Medium** |
| Threat intel synthesis | ⚠️ Basic (classification only) | AI-reasoned cross-correlation | **Medium** |
| Browser automation | ✅ Native (zendriver + Playwright) | Not applicable | None |
| Wallet extraction | ✅ Native | Not applicable | None |
| Google OSINT | ✅ Native (People, Maps) | Not applicable | None |

### 2.2 Where Sec-Gemini Complements SSI

**High-value additions** (SSI cannot do these today):

1. **Email security posture analysis** — When SSI finds email addresses on scam sites (admin contacts, registration forms), Sec-Gemini can analyze the sending domain's SPF, DKIM, DMARC, and MX configuration. This reveals whether the scam operation uses properly configured email infrastructure (sophisticated) or throwaway domains (commodity scam).

2. **Vulnerability correlation** — When SSI identifies the tech stack of a scam site (via HTTP headers, server fingerprints), Sec-Gemini can look up known CVEs and determine if the site is running on vulnerable infrastructure. This enriches the threat assessment.

3. **AI-reasoned threat synthesis** — Sec-Gemini can take SSI's raw OSINT data (WHOIS, DNS, SSL, threat indicators) and produce a synthesis report with reasoning that goes beyond SSI's rule-based classification. This is essentially a "second opinion" from Google's security AI.

**Not applicable / no value:**

- Browser automation — Sec-Gemini has no browser. SSI's zendriver+Playwright setup is purpose-built and cannot be replaced.
- Wallet extraction — Sec-Gemini has no crypto capabilities.
- Active site interaction — Sec-Gemini is a recon/analysis tool, not an interaction agent.

### 2.3 Where Sec-Gemini Does NOT Fit

| SSI Requirement | Sec-Gemini Limitation |
|-----------------|----------------------|
| Deterministic, repeatable results | Agent output varies per run |
| Sub-second latency per OSINT call | 30s–5min per session (agent-driven) |
| Offline/local-first operation | Cloud-only (requires internet + API key) |
| Evidence chain-of-custody (SHA-256) | Ephemeral 7-day storage, no provenance chain |
| Budget control (<$0.01/investigation) | Pricing unknown (trusted tester phase) |
| 599 tests with deterministic assertions | Non-deterministic agent output |

---

## 3. Integration Architecture

### 3.1 Design Principle: Optional Enrichment Provider

Sec-Gemini is integrated as a **new enrichment provider** in SSI's Phase 1 pipeline, alongside the existing OSINT modules. It is:
- **Feature-flagged** via `SSI_SEC_GEMINI__ENABLED` (default: `false`)
- **Non-blocking** — failure does not abort the investigation
- **Additive** — results are merged into `InvestigationResult.threat_indicators` and a new `sec_gemini_analysis` field
- **Budget-gated** — respects `CostTracker` budget enforcement

### 3.2 Architecture Diagram

```
Orchestrator (run_investigation)
  │
  ├── Phase 1: Passive Recon
  │     ├── _run_whois()          ← existing
  │     ├── _run_dns()            ← existing
  │     ├── _run_ssl()            ← existing
  │     ├── _run_geoip()          ← existing
  │     ├── _run_virustotal()     ← existing
  │     ├── _run_urlscan()        ← existing
  │     ├── _run_ecx_enrichment() ← existing
  │     └── _run_sec_gemini()     ← NEW (optional, feature-flagged)
  │           │
  │           ├── SecGeminiProvider.analyze_domain()
  │           │     → email security, vuln correlation, infra fingerprint
  │           ├── SecGeminiProvider.synthesize_threat_intel()
  │           │     → AI-reasoned summary from SSI's raw OSINT data
  │           └── Results → InvestigationResult
  │                 ├── .threat_indicators (appended)
  │                 └── .sec_gemini_analysis (new field)
  │
  ├── Phase 2: Active Interaction  ← unchanged
  └── Phase 3: Classification      ← unchanged (can use sec_gemini data)
```

### 3.3 Module Structure

```
ssi/src/ssi/
  └── providers/
      └── sec_gemini/
          ├── __init__.py
          ├── provider.py      # SecGeminiProvider class
          ├── prompts.py        # Investigation prompt templates
          ├── parser.py         # Parse agent response → structured models
          ├── models.py         # SecGeminiAnalysis Pydantic model
          └── skills/
              └── ssi_investigation.md  # Custom skill for SSI workflow
```

### 3.4 Provider Implementation

```python
# ssi/src/ssi/providers/sec_gemini/provider.py

class SecGeminiProvider:
    """Optional enrichment provider using Google's Sec-Gemini SDK."""

    def __init__(self, api_key: str, timeout_seconds: int = 180):
        self._api_key = api_key
        self._timeout = timeout_seconds

    async def analyze_domain(self, url: str, existing_osint: dict) -> SecGeminiAnalysis:
        """Run domain security analysis via Sec-Gemini.

        Prompts the agent to:
        1. Analyze email security posture (SPF/DKIM/DMARC)
        2. Fingerprint infrastructure and check for known CVEs
        3. Cross-correlate with threat intelligence

        Args:
            url: Target URL being investigated.
            existing_osint: Dict of SSI's existing OSINT results (WHOIS, DNS, SSL)
                to avoid redundant lookups and provide context.

        Returns:
            Structured analysis result.
        """
        async with SecGemini(api_key=self._api_key) as client:
            session = await client.sessions.create()
            try:
                # Upload SSI's existing OSINT as context
                context_json = json.dumps(existing_osint, indent=2)
                await session.files.upload_content(
                    "ssi_osint_context.json", context_json
                )

                # Send focused analysis prompt
                prompt = build_investigation_prompt(url, existing_osint)
                await session.prompt(prompt)

                # Stream and collect results with timeout
                return await self._collect_results(session)
            finally:
                await session.delete()

    async def _collect_results(self, session) -> SecGeminiAnalysis:
        """Stream agent messages and parse final response."""
        responses = []
        async for msg in session.messages.stream():
            msg_type = msg.get("message_type", "")
            if msg_type == "MESSAGE_TYPE_RESPONSE":
                responses.append(msg.get("content", ""))
            elif msg_type == "MESSAGE_TYPE_AGENT_IS_DONE":
                break

        combined = "\n".join(responses)
        return parse_sec_gemini_response(combined)
```

### 3.5 Orchestrator Integration

```python
# In orchestrator.py, add after _run_ecx_enrichment():

def _run_sec_gemini(url: str, result: InvestigationResult) -> None:
    """Optional Sec-Gemini enrichment (feature-flagged)."""
    from ssi.settings import get_settings
    settings = get_settings()

    if not settings.sec_gemini.enabled:
        return

    from ssi.providers.sec_gemini.provider import SecGeminiProvider

    try:
        provider = SecGeminiProvider(
            api_key=settings.sec_gemini.api_key,
            timeout_seconds=settings.sec_gemini.timeout_seconds,
        )

        # Build context from existing OSINT results
        existing_osint = _build_osint_context(result)

        # Run async provider
        import asyncio
        analysis = asyncio.run(provider.analyze_domain(url, existing_osint))

        # Merge results
        result.threat_indicators.extend(analysis.threat_indicators)
        result.sec_gemini_analysis = analysis.model_dump(mode="json")

        logger.info(
            "Sec-Gemini enrichment: %d indicators, risk_delta=%.1f",
            len(analysis.threat_indicators),
            analysis.risk_adjustment,
        )
    except Exception as e:
        logger.warning("Sec-Gemini enrichment failed (non-fatal): %s", type(e).__name__)
```

### 3.6 Configuration

```toml
# config/settings.default.toml

[sec_gemini]
enabled = false                    # Feature flag — off by default
api_key = ""                       # From secgemini.google/keys
timeout_seconds = 180              # Max wait for agent completion
enable_email_security = true       # Analyze email posture
enable_vuln_correlation = true     # CVE/exploit lookup
enable_threat_synthesis = true     # AI-reasoned summary
```

Environment variable overrides:
```
SSI_SEC_GEMINI__ENABLED=true
SSI_SEC_GEMINI__API_KEY=<key>
SSI_SEC_GEMINI__TIMEOUT_SECONDS=180
```

### 3.7 Data Model

```python
# ssi/src/ssi/providers/sec_gemini/models.py

class EmailSecurityPosture(BaseModel):
    """SPF/DKIM/DMARC analysis for a domain."""
    domain: str
    spf_record: str | None = None
    spf_valid: bool = False
    dkim_configured: bool = False
    dmarc_record: str | None = None
    dmarc_policy: str | None = None  # none | quarantine | reject
    mx_records: list[str] = []
    assessment: str = ""  # Human-readable summary

class InfraFingerprint(BaseModel):
    """Technology stack identification."""
    web_server: str | None = None
    framework: str | None = None
    cms: str | None = None
    hosting_provider: str | None = None
    cdn: str | None = None
    cves: list[str] = []  # Related CVEs

class SecGeminiAnalysis(BaseModel):
    """Structured output from Sec-Gemini enrichment."""
    email_security: list[EmailSecurityPosture] = []
    infrastructure: InfraFingerprint | None = None
    threat_synthesis: str = ""  # AI-reasoned summary
    threat_indicators: list[ThreatIndicator] = []
    risk_adjustment: float = 0.0  # -10 to +10 delta to apply to risk score
    raw_agent_response: str = ""  # Full response for audit
    session_id: str = ""
    duration_seconds: float = 0.0
```

### 3.8 Custom Skill for SSI

Upload a custom skill to Sec-Gemini that focuses the agent on SSI-relevant analysis:

```markdown
---
name: ssi-domain-investigation
description: Focused domain security analysis for scam site investigation
---

## Instructions

You are assisting a scam site investigation system. Given a URL and existing
OSINT data (WHOIS, DNS, SSL, GeoIP), perform the following targeted analyses:

1. **Email Security Posture**: For all email domains found in the WHOIS
   registrant contact and the page content, use `check_email_security` to
   analyze SPF, DKIM, DMARC, and MX configuration.

2. **Infrastructure Fingerprinting**: Use `http_headers` and `fetch_http`
   to identify the web server, framework, CMS, and hosting provider. Check
   for known CVEs using `lookup_vulnerability`.

3. **Do NOT repeat** DNS, WHOIS, or SSL lookups — these are provided in the
   attached context file.

## Output Format

Return a JSON object with this structure:
{
  "email_security": [...],
  "infrastructure": {...},
  "threat_synthesis": "...",
  "risk_adjustment": 0,
  "cves": [...]
}
```

---

## 4. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Sec-Gemini exits trusted tester / API changes | High | Feature flag + provider abstraction. If API breaks, disable flag — zero impact. |
| Non-deterministic output breaks tests | Medium | Parse responses into structured models with fallback defaults. Unit tests mock the provider. Integration tests use recorded fixtures. |
| Latency spikes (agent takes >3min) | Medium | Configurable timeout (`timeout_seconds`). Orchestrator continues if Sec-Gemini times out. |
| Cost unknown / budget exceeded | Medium | Track as `cost_tracker.record_api_call("sec_gemini")` with conservative estimate. Budget gate runs before Sec-Gemini call. |
| Data sovereignty (OSINT data sent to Google) | Low | Already using Vertex AI Gemini for LLM. Sec-Gemini has encryption at rest, 7-day expiry, logging suppression. Use `--disable-logging` for sensitive cases. |
| Dependency on external cloud service | Low | Feature-flagged. SSI works perfectly without it. |

---

## 5. Effort Estimate

| Task | Estimate | Owner |
|------|----------|-------|
| `SecGeminiProvider` + models + parser | 3 days | Backend |
| Orchestrator integration + config | 1 day | Backend |
| Custom SSI skill authoring + testing | 1 day | Backend |
| Unit tests (mocked provider) | 1 day | Backend |
| Integration tests (recorded fixtures) | 1 day | Backend |
| Settings schema + env var docs | 0.5 day | Backend |
| Secret Manager setup (API key) | 0.5 day | Infra |
| Report template updates (new section) | 1 day | Backend |
| **Total** | **~9 days** | |

### Dependencies

- Sec-Gemini API key (request from `secgemini.google/keys`)
- `sec-gemini` PyPI package added to `pyproject.toml`

---

## 6. Success Criteria

| Metric | Target |
|--------|--------|
| Integration does not slow existing pipeline | +0s when disabled; <60s added when enabled |
| No existing tests break | All 599 tests pass with feature flag off |
| New provider has ≥90% unit test coverage | Mocked provider tests |
| Feature flag works correctly | `SSI_SEC_GEMINI__ENABLED=false` → zero Sec-Gemini calls |
| Email security analysis adds value | ≥1 new indicator per investigation with email domains |
| Graceful degradation | Sec-Gemini failure → warning log, investigation continues |

---

## 7. Go/No-Go Decision Framework

### GO if:

- [x] SDK is asyncio Python — fits SSI stack ✅
- [x] Integration is optional/feature-flagged — no risk to existing pipeline ✅
- [x] Fills genuine capability gap (email security, vuln correlation) ✅
- [x] Effort is bounded (~9 days) ✅
- [x] Architecture is clean (one new provider module) ✅

### NO-GO if:

- [ ] Sec-Gemini requires GA pricing commitment before integration ❓
- [ ] API key provisioning is blocked (org approval required) ❓
- [ ] Data sovereignty review rejects sending OSINT to Google Cloud ❓

### Recommendation

**CONDITIONAL GO** — Proceed with implementation contingent on:
1. Obtaining a Sec-Gemini API key (verify org eligibility)
2. Confirming no data sovereignty blockers (we already send data to Vertex AI)
3. Accepting that this is a trusted-tester integration that may need adjustment at GA

---

## 8. Implementation Phases

### Phase 1: Foundation (Days 1–4)
- Add `sec-gemini` to `pyproject.toml` optional dependencies
- Implement `SecGeminiProvider`, `models.py`, `parser.py`
- Add `[sec_gemini]` config section to settings
- Store API key in Secret Manager
- Write unit tests with mocked SDK

### Phase 2: Integration (Days 5–7)
- Add `_run_sec_gemini()` to orchestrator
- Author and upload custom SSI skill
- Wire results into `InvestigationResult`
- Update report templates to include Sec-Gemini section
- Integration tests with recorded fixtures

### Phase 3: Validation (Days 8–9)
- Run against 10 known scam sites with Sec-Gemini enabled
- Compare output quality vs. Sec-Gemini disabled
- Document value-add and latency impact
- Update `docs/tdd.md` with new provider section

---

## 9. Appendix: Key Sec-Gemini SDK References

| Resource | URL |
|----------|-----|
| Overview | https://docs.secgemini.google/docs/overview/ |
| Architecture & Security | https://docs.secgemini.google/docs/architecture-and-security/ |
| Python SDK Guide | https://docs.secgemini.google/docs/python-sdk/ |
| SDK API Reference | https://docs.secgemini.google/docs/reference/sdk/ |
| BYOT (Bring Your Own Tools) | https://docs.secgemini.google/docs/byot/ |
| Skills Guide | https://docs.secgemini.google/docs/skills/ |
| GitHub | https://github.com/pss-security-research/sec-gemini-mark3 |

---

## 10. Appendix: SSI Investigation Pipeline Reference

The SSI pipeline is a three-phase system (see `ssi/docs/tdd.md` §6):

- **Phase 1 — Passive Recon**: WHOIS, DNS, SSL, GeoIP, VirusTotal, urlscan, eCrimeX, **Sec-Gemini†**
- **Phase 2 — Active Interaction**: AI agent browser automation, wallet extraction
- **Phase 2.7 — Google OSINT**: Native Google identity resolution (People API, Maps contributions) using browser session cookies
- **Phase 3 — Classification & Evidence**: Five-axis fraud taxonomy, report generation, STIX bundle

† Sec-Gemini is feature-flagged (`SSI_SEC_GEMINI__ENABLED`, default: off).

Sec-Gemini integrates into **Phase 1 only**, as an additional enrichment source after the existing OSINT modules complete. It receives the existing OSINT results as context (to avoid redundant lookups) and returns structured analysis that merges into the standard `InvestigationResult`.

> **Note:** The Google OSINT integration (Phase 2.7) was implemented in a prior sprint
> (see `planning/tasks/google-osint-implementation.md`) and is now documented in
> `ssi/docs/tdd.md` §6.7.
