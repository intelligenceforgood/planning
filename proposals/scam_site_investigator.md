# Product Proposal: Scam Site Investigator (SSI)

> **Status**: Draft — Exploratory
> **Author**: Jerry Soung
> **Date**: February 17, 2026
> **Team**: Intelligence For Good

---

## 1. Executive Summary

**Scam Site Investigator (SSI)** is an AI-driven tool that takes a suspicious URL (from a scam text, email, or social media post) and automatically performs deep reconnaissance — extracting infrastructure intelligence, identifying the type of scam, cataloguing the PII it targets, and generating a prosecution-ready evidence package for law enforcement.

The key differentiator: SSI doesn't just _scan_ the site — it **interacts** with it using an AI agent and synthetic PII, walking through the scam funnel the way a victim would, documenting every step forensically.

---

## 2. Is This Worth Pursuing?

### The Case FOR Building This

1. **Massive unmet need.** The FTC reported $12.5B lost to fraud in 2024, up 25% year-over-year. Law enforcement is overwhelmed — most scam reports go uninvestigated because gathering evidence from scam sites is manual, dangerous, and time-consuming.

2. **Existing tools solve adjacent problems, not this one.** (See §3 below.) Current products focus on scanning/detection or brand protection for enterprises. Nobody builds prosecution-ready evidence packages from the _victim's perspective_ — walking the scam funnel end-to-end.

3. **Perfect fit for i4g's mission.** The platform already classifies fraud, processes victim-submitted content, and generates LEO reports. SSI extends the pipeline _upstream_ — from "victim tells us what happened" to "we can independently verify and document the scam site."

4. **AI makes this newly feasible.** Before LLMs, interacting with arbitrary scam sites required manual human analysts or rigid web scrapers that broke on every new layout. An AI agent with vision + DOM understanding can navigate unknown sites adaptively.

5. **LEA partnerships become much stronger.** Handing law enforcement a ZIP file containing screenshots, network traces, WHOIS records, and a synthetic identity's journey through the scam funnel is orders of magnitude more actionable than a victim's written narrative.

### Risks & Concerns

| Risk                                                    | Severity | Mitigation                                                                                   |
| ------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------- |
| Legal exposure from interacting with scam sites         | Medium   | Operate under academic research / LEA cooperation; never use real PII; consult legal counsel |
| Scam sites may serve malware to the agent               | High     | Sandboxed execution environment (Docker/gVisor); no host network access; disposable VMs      |
| AI agent may get stuck on CAPTCHAs or anti-bot measures | Medium   | Use CAPTCHA-solving services or flag for human-in-the-loop; accept incomplete traversals     |
| Cost of LLM inference per investigation                 | Medium   | Estimate and cap per-session token budgets (see §8)                                          |
| Scammers may detect synthetic data patterns             | Low      | Rotate and diversify synthetic PII; use region-appropriate data                              |
| Ethical concerns about "hacking back"                   | Medium   | SSI only observes and inputs data — it never exploits, defaces, or disrupts                  |

### Verdict

**Yes, this is worth exploring.** The combination of i4g's existing fraud taxonomy + classification pipeline, the unmet LEA evidence-gathering need, and the new feasibility from AI agents creates a compelling opportunity. A focused PoC (2–3 weeks) can validate the core interaction loop before committing to a full build.

---

## 3. Competitive Landscape

### Existing Tools (What Already Exists)

