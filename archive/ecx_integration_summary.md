# SSI–eCrimeX Integration: Summary

> **Completed**: March 7, 2026
> **Source PRD**: `planning/prd_ecx_integration.md`
> **Source TDD**: `ssi/docs/tdd_ecx_integration.md`

---

## Phase 1 — Consume (Enrichment)

**Goal:** Enrich every SSI investigation with eCX community intelligence during passive recon. SSI queries eCX for known phishing URLs, malicious domains, malicious IPs, and criminal wallet addresses — injecting community context into investigation reports and STIX bundles.

**Delivered:** `ECXClient` with search methods (phish, domain, IP, crypto, report-phishing), enrichment pipeline wired into the orchestrator's passive-recon and post-wallet-extraction phases, SQLite-backed cache with configurable TTL, "Community Intelligence (eCrimeX)" section in reports, eCX external references in STIX 2.1 indicators, CLI (`ssi ecx search …`) and API endpoints (`/ecx/search/*`, `/ecx/investigate/{scan_id}`), wallet allowlist expanded to cover XLM/XMR/XZC/ZEC.

## Phase 2 — Contribute (Submission)

**Goal:** Submit SSI investigation findings (scam URLs, wallet addresses, malicious domains, malicious IPs) back to eCX with hybrid governance — auto-submit for high-confidence, analyst review queue for medium-confidence.

**Delivered:** `ECXClient` submit/update/add-note methods, `ecx_submissions` table with Alembic migration, `ECXSubmissionService` with threshold-based governance (auto-submit / queue / skip), deduplication against existing eCX records, analyst approve/reject/retract flows, field mapping via `ecx_currency_map.json`, post-investigation pipeline integration (non-blocking), CLI (`ssi ecx submit/status/retract/submissions`), API endpoints (`/ecx/submissions/*`), UI analyst console with submission status indicators, bulk approve/reject queue page, and sidebar navigation.

## Phase 3 — Orchestrate (Full Bidirectional)

**Goal:** eCX becomes an inbound intelligence source that triggers SSI investigations automatically. Campaign correlation links SSI investigations to eCX records for cross-organizational threat intelligence.

**Delivered:** `ECXPoller` service with per-module `last_polled_id` state tracking (Alembic migration), configurable filtering (confidence, brand, TLD), deduplication against existing investigations, Cloud Run Job + Cloud Scheduler Terraform resources, CLI (`ssi ecx poll`), campaign correlation engine (wallet-based linkage, IP/ASN clustering, brand impersonation detection) feeding core's `campaigns` table, UI intelligence feed with one-click investigate, campaign timeline view, and trend dashboard (phish-by-brand time series, wallet heat map, geographic distribution).

---

## Outstanding Non-Development Items

- **APWG data sharing agreement** — Required before Phase 2 submissions flow to production eCX. Development validated against sandbox.
- **Cloud Run Job validation in `i4g-dev`** — Terraform and job definitions are in place; deployment validation deferred until the module is prioritized for production.

## Advisory for Future Work

If this track is resumed:

1. **Production activation path:** Secure the APWG data sharing agreement, deploy the poller Cloud Run Job to `i4g-dev`, validate the full bidirectional loop (poll → investigate → submit) end-to-end, then promote to `i4g-prod`.
2. **Rate limiting & quotas:** The eCX API has per-module rate limits. The current `@with_retries` decorator handles 429s with exponential backoff, but sustained high-volume polling may require request budgeting or a token-bucket strategy.
3. **Redis migration:** The poller's polling state and submission queue currently use SQLite. When core migrates to Redis-backed task tracking, consider moving eCX polling state there for consistency.
4. **Module access:** eCX modules beyond phish (malicious-domain, malicious-ip, cryptocurrency-addresses) require separate access grants from APWG. The client degrades gracefully (skip on 403), so new modules can be enabled by configuration alone.
5. **Campaign correlation maturity:** The current correlation engine uses heuristic-based linkage. A future iteration could layer ML-based clustering over the wallet/IP/brand signals for higher-fidelity campaign detection.
