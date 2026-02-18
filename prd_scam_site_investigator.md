# Product Requirements Document: Scam Site Investigator (SSI)

> **Document Version**: 1.0
> **Last Updated**: February 18, 2026
> **Owner**: Jerry Soung
> **Status**: Prototype Complete — Local

---

## 1. Executive Summary

**Scam Site Investigator (SSI)** is an AI-driven tool that takes a suspicious URL and automatically performs deep reconnaissance — extracting infrastructure intelligence, identifying the scam type, cataloguing the PII it targets, and generating a prosecution-ready evidence package for law enforcement.

The key differentiator: SSI does not just _scan_ the site — it **interacts** with it using an AI agent and synthetic PII, walking through the scam funnel the way a victim would, documenting every step forensically.

**Current State**: Local prototype running on Ollama (Llama 3.3) + Playwright, with CLI and API interfaces. All core capabilities are implemented and ready for testing against real scam sites.

**Deployment**: Standalone Python package (`ssi`) in the `ssi/` repo within the i4g workspace. Runs locally via `ssi` CLI or FastAPI on port 8100.

---

## 2. Problem Statement

The FTC reported $12.5B lost to fraud in 2024, up 25% year-over-year. Law enforcement is overwhelmed — most scam reports go uninvestigated because gathering evidence from scam sites is manual, dangerous, and time-consuming.

**Existing tools solve adjacent problems, not this one.** urlscan.io, VirusTotal, and Joe Sandbox focus on passive scanning, malware detection, or brand protection. No tool combines automated site interaction, synthetic PII injection, infrastructure intelligence, and prosecution-ready evidence packaging in a single workflow.

**A human analyst investigating a scam site manually takes 30–60 minutes and costs $15–30.** SSI performs the same investigation in under 5 minutes at effectively $0 locally, or ~$0.08–$0.25 on GCP — a **60–375x cost reduction** with more consistent, comprehensive output.

---

## 3. Goals & Success Criteria

| Metric                                       | Target                         |
| -------------------------------------------- | ------------------------------ |
| Scam sites successfully traversed end-to-end | ≥ 70% of submitted URLs        |
| Average investigation time                   | < 5 min (vs. 30–60 min manual) |
| Evidence packages accepted by LEA partners   | ≥ 3 LEA partners using outputs |
| Unique infrastructure clusters identified    | ≥ 50 linked scam campaigns     |
| Cost per investigation (GCP)                 | ≤ $0.25                        |
| False positive rate                          | < 5%                           |

---

## 4. Competitive Landscape

| Tool                                  | What It Does                                          | Gap SSI Fills                                  |
| ------------------------------------- | ----------------------------------------------------- | ---------------------------------------------- |
| **urlscan.io**                        | Passive URL scan — DOM, JS, cookies, screenshots, IPs | No form interaction, no evidence packaging     |
| **VirusTotal**                        | URL/file reputation across 70+ AV engines             | Detection only, no investigation               |
| **Joe Sandbox**                       | Malware behavioral analysis in sandboxed VMs          | Executable-focused, not web scam funnels       |
| **ANY.RUN**                           | Interactive manual malware sandbox                    | Manual, not AI-driven, not scam-optimized      |
| **PhishTool**                         | Forensic analysis of phishing emails                  | Email-only, does not visit destination URLs    |
| **Netcraft**                          | Enterprise phishing detection + domain takedown       | Enterprise pricing, brand-protection focus     |
| **ScamAdviser**                       | Website trust score (domain age, WHOIS, etc.)         | Surface-level only, no deep investigation      |
| **OSINT tools** (Maltego, SpiderFoot) | Graph-based intelligence gathering                    | General-purpose, requires manual orchestration |

**No existing tool combines**: (1) automated AI-driven site interaction, (2) synthetic PII injection for multi-step funnel traversal, (3) infrastructure intelligence, (4) PII collection mapping, (5) prosecution-ready evidence packaging, and (6) fraud taxonomy classification.

---

## 5. Capabilities

### Tier 1 — Passive Reconnaissance

Given a URL, SSI automatically collects:

- Screenshot and full-page archive
- DOM snapshot including hidden fields and forms
- SSL certificate details (issuer, SAN, validity, fingerprint)
- WHOIS / RDAP domain registration data
- DNS records (A, AAAA, MX, TXT, NS, CNAME)
- IP geolocation and ASN / hosting provider
- HTTP headers and full redirect chain
- Technology fingerprint (CMS, frameworks, analytics)
- External resources loaded by the page
- Form field inventory (all inputs with labels)
- VirusTotal URL reputation
- urlscan.io page analysis