| Tool                                                | What It Does                                                                                                                                                              | What It Doesn't Do                                                                                                                 |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **urlscan.io**                                      | Scans a URL and records DOM, JS, cookies, screenshots, contacted IPs/domains. Identifies brands being impersonated. Free tier + API.                                      | Passive scan only — does not interact with forms, submit data, or walk multi-step funnels. No LEA report output.                   |
| **VirusTotal**                                      | Scans URLs/files against 70+ antivirus engines and URL reputation services.                                                                                               | Detection-focused, not investigation-focused. No site interaction. No evidence packaging.                                          |
| **Joe Sandbox**                                     | Deep malware analysis — executes files/URLs in sandboxed Windows/macOS/Linux VMs, records behavior.                                                                       | Focused on executable malware analysis. Does not navigate web-based scam funnels or generate LEA intelligence.                     |
| **ANY.RUN**                                         | Interactive malware sandbox — lets analysts manually interact with malware samples in a cloud VM.                                                                         | Manual interaction required. Not AI-driven. Not optimized for phishing/scam site walkthroughs.                                     |
| **PhishTool**                                       | Forensic analysis of phishing _emails_ — parses headers, links, attachments.                                                                                              | Email-focused, not site-focused. Does not visit or interact with the destination URL.                                              |
| **Netcraft**                                        | Enterprise-scale phishing detection + domain takedown. Includes "Marked Account Injection" — injects honeypot credentials into phishing sites to track criminal behavior. | Enterprise product ($$$). Focused on brand protection, not victim-side investigation. Takedown-oriented, not prosecution-oriented. |
| **Scamalytics**                                     | IP fraud scoring and user fraud detection for online platforms.                                                                                                           | B2B fraud prevention, not investigation tool. No site interaction.                                                                 |
| **ScamAdviser**                                     | Website trust score based on domain age, WHOIS, hosting location, etc.                                                                                                    | Surface-level reputation check. No deep investigation, no interaction, no evidence package.                                        |
| **OSINT tools** (Maltego, SpiderFoot, theHarvester) | Graph-based intelligence gathering — link domains, IPs, emails, social accounts.                                                                                          | General-purpose OSINT. Requires manual orchestration. No scam-specific workflow.                                                   |

### The Gap SSI Fills

No existing tool combines all of:

1. **Automated site interaction** via AI agent (not just passive scanning)
2. **Synthetic PII injection** to traverse multi-step scam funnels
3. **Infrastructure intelligence** (IP, DNS, hosting, geo, SSL, WHOIS)
4. **PII collection mapping** (what data the scam targets)
5. **Prosecution-ready evidence packaging** formatted for LEA consumption
6. **Integration with a fraud taxonomy** (classifying the scam type, techniques, persona)

Netcraft's "Marked Account Injection" is the closest concept — but it's a feature within an enterprise brand-protection platform, not a standalone investigation tool for LEAs or nonprofits.

---

## 4. Proposed Capabilities

### Tier 1 — Passive Reconnaissance (PoC Target)

Given a URL, automatically collect:

| Intelligence                       | Method                                                               | Tools/APIs                      |
| ---------------------------------- | -------------------------------------------------------------------- | ------------------------------- |
| **Screenshot & page archive**      | Headless browser capture (full page + above-fold)                    | Playwright / Puppeteer          |
| **DOM snapshot**                   | Serialize full DOM including hidden fields, forms                    | Playwright                      |
| **SSL certificate details**        | TLS handshake inspection                                             | Python `ssl` / `certifi`        |
| **WHOIS / RDAP data**              | Domain registration lookup                                           | `python-whois`, RDAP API        |
| **DNS records**                    | A, AAAA, MX, TXT, NS, CNAME                                          | `dnspython`                     |
| **IP geolocation**                 | GeoIP lookup of hosting IP                                           | MaxMind GeoLite2, ipinfo.io     |
| **ASN & hosting provider**         | IP-to-ASN mapping                                                    | Team Cymru, ipinfo.io           |
| **HTTP headers & redirects**       | Full redirect chain with headers                                     | `httpx` / `requests`            |
| **Technology fingerprint**         | Detect CMS, frameworks, analytics                                    | Wappalyzer / `builtwith`        |
| **Linked domains & resources**     | All external resources loaded by the page                            | Playwright network interception |
| **Form field inventory**           | Enumerate all `<input>`, `<select>`, `<textarea>` fields with labels | DOM parsing                     |
| **Identified brand impersonation** | Logo/favicon matching, title/meta analysis                           | Perceptual hashing + LLM        |
| **Malware/exploit detection**      | Check URL + any downloads against threat intel                       | VirusTotal API, urlscan.io API  |

### Tier 2 — Active Interaction (AI Agent)

An LLM-powered agent navigates the scam site interactively:

| Capability                             | Description                                                                                                              |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Form completion with synthetic PII** | Agent fills in forms using data from the Synthetic Identity Vault (§5). Submits and records what happens next.           |
| **Multi-step funnel traversal**        | Follows the scam through multiple pages — login → dashboard → payment → confirmation. Records each step.                 |
| **Decision-point reasoning**           | When the site presents choices (e.g., "select your bank"), the agent reasons about which path to explore and can branch. |
| **Download interception**              | If the site offers a file for download, capture it without executing. Submit to sandbox for analysis.                    |
| **Credential phishing detection**      | Identifies when the site is asking for credentials and which institution it impersonates.                                |
| **Payment page analysis**              | Detects payment forms, cryptocurrency addresses, money transfer instructions. Records destination details.               |
| **Session recording**                  | Full HAR (HTTP Archive) + video recording of the agent's browser session.                                                |
| **Anti-detection evasion**             | Randomized user-agent, realistic mouse movements, typing delays, residential proxy rotation.                             |

