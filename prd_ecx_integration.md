# Product Requirements Document: eCrimeX Integration

> **Document Version**: 1.0
> **Last Updated**: March 5, 2026
> **Owner**: Jerry Soung
> **Status**: Draft — Pending Executive & Partner Approval
> **Parent Document**: `planning/prd_scam_site_investigator.md` (SSI PRD v2.0)
> **Technical Design**: `ssi/docs/tdd_ecx_integration.md`

---

## 1. Executive Summary

This document proposes integrating the Scam Site Investigator (SSI) with [eCrimeX (eCX)](https://ecrimex.net), the Anti-Phishing Working Group's (APWG) eCrime eXchange data clearinghouse. eCX is the industry's largest cooperative threat intelligence sharing platform, aggregating phishing, malware, cryptocurrency fraud, and malicious infrastructure indicators from member organizations worldwide.

**The integration is bidirectional.** SSI consumes eCX intelligence to enrich its investigations — cross-referencing URLs, domains, IPs, and wallet addresses against the community's collective database. SSI also contributes back, submitting its investigation findings (confirmed scam URLs, harvested wallet addresses, malicious domains) to eCX, amplifying the intelligence available to the entire APWG membership.

**Why this matters:** Today, SSI investigates scam sites in isolation. A URL that has already been flagged by 12 APWG members still gets a full investigation. A wallet address SSI extracts that is already linked to 50 known scams yields no additional context. eCX integration eliminates these blind spots, enriches every investigation with community intelligence, and positions IntelligenceForGood as an active contributor to the global anti-fraud ecosystem.

**Phased approach:**

| Phase | Name            | Focus                                              | Key Dependency                                |
| ----- | --------------- | -------------------------------------------------- | --------------------------------------------- |
| 1     | **Consume**     | Enrich SSI investigations with eCX data            | API access to required modules                |
| 2     | **Contribute**  | Submit SSI findings back to eCX                    | Data sharing agreement, submission governance |
| 3     | **Orchestrate** | eCX as investigation trigger, campaign correlation | Phase 1+2 stable, polling infrastructure      |

---

## 2. Problem Statement

### 2.1 Intelligence Silo

SSI currently performs each investigation in isolation. It queries VirusTotal, urlscan.io, WHOIS, DNS, and GeoIP — but these are passive reconnaissance sources. None of them provide structured, curated intelligence about known scam campaigns, previously identified criminal wallet addresses, or confirmed malicious domains from the anti-fraud community.

**Result:** SSI misses the context that a scam URL is part of a 200-site campaign already tracked by APWG members. An extracted wallet address that has stolen $2M across 50 known scams appears as "newly discovered" in SSI's report. Law enforcement receives an evidence package that is useful but lacks the cross-organizational corroboration that strengthens prosecutions.

### 2.2 One-Way Intelligence

SSI generates high-quality, structured intelligence: confirmed scam URLs, verified wallet addresses, malicious infrastructure details, and fraud classifications. Today, this intelligence benefits only i4g users. It does not flow back to the broader anti-fraud community.

**Result:** The APWG ecosystem does not benefit from SSI's automated, deep investigation capability. IntelligenceForGood is a consumer of community intelligence but not yet a contributor — limiting partnership depth.

### 2.3 Reactive-Only Workflow

SSI investigations are triggered manually (URL submission via CLI, API, or UI). There is no automated mechanism to surface new threats for investigation based on community intelligence feeds.

**Result:** New scam campaigns identified by the APWG community do not automatically trigger SSI investigations, missing early-detection opportunities.

---

## 3. eCrimeX Platform Overview

### 3.1 What eCrimeX Is

eCrimeX is the APWG's data clearinghouse for sharing cybercrime intelligence across member organizations. It provides a REST API (v1.1, OpenAPI 3.0) for programmatic access to six intelligence modules:

| Module                     | Description                               | Data Fields (Key)                                                                                        |
| -------------------------- | ----------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `phish`                    | Phishing lure URLs                        | url, brand, confidence, ip, asn, status, tld                                                             |
| `malicious-domain`         | DNS names performing malicious activities | domain, classification (scam, botnet C&C, fake store, malicious, malware, other, storefront), confidence |
| `malicious-ip`             | Malicious IP addresses                    | ip, brand, description, asn, port, confidence                                                            |
| `cryptocurrency-addresses` | Criminal wallet identifiers               | currency, address, crimeCategory, siteLink, price, procedure (manual/automatic), actorCategory, source   |
| `report-phishing`          | Real-time reportphishing@apwg.org archive | emailSubject, senderEmail, emailBody, emailHeaders (read-only)                                           |
| `malicious-sms`            | Malicious SMS/text messages               | carrier, callerIdDisplayedNumber, contentAsText, images, landingTelephoneNumber                          |

### 3.2 API Capabilities

- **Authentication**: Bearer token via `Authorization` header
- **CRUD operations**: GET (by ID, latest batch up to 10,000), POST (submit), PUT (update confidence/status)
- **Search**: POST `/search` with filters, field selection, sorting, pagination (500/page)
- **Notes**: Attach descriptive notes to `malicious-domain` and `cryptocurrency-addresses` records
- **Confidence model**: 0 (false positive), 50 (suspicious/unverified), 90 (automated detection), 100 (verified)
- **Environments**: Production (`ecrimex.net/api/v1`) and Sandbox (`sandbox.ecx2.ecrimex.net/api/v1`)

### 3.3 Data Volume

The `phish` module alone contains 112M+ records with continual high-velocity submissions. This is a rich, actively maintained intelligence source.

---

## 4. Integration Design

### 4.1 Phase 1 — Consume (Enrichment)

**Goal:** Enrich every SSI investigation with eCX community intelligence during passive reconnaissance.

#### Enrichment Points

During SSI's Phase 1 (Passive Recon), the eCX enrichment module queries relevant eCX modules and injects findings into the investigation report:

| SSI Data Point    | eCX Module Queried         | Query Strategy              | Enrichment Value                                                             |
| ----------------- | -------------------------- | --------------------------- | ---------------------------------------------------------------------------- |
| Target URL        | `phish`                    | Search by URL substring     | "This URL was submitted to eCX N times, first seen DATE, brand: X"           |
| Target domain     | `malicious-domain`         | Search by domain            | Classification (scam/botnet/malware), community confidence, submission count |
| Hosting IP(s)     | `malicious-ip`             | Search by IP                | Known malicious activity, associated brands, port intel                      |
| Extracted wallets | `cryptocurrency-addresses` | Search by address           | Crime category, associated sites, actor category, total submissions          |
| Target URL        | `report-phishing`          | Search by URL in email body | Original phishing report context, reporter information                       |

#### Output

- New section in the SSI investigation report: **"Community Intelligence (eCrimeX)"**
- Each enrichment hit includes: source module, eCX record ID, confidence, first/last seen timestamps, submission count
- Threat indicators added to the STIX 2.1 bundle with `source: "ecrimex"` attribution
- Wallet manifest enriched with eCX hit status (known/unknown to community)

#### Workflow

```
SSI Investigation Pipeline
  │
  ├─ Phase 1: Passive Recon (existing)
  │   ├─ WHOIS / DNS / SSL / GeoIP / VirusTotal / urlscan.io
  │   └─ ★ eCrimeX Enrichment (NEW)
  │       ├─ Query phish by URL
  │       ├─ Query malicious-domain by domain
  │       ├─ Query malicious-ip by hosting IPs
  │       └─ Query report-phishing by URL
  │
  ├─ Phase 2: Active Interaction (existing, unchanged)
  │   └─ ... wallet extraction ...
  │       └─ ★ eCrimeX wallet lookup (NEW, post-extraction)
  │
  └─ Phase 3: Intelligence Synthesis (existing, enriched)
      └─ Report includes eCX community intelligence section
```

### 4.2 Phase 2 — Contribute (Intelligence Sharing)

**Goal:** Submit SSI investigation findings back to eCX, contributing to the community intelligence pool.

#### Submission Targets

| SSI Finding              | eCX Module                 | Confidence Mapping                                         | Submission Trigger |
| ------------------------ | -------------------------- | ---------------------------------------------------------- | ------------------ |
| Confirmed scam URL       | `phish`                    | SSI risk_score ≥ threshold → eCX confidence 90 (automated) | Post-investigation |
| Extracted wallet address | `cryptocurrency-addresses` | All extracted wallets, procedure="automatic"               | Post-investigation |
| Confirmed scam domain    | `malicious-domain`         | SSI classification → eCX classification mapping            | Post-investigation |
| Malicious hosting IPs    | `malicious-ip`             | From passive recon, with context                           | Post-investigation |

#### Submission Governance (Hybrid Model)

The submission model balances automation with analyst oversight:

```
Investigation Complete (risk_score computed)
  │
  ├─ risk_score ≥ auto_submit_threshold (configurable, default: 80)
  │   └─ Auto-submit to eCX with confidence=90, procedure="automatic"
  │       └─ Analyst can review/retract post-submission
  │
  ├─ risk_score < auto_submit_threshold AND risk_score ≥ 50
  │   └─ Queue for analyst review
  │       └─ Analyst reviews → assigns release label → approve/reject
  │           └─ On approve → submit to eCX with confidence=90
  │
  └─ risk_score < 50
      └─ Do not submit (too low confidence)
          └─ Analyst can manually override and submit
```

**Release labels** are configurable text tags that the analyst assigns before approving submission. They serve as an audit trail and can be used for internal classification (e.g., "confirmed-scam", "investment-fraud", "pig-butchering"). The label is stored locally and attached as a note to the eCX record.

#### Deduplication

Before submitting, check if the URL/domain/address already exists in eCX:

- If exists: update confidence (PUT) if our confidence is higher, add a note with SSI investigation context
- If new: submit (POST) with full SSI attribution

#### Submission Record

Every submission is tracked locally in the `ecx_submissions` table:

- eCX record ID, module, submission timestamp, SSI case ID, analyst (if reviewed), release label, status (submitted/updated/failed/retracted)

### 4.3 Phase 3 — Orchestrate (Full Bidirectional)

**Goal:** eCX becomes an inbound intelligence source that triggers SSI investigations and enables campaign correlation.

#### Inbound Polling

A configurable polling job queries eCX at regular intervals for new submissions:

- **`phish` polling**: New phishing URLs → filter by criteria (e.g., confidence ≥ 90, specific brands, specific TLDs) → auto-submit to SSI for investigation
- **`report-phishing` polling**: New phishing reports → extract URLs from email body → submit to SSI
- **`malicious-domain` polling**: New scam-classified domains → submit for SSI investigation

Polling is opt-in, configurable by module, and rate-limited to respect eCX API quotas.

#### Campaign Correlation

Cross-reference SSI investigation results with eCX data to identify campaigns:

- Same wallet address across multiple eCX records → campaign linkage
- Same hosting IP/ASN across multiple phish records → infrastructure cluster
- Same brand impersonation pattern → coordinated phishing wave

Results feed into core's `campaigns` table for the analyst review queue.

#### Trend Dashboard

Surface eCX data in the analyst console:

- New phish submissions by brand (time series)
- Wallet address heat map (most-reported currencies)
- Geographic distribution of malicious infrastructure

---

## 5. Currency & Wallet Coverage

### 5.1 Current State

| Source               | Supported Currencies                                                                   |
| -------------------- | -------------------------------------------------------------------------------------- |
| eCX API              | ADA, BCH, BNB, BTC, DASH, DOGE, ETH, LTC, NED, TRX, XLM, XMR, XRP, XZC, ZEC (15 total) |
| SSI wallet allowlist | BNB, BTC, BCH, ADA, DASH, DOGE, ETH, LTC, MATIC, SOL, TRX, USDT (12+ networks)         |

### 5.2 Gap Analysis

- **SSI discovers but eCX does not accept**: SOL (Solana), MATIC (Polygon), USDT (Tether, multi-chain)
- **eCX accepts but SSI does not extract**: XLM (Stellar), XMR (Monero), XZC (Zcoin), ZEC (Zcash), NED

### 5.3 Design Decision

1. **SSI extraction expansion**: Add wallet regex patterns for XLM, XMR, XZC, ZEC, and any other currencies present in the eCX enum. Expand the wallet allowlist accordingly.
2. **Submission mapping**: Maintain a configurable `ecx_currency_map.json` that maps SSI `token_symbol` → eCX `currency` code. For exact matches, submit directly. For unmapped SSI currencies (e.g., future tokens), log and queue for manual review.
3. **Forward-compatible design**: When eCX expands their currency enum, a config update enables submission — no code changes needed.

---

## 6. Configuration

All eCX integration settings are configurable and scoped under the `[ecx]` section:

| Setting                     | Default                                                   | Env Var                              | Description                                                     |
| --------------------------- | --------------------------------------------------------- | ------------------------------------ | --------------------------------------------------------------- |
| `enabled`                   | `false`                                                   | `SSI_ECX__ENABLED`                   | Master toggle for eCX integration                               |
| `api_key`                   | `""`                                                      | `SSI_ECX__API_KEY`                   | eCX API bearer token                                            |
| `base_url`                  | `https://sandbox.ecx2.ecrimex.net/api/v1`                 | `SSI_ECX__BASE_URL`                  | API base URL (sandbox default, switch to production when ready) |
| `attribution`               | `IntelligenceForGood`                                     | `SSI_ECX__ATTRIBUTION`               | Organization name used in eCX submissions                       |
| `timeout_sec`               | `15`                                                      | `SSI_ECX__TIMEOUT_SEC`               | HTTP request timeout                                            |
| `enrichment_enabled`        | `true`                                                    | `SSI_ECX__ENRICHMENT_ENABLED`        | Phase 1: query eCX during investigations                        |
| `submission_enabled`        | `false`                                                   | `SSI_ECX__SUBMISSION_ENABLED`        | Phase 2: submit findings to eCX                                 |
| `auto_submit_threshold`     | `80`                                                      | `SSI_ECX__AUTO_SUBMIT_THRESHOLD`     | Minimum risk_score for auto-submission (0–100)                  |
| `submission_modules`        | `["phish","cryptocurrency-addresses","malicious-domain"]` | `SSI_ECX__SUBMISSION_MODULES`        | Which eCX modules to submit to                                  |
| `inbound_enabled`           | `false`                                                   | `SSI_ECX__INBOUND_ENABLED`           | Phase 3: poll eCX for investigation triggers                    |
| `inbound_poll_interval_min` | `15`                                                      | `SSI_ECX__INBOUND_POLL_INTERVAL_MIN` | Polling interval in minutes                                     |
| `inbound_modules`           | `["phish","report-phishing"]`                             | `SSI_ECX__INBOUND_MODULES`           | Which eCX modules to poll for inbound triggers                  |
| `currency_map_path`         | `config/ecx_currency_map.json`                            | `SSI_ECX__CURRENCY_MAP_PATH`         | Path to token symbol → eCX currency mapping                     |

---

## 7. Success Criteria

### Phase 1 — Consume

| Metric                       | Target                                                   |
| ---------------------------- | -------------------------------------------------------- |
| eCX enrichment hit rate      | ≥ 30% of investigations yield at least one eCX match     |
| Enrichment latency           | < 3 seconds per investigation (all eCX queries combined) |
| Investigation report quality | eCX section present in 100% of reports when enabled      |
| Zero-downgrade guarantee     | eCX unavailability does not block or slow investigations |

### Phase 2 — Contribute

| Metric                       | Target                                                   |
| ---------------------------- | -------------------------------------------------------- |
| Submission completeness      | ≥ 95% of high-confidence investigations submitted to eCX |
| Deduplication accuracy       | < 1% duplicate submissions                               |
| Analyst review queue latency | < 24 hours from investigation to analyst decision        |
| Submission acceptance rate   | < 5% rejection rate from eCX API                         |

### Phase 3 — Orchestrate

| Metric                             | Target                                         |
| ---------------------------------- | ---------------------------------------------- |
| Inbound investigation trigger rate | ≥ 10 auto-triggered investigations/day         |
| Campaign correlation accuracy      | ≥ 70% of linked campaigns confirmed by analyst |
| Polling reliability                | ≥ 99.5% uptime for scheduled polling           |

---

## 8. User Experience

### 8.1 Analyst Console Changes

**Investigation Detail — Recon Tab (Phase 1):**

- New "Community Intelligence" card showing eCX matches
- For each match: module, eCX record ID, confidence, first seen, submission count
- Link to eCX web interface for deep-dive (if available)

**Investigation Detail — Results Tab (Phase 2):**

- "eCX Submission" status indicator: Not submitted / Queued for review / Submitted / Failed
- For queued items: release label input field + Approve/Reject buttons
- Submission history: timestamp, eCX record ID, module, analyst who approved

**Investigation List (Phase 2):**

- Filter by eCX submission status
- Bulk approve/reject for submission queue

**New Page: eCX Intelligence Feed (Phase 3):**

- Live feed of new eCX submissions matching configured filters
- One-click "Investigate" to trigger SSI investigation from eCX record
- Campaign view linking SSI investigations to eCX records

### 8.2 CLI Changes

```
ssi ecx search <type> <query>       # Ad-hoc eCX lookup (phish/domain/ip/wallet)
ssi ecx submit <investigation-id>   # Manually submit an investigation to eCX
ssi ecx status <investigation-id>   # Check eCX submission status
ssi ecx poll                        # Manual trigger for inbound polling
```

---

## 9. Dependencies & Risks

### 9.1 Dependencies

| Dependency                                  | Status      | Owner         | Impact                                      |
| ------------------------------------------- | ----------- | ------------- | ------------------------------------------- |
| eCX API key with full module access         | Pending     | Jerry         | Blocks Phase 1 for non-phish modules        |
| Data sharing agreement with APWG            | Not started | Legal / Jerry | Blocks Phase 2 (submission)                 |
| eCX sandbox access validation               | Not started | Engineering   | Blocks development start                    |
| Wallet regex expansion (XLM, XMR, ZEC, XZC) | Not started | Engineering   | Partial block on Phase 2 crypto submissions |

### 9.2 Risks

| Risk                                          | Likelihood | Impact                        | Mitigation                                                     |
| --------------------------------------------- | ---------- | ----------------------------- | -------------------------------------------------------------- |
| eCX API rate limiting                         | Medium     | Investigation delays          | Caching layer, backoff, parallel query batching                |
| eCX API downtime                              | Low        | Lost enrichment data          | Graceful degradation (same as VT/urlscan pattern), local cache |
| Data quality concerns                         | Medium     | False positives in enrichment | Confidence threshold filtering, analyst review                 |
| Legal complications with automated submission | Medium     | Phase 2 delay                 | Secure data sharing agreement before Phase 2 launch            |
| eCX currency enum too restrictive             | Low        | Unmapped wallet submissions   | Mapping table + APWG expansion request                         |
| API key exposure                              | Low        | Security breach               | Secret Manager, env var only, never in config files            |

---

## 10. Privacy & Compliance

- **No PII in submissions**: SSI strips synthetic PII before submitting to eCX. Only infrastructure indicators (URLs, domains, IPs, wallet addresses) are shared.
- **Data sharing agreement**: Required before Phase 2. Must cover: data ownership, usage rights, retention, confidentiality, right to retract.
- **Attribution**: All submissions attributed to "IntelligenceForGood" (configurable). No individual analyst names shared with eCX.
- **Audit trail**: Every eCX interaction (query and submission) logged locally with timestamp, user, and eCX response.

---

## 11. Open Questions

1. **eCX API rate limits**: What are the per-module query/submission rate limits? Are they different for sandbox vs. production?
2. **Bulk submission API**: Does eCX support batch POST for submitting multiple records in a single request? The phish POST description suggests "one or more" — needs validation.
3. **Webhook support**: Does eCX offer webhooks for real-time notification of new submissions, as an alternative to polling in Phase 3?
4. **eCX web UI deep-links**: Can we link from the analyst console directly to an eCX record in their web interface?
5. **APWG membership tier**: Does our membership tier affect module access or rate limits?

---

## 12. Technical References

| Document               | Location                                                    |
| ---------------------- | ----------------------------------------------------------- |
| Technical design (TDD) | `ssi/docs/tdd_ecx_integration.md`                           |
| SSI PRD (parent)       | `planning/prd_scam_site_investigator.md`                    |
| SSI TDD (parent)       | `ssi/docs/tdd.md`                                           |
| eCX API specification  | `https://apwg.github.io/ecx2-openapi-doc/`                  |
| eCX OpenAPI YAML       | `https://apwg.github.io/ecx2-openapi-doc/ecx2-openapi.yaml` |
| eCX sandbox            | `https://sandbox.ecx2.ecrimex.net/api/v1`                   |
| eCX production         | `https://ecrimex.net/api/v1`                                |

---

_This PRD is an addendum to the SSI PRD v2.0. It describes a new integration work stream with its own phased milestones. For the base SSI system, see `planning/prd_scam_site_investigator.md`._