### Tier 2 — Active Interaction (AI Agent)

An LLM-powered agent navigates the scam site interactively:

- **Form completion with synthetic PII** — fills forms using data from the Synthetic Identity Vault, submits and records responses
- **Multi-step funnel traversal** — follows the scam through login → dashboard → payment → confirmation
- **Decision-point reasoning** — reasons about which paths to explore when the site presents choices
- **Download interception** — captures files offered for download without executing them; hashes and checks against VirusTotal
- **CAPTCHA detection** — identifies reCAPTCHA, hCaptcha, Cloudflare Turnstile, and others; applies configurable handling strategies
- **HAR recording** — captures full HTTP archive of the browser session
- **Anti-detection** — randomized user-agent, browser fingerprint, stealth scripts, proxy rotation

### Tier 3 — Intelligence Synthesis & Reporting

- **Fraud taxonomy classification** — five-axis classification (Intent, Channel, Techniques, Actions, Persona) with confidence scores and risk score (0–100)
- **Structured investigation report** — JSON + Markdown
- **Law enforcement evidence report** — prosecution-oriented summary
- **STIX 2.1 threat indicator bundle** — IOCs in standard threat intelligence format
- **Evidence ZIP** — all artifacts with SHA-256 chain-of-custody manifest
- **PII collection map** — table of what PII the scam collects, at which step, with field labels

---

## 6. Synthetic Identity Vault

A repository of realistic but entirely fake PII used by the AI agent to interact with scam sites.

| Category     | Safety Mechanism                            |
| ------------ | ------------------------------------------- |
| SSN          | 900–999 prefix range (invalid per IRS)      |
| Credit cards | Stripe test BIN (`4242424242424242`)        |
| Email        | Controlled probe domain (`@i4g-probe.net`)  |
| Addresses    | Faker-generated, valid format, non-real     |
| All fields   | Unique UUID per identity for tracking reuse |

Design principles: never endanger real people, region-appropriate generation, internally consistent identities, trackable via UUID, rotated per investigation.

---

## 7. Integration with i4g Core

SSI extends the existing i4g platform:

- **Fraud Taxonomy** — SSI classification output feeds directly into the five-axis taxonomy
- **Evidence Store** — evidence packages attach to existing case records
- **LEO Reports** — SSI intelligence enriches the existing dossier/LEO report pipeline
- **Ingestion** — a scam URL submitted by a victim can trigger an SSI investigation via the worker/jobs pipeline
- **Core Bridge** — HTTP-based integration creates cases, attaches evidence, stores taxonomy results, and triggers dossier generation

---

## 8. Cost Estimation

### Per-Investigation

| Component                  | Local (Ollama) | Production (GCP) |
| -------------------------- | -------------- | ---------------- |
| LLM inference (~50 pages)  | $0             | ~$0.05–0.15      |
| Classification + synthesis | $0             | ~$0.01–0.03      |
| Browser sandbox            | $0             | ~$0.01–0.02      |
| OSINT API calls            | $0             | ~$0.01–0.05      |
| Cloud Storage              | $0             | ~$0.001          |
| **Total**                  | **$0**         | **~$0.08–0.25**  |

### Monthly Projections

| Scenario                | Investigations/month | Cost        |
| ----------------------- | -------------------- | ----------- |
| Testing                 | 50                   | $0          |
| Early production        | 500                  | ~$40–125    |
| Scale (LEA partnership) | 5,000                | ~$400–1,250 |

---

## 9. Open Questions

1. **Legal review**: Is automated interaction with scam sites permissible under CFAA / CMA? Submitting data to a public form is not unauthorized access, but legal confirmation is needed.
2. **Partnership model**: Should SSI operate standalone or always in coordination with an LEA?
3. **Malware analysis scope**: API integration with Joe Sandbox / ANY.RUN preferred over in-house sandbox.
4. **Identity vault liability**: Even synthetic data could raise compliance questions — use only well-known test ranges.
5. **Multi-language support**: Many scams target non-English speakers. Gemini handles this well; smaller local models may not.

---

## 10. Technical References

| Document               | Location                                       |
| ---------------------- | ---------------------------------------------- |
| Architecture decisions | `ssi/docs/architecture.md`                     |
| User guide             | `ssi/docs/user_guide.md`                       |
| Developer guide        | `ssi/docs/developer_guide.md`                  |
| Next steps / roadmap   | `planning/proposals/ssi_next_steps.md`         |

---

_This PRD describes the Scam Site Investigator as delivered in the prototype phase. For the roadmap to production deployment and platform integration, see `planning/proposals/ssi_next_steps.md`._