### Tier 3 — Intelligence Synthesis & Reporting

| Output                       | Format                                                                     | Consumer                          |
| ---------------------------- | -------------------------------------------------------------------------- | --------------------------------- |
| **Scam classification**      | i4g fraud taxonomy labels (intent, channel, technique, action, persona)    | i4g platform                      |
| **Infrastructure dossier**   | Structured JSON + human-readable summary                                   | Analyst / LEA                     |
| **PII collection map**       | Table of what PII the scam collects, at which step, with field labels      | LEA report appendix               |
| **Evidence package**         | ZIP containing screenshots, HAR, DOM snapshots, WHOIS, network logs, video | LEA submission                    |
| **Threat indicators (IOCs)** | IP addresses, domains, email addresses, crypto wallets, phone numbers      | Threat intel sharing (STIX/TAXII) |
| **Similarity report**        | Links to known scam campaigns using same infrastructure/kit                | i4g intelligence graph            |

---

## 5. Synthetic Identity Vault

A repository of **realistic but entirely fake** PII data used by the AI agent to interact with scam sites. This is critical — without it, the agent cannot proceed past the first form.

### Data Categories

| Category                   | Examples                   | Generation Method                                  |
| -------------------------- | -------------------------- | -------------------------------------------------- |
| **Names**                  | First, last, middle        | Faker library, culturally diverse                  |
| **Addresses**              | Street, city, state, ZIP   | Valid formats per region, non-real addresses       |
| **Phone numbers**          | Mobile, landline           | Valid format, non-allocated ranges                 |
| **Email addresses**        | Personal, work             | Controlled domains we own (e.g., `@i4g-probe.net`) |
| **SSN / Tax ID**           | Format-valid               | Invalid checksum digits (cannot match real people) |
| **Bank account / routing** | Format-valid               | Test ranges from banking standards                 |
| **Credit card numbers**    | Format-valid               | Luhn-valid but from designated test BINs           |
| **Date of birth**          | Realistic range            | Random within plausible bounds                     |
| **Government ID**          | Driver's license, passport | Valid format, clearly synthetic serial ranges      |
| **Login credentials**      | Username + password        | Unique per session, tracked for reuse detection    |

### Design Principles

- **Never endanger real people.** All synthetic data must be provably non-real. Use invalid SSN ranges (900–999), test credit card BINs (4111-xxxx), etc.
- **Region-appropriate.** Generate data matching the target region of the scam (US, UK, AU, etc.).
- **Consistent identities.** A single synthetic persona should be internally consistent (address matches stated city, area code matches region, etc.).
- **Trackable.** Every synthetic identity gets a UUID. If it appears in breach databases later, we know the scam site sold or shared the data.
- **Rotatable.** Generate fresh identities for each investigation to prevent pattern detection.

---

## 6. Technical Architecture

### High-Level Flow

```
┌─────────────┐     ┌──────────────────┐     ┌───────────────────┐
│ Analyst UI  │────▶│ SSI Orchestrator │────▶│ Sandboxed Browser │
│ (or API)    │     │ (FastAPI)        │     │ (Playwright in    │
└─────────────┘     └──────┬───────────┘     │  gVisor/Docker)   │
                           │                 └────────┬──────────┘
                           │                          │
                    ┌──────▼───────────┐       ┌──────▼──────────┐
                    │ AI Agent         │       │ Network Monitor │
                    │ (Ollama / Gemini)│       │ (mitmproxy)     │
                    └──────┬───────────┘       └──────┬──────────┘
                           │                          │
                    ┌──────▼───────────┐       ┌──────▼──────────┐
                    │ Synthetic PII    │       │ OSINT Enrichment│
                    │ Vault            │       │ (WHOIS, GeoIP,  │
                    └──────────────────┘       │  DNS, VT, etc.) │
                                               └──────┬──────────┘
                                                      │
                                               ┌──────▼──────────┐
                                               │ Evidence Store  │
                                               │ + Report Gen    │
                                               └─────────────────┘
```

### Component Stack

| Component                | PoC (Local)                   | Production (GCP)                     |
| ------------------------ | ----------------------------- | ------------------------------------ |
| **LLM**                  | Ollama (Llama 3 / Mistral)    | Vertex AI Gemini 2.0 Flash           |
| **Browser automation**   | Playwright (local Docker)     | Playwright in Cloud Run Job (gVisor) |
| **Network interception** | mitmproxy                     | mitmproxy in sidecar container       |
| **OSINT APIs**           | Free tiers (ipinfo, RDAP, VT) | Paid API keys in Secret Manager      |
| **Synthetic PII**        | Faker + local SQLite          | Faker + Cloud SQL                    |
| **Evidence storage**     | Local filesystem (`data/`)    | Cloud Storage bucket                 |
| **Orchestrator API**     | FastAPI (local uvicorn)       | Cloud Run service                    |
| **Report generation**    | Existing i4g report pipeline  | Same                                 |
| **Malware sandbox**      | Docker-in-Docker (limited)    | Cloud Run Job with gVisor isolation  |

### Integration with i4g Core

SSI extends the existing platform rather than replacing it:

- **Fraud Taxonomy** — SSI's classification output feeds directly into the five-axis taxonomy (intent, channel, technique, action, persona).
- **Evidence Store** — SSI evidence packages attach to existing case records via the evidence attachment system.
- **LEO Reports** — SSI intelligence enriches the existing dossier/LEO report pipeline with infrastructure evidence.
- **Ingestion** — A scam URL submitted by a victim can automatically trigger an SSI investigation via the existing worker/jobs pipeline.

---

## 7. Executable / Malware Analysis

When the scam link points to a downloadable file rather than a webpage:

### Detection

1. Follow the URL, inspect `Content-Type` and `Content-Disposition` headers.
2. If the response is a binary/executable (`.exe`, `.apk`, `.dmg`, `.msi`, `.js`, `.ps1`, `.bat`, etc.), download to an isolated filesystem.
3. Do NOT execute locally.

### Analysis Pipeline

| Step | Action                                          | Tool                                            |
| ---- | ----------------------------------------------- | ----------------------------------------------- |
| 1    | File hash (MD5, SHA-256)                        | `hashlib`                                       |
| 2    | Check hash against known malware databases      | VirusTotal API                                  |
| 3    | Static analysis — strings, imports, metadata    | `strings`, `pefile`, `androguard`               |
| 4    | Behavioral analysis in sandbox                  | Joe Sandbox API (Cloud) or local Docker sandbox |
| 5    | Identify exploit kit / malware family           | VirusTotal + YARA rules                         |
| 6    | Extract C2 (command & control) server addresses | Static analysis + sandbox network capture       |
| 7    | Package findings into evidence report           | SSI report generator                            |

### Scope Boundary

SSI aims to **identify and classify** malware, not to build a full malware reverse-engineering capability. For deep reversing, the tool outputs IOCs and defers to dedicated platforms (Joe Sandbox, ANY.RUN, or a partner lab).

---

## 8. Cost Estimation

### Per-Investigation Costs

| Cost Component                                                                          | PoC (Ollama, local) | Production (GCP)                                                |
| --------------------------------------------------------------------------------------- | ------------------- | --------------------------------------------------------------- |
| **LLM inference** (agent interaction, ~5K input + 2K output tokens per page, ~10 pages) | $0 (local model)    | ~$0.05–0.15 (Gemini 2.0 Flash: $0.10/1M input, $0.40/1M output) |
| **LLM inference** (classification + report synthesis, ~10K tokens)                      | $0                  | ~$0.01–0.03                                                     |
| **Browser sandbox** (Cloud Run Job, 2 vCPU / 4GB, ~5 min)                               | $0                  | ~$0.01–0.02                                                     |
| **OSINT API calls** (WHOIS, GeoIP, DNS, VirusTotal)                                     | $0 (free tiers)     | ~$0.01–0.05 (paid tiers for volume)                             |
| **Cloud Storage** (evidence package, ~50MB avg)                                         | $0                  | ~$0.001                                                         |
| **Total per investigation**                                                             | **$0**              | **~$0.08–0.25**                                                 |

### Monthly Operating Costs (Projected)

| Scenario                | Investigations/month | Monthly cost |
| ----------------------- | -------------------- | ------------ |
| PoC / Testing           | 50                   | $0 (local)   |
| Early production        | 500                  | ~$40–125     |
| Scale (LEA partnership) | 5,000                | ~$400–1,250  |

### Cost Comparison

For context: a human analyst manually investigating a scam site takes 30–60 minutes. At $30/hr, that's $15–30 per investigation. SSI at $0.08–0.25 per investigation is **60–375x cheaper** and produces more consistent, comprehensive evidence.

---

## 9. Implementation Phases

### Phase 0 — Research Spike (1 week)

- [ ] Stand up Playwright in Docker with network recording
- [ ] Test Ollama (Llama 3.3) as a browser interaction agent against 3–5 known scam site types
- [ ] Validate that the agent can fill forms and navigate multi-step flows
- [ ] Measure token usage and latency per interaction
- [ ] **Go/no-go decision** based on agent reliability

### Phase 1 — PoC: Passive Reconnaissance (2 weeks)

- [ ] Build the Tier 1 passive scanner (WHOIS, DNS, GeoIP, SSL, screenshots, DOM, form inventory)
- [ ] Integrate with urlscan.io and VirusTotal APIs
- [ ] Generate structured JSON + markdown report
- [ ] Wire into i4g CLI: `i4g investigate <url>`

### Phase 2 — PoC: Active Interaction Agent (3 weeks)

- [ ] Build the Synthetic Identity Vault with Faker
- [ ] Implement the AI agent loop: observe page → reason about action → act → record → repeat
- [ ] HAR recording + video capture of sessions
- [ ] Malware download interception and hash-based classification
- [ ] Run against 20+ real scam URLs across different scam types

### Phase 3 — Integration & Evidence Packaging (2 weeks)

- [ ] Wire SSI output into i4g fraud taxonomy classification
- [ ] Generate prosecution-ready evidence packages (ZIP with chain-of-custody metadata)
- [ ] Integrate with existing LEO report pipeline
- [ ] Add SSI as a Cloud Run Job triggered from API/CLI

### Phase 4 — Hardening & Scale (ongoing)

- [ ] Anti-detection improvements (proxy rotation, browser fingerprint randomization)
- [ ] CAPTCHA handling strategy (service integration or graceful degradation)
- [ ] Cost monitoring and per-session budget caps
- [ ] Feedback loop — did the evidence lead to prosecution?

---

## 10. Open Questions

1. **Legal review needed.** Is automated interaction with scam sites permissible under CFAA / CMA / local equivalents? We believe yes (no unauthorized access to legitimate systems; submitting data to a form is not "hacking"), but need legal confirmation.

2. **Partnership model.** Should SSI be a standalone tool, or always operated in coordination with an LEA? Operating under LEA partnership provides legal cover.

3. **Scope of malware analysis.** Do we build in-house sandbox capability, or integrate with Joe Sandbox / ANY.RUN APIs? API integration is cheaper and faster to build. Recommendation: API-first.

4. **Identity vault liability.** Even with synthetic data, could generated credit card numbers or SSNs create compliance issues? Recommendation: use only well-known test ranges (Stripe test cards, IRS invalid SSN ranges).

5. **Multi-language / region support.** Many scams target non-English speakers. The AI agent needs multilingual capability. Gemini supports this well; smaller local models may not.

6. **Real-time vs. batch.** Should investigation be synchronous (analyst waits) or queued (results delivered async)? Recommendation: async with progress updates, same pattern as existing i4g report generation.

---

## 11. Success Metrics

| Metric                                        | Target (6 months post-launch)         |
| --------------------------------------------- | ------------------------------------- |
| Scam sites successfully traversed end-to-end  | ≥ 70% of submitted URLs               |
| Average investigation time (vs. manual)       | < 5 min (vs. 30–60 min manual)        |
| Evidence packages accepted by LEA partners    | ≥ 3 LEA partners using outputs        |
| Unique infrastructure clusters identified     | ≥ 50 (linking related scam campaigns) |
| Cost per investigation                        | ≤ $0.25 on GCP                        |
| False positive rate (legitimate site flagged) | < 5%                                  |

---

## 12. Recommendation

**Proceed with Phase 0 (research spike).** The core technical risk is whether an LLM agent can reliably navigate diverse scam site layouts. A one-week spike using Ollama + Playwright will answer this. If the agent can complete 3 out of 5 test scam funnels, greenlight Phase 1–2.

This capability would be **unique in the nonprofit/LEA space** — no existing tool offers AI-driven scam site interaction with evidence packaging. It directly serves i4g's mission and strengthens the platform's value proposition for LEA partnerships.

---

_This document is a living proposal. Feedback from the Intelligence For Good team is requested before committing engineering resources._
