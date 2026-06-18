# PhishDestroy Integration — Product Requirements Document

**Status:** Draft</br>
**Created:** 2026-04-23</br>
**Team:** TBD (Core Backend + SSI + UI)</br>
**Source material:** `github.com/phishdestroy/*` — `ScamIntelLogs`, `DestroyScammers`, `merklemap-cli`, `destroylist`</br>
**Related:** [prd_scam_site_investigator.md](prd_scam_site_investigator.md), [prd_threat_intelligence_analytics.md](prd_threat_intelligence_analytics.md), [prd_fraud_taxonomy.md](prd_fraud_taxonomy.md)

---

## 1. Purpose & Goals

### 1.1 Purpose

Integrate the PhishDestroy body of work — a multi-year, high-signal scam intelligence program — into the I4G Platform as an **upstream data source and tooling baseline**, without forking or rewriting his repos.

The outcome:
- I4G can ingest his archive, reproduce his OSINT toolchain natively inside SSI
- Surface his actor-centric intelligence model to analysts, and
- Consume his real-time phishing-domain discovery feed for automatic triage

### 1.2 Goals

1. Record threat intelligence at the **actor + operator + persona** granularity he operates at, not just cases and indicators.
2. Bring his OSINT toolchain into SSI as first-class modules so our passive scan has parity with his coverage.
3. Turn his [merklemap](https://www.merklemap.com/) CT-log `tail` into a live discovery feed that auto-enqueues SSI passive investigations.
4. Ingest the `ScamIntelLogs` archive (per-team `iocs.json`, chats, wallets, payments) via an additive schema.
5. Give analysts an **actor-centric** view on the UI (beyond the existing case-centric view).

### 1.3 Non-Goals

- Forking, mirroring, or rewriting his repos. He remains the upstream author.
- Building our own Telegram-chat collection infrastructure. We ingest what he publishes.
- Recovery/takedown service offerings.
- Changing any existing `cases`, `entities`, or `indicators` semantics. All schema changes are **additive**.

### 1.4 Collaboration Model (assumed)

His repos stay upstream. I4G is a consumer that ingests + enriches. Interfaces are defined so that, if he later agrees, we can pipe enriched records or takedown status back — but no two-way integration is built in v1.

---

## 2. Design Principles

1. **Additive schema only.** New tables for new concepts; never mutate existing `cases` / `entities` / `indicators` column semantics.
2. **Adapter at the edge.** One ingestion adapter parses his formats (`iocs.json`, Telegram exports, `data/data.json`, `data/registrants.json`) and hydrates the internal schema. The rest of I4G is format-agnostic.
3. **OSINT modules match SSI conventions.** Each new module implements the same `scan(...)` contract as `ssi/osint/{dns_lookup,urlscan,virustotal}.py`. No special cases.
4. **Immutable evidence.** Chats, screenshots, panel source maps, and archive.org snapshots are evidence blobs — stored via the existing `storage/evidence.py` pathway and signed into dossiers.
5. **Legal posture: RBAC + audit.** PII (operator real names, victim statements, chat transcripts) is ingested but gated behind role-scoped read APIs and fully audit-logged via the existing `audit_log` table.
6. **Upstream tracking.** Every row ingested from a PhishDestroy source carries a `source_provenance` JSON (`{source: "scamintellogs", team: "...", commit_sha: "...", ingested_at: "..."}`) so we can re-sync.

---

## 3. Current State & Gaps

### 3.1 What he has that we don't

| Capability                                                                                                                                          | Where it lives                                                    | I4G today                                                                       |
| --------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Threat-actor identity graph (Telegram handle + username history + display-name history + real-name + group co-membership edges)                     | `ScamIntelLogs/*/iocs.json`                                       | **Missing.** Entities are flat; no actor/persona abstraction.                   |
| Per-victim chat-session corpus with engagement metrics + deposit-demand flags + confirmed-send flags                                                | `ScamIntelLogs/*/chat/`, `*/user-<id>-messages.json`              | **Missing.** No chat-session evidence type.                                     |
| Financial damage ledger (claimed vs confirmed, per currency, top-cases index, on-chain verification status)                                         | `iocs.json.financial_damage`                                      | **Missing.** Amounts aren't first-class.                                        |
| Panel/infrastructure profile (tech stack, source-map exposure, auth model, CORS, API subdomain roles)                                               | `iocs.json.tech_stack` + `infrastructure`                         | Partial — `infrastructure_edges` exists but doesn't carry profile detail.       |
| Community blocklist aggregation (MetaMask, ScamSniffer, OpenPhish, SEAL, Enkrypt, destroylist, Polkadot, CryptoFirewall) with per-source provenance | `DestroyScammers/scripts/blocklist_checker.py`                    | **Missing.** SSI does not consult community blocklists.                         |
| Reverse-WHOIS pivot engine (by email, registrant name, company, phone)                                                                              | `DestroyScammers/scripts/whoxy_lookup.py`                         | **Missing.** SSI has WHOIS lookup but no reverse-pivot.                         |
| CT-log subdomain enumeration (crt.sh)                                                                                                               | `DestroyScammers/scripts/crtsh_lookup.py`                         | **Missing.**                                                                    |
| Real-time CT-log discovery stream (merklemap.com `tail`)                                                                                            | `merklemap-cli`                                                   | **Missing.**                                                                    |
| Google persona OSINT (GHunt) [DEPRECATED]                                                                                                          | `DestroyScammers/scripts/ghunt_lookup.py`                         | **Deprecated & Removed.**                                                       |
| Web-archive lookup (snapshot discovery + download)                                                                                                  | `DestroyScammers/scripts/webarchive_lookup.py`                    | **Missing.**                                                                    |
| Leak / credential records per actor (breach DB, password count)                                                                                     | `DestroyScammers/data/data.json.leak_extended`                    | **Missing.**                                                                    |
| Brand-impersonation dedup set per domain                                                                                                            | `DestroyScammers/data/data.json.blacklist[*].brand_impersonation` | Partial — classification taxonomy covers brands but not as a per-indicator set. |
| destroylist blocklist (~70k malicious domains)                                                                                                      | `github.com/phishdestroy/destroylist`                             | **Missing.** Not ingested as indicators.                                        |

### 3.2 What we have that augments his work

- Active browser-agent investigation (SSI Playwright) — he has no active recon.
- Review queue + analyst engagement model — he has no analyst workflow.
- Signed dossiers + STIX 2.1 export — he has static HTML dashboards.
- Classification / fraud taxonomy pipeline — he tags by team, not by taxonomy.
- ML infrastructure (drift, retraining) — he has none.

The collaboration is naturally complementary: **he supplies depth-of-field intel + passive toolchain + real-time feed; we supply active recon + analyst workflow + signed output + ML.**

---

## 4. Proposed Architecture

```
                 ┌─────────────────────────────────────┐
                 │   PhishDestroy upstream (GitHub)    │
                 │  ScamIntelLogs · destroylist ·      │
                 │  DestroyScammers · merklemap SaaS   │
                 └──────────┬──────────────────────────┘
                            │
         ┌──────────────────┼──────────────────────────┐
         │                  │                          │
         ▼                  ▼                          ▼
  ┌─────────────┐   ┌────────────────┐        ┌────────────────────┐
  │ phishdestroy│   │ blocklist      │        │ merklemap tail     │
  │ archive     │   │ aggregator     │        │ worker (streaming) │
  │ ingestor    │   │ (cron, 6h)     │        │ (Cloud Run job)    │
  │ (one-shot + │   │                │        │                    │
  │  re-sync)   │   │                │        │                    │
  └──────┬──────┘   └────────┬───────┘        └──────────┬─────────┘
         │                   │                           │
         │                   │                           │  (brand-regex
         │                   │                           │   + blocklist
         │                   │                           │   filter)
         ▼                   ▼                           ▼
  ┌────────────────────────────────────────────────────────────────┐
  │               i4g/core SQL schema (additive)                   │
  │  threat_actors · actor_identities · actor_identity_edges       │
  │  chat_sessions · victim_engagements · financial_damage_claims  │
  │  infrastructure_profiles · leak_records · blocklist_hits       │
  │  brand_impersonations · registrant_pivots · domain_discoveries │
  │  (+ existing cases/entities/indicators/campaigns)              │
  └──────────────────────────────┬─────────────────────────────────┘
                                 │
                    ┌────────────┼───────────────┐
                    ▼            ▼               ▼
              ┌──────────┐  ┌────────┐   ┌────────────────┐
              │ SSI      │  │ Review │   │ UI analyst     │
              │ passive  │  │ queue  │   │ console        │
              │ scan     │  │        │   │ (actor-centric │
              │ (enriched│  │        │   │  + case view)  │
              │ modules) │  │        │   │                │
              └──────────┘  └────────┘   └────────────────┘
```

### 4.1 New SSI OSINT modules (Core unchanged)

All live under `ssi/src/ssi/osint/`. Each module implements the existing scan contract.

| Module                     | Replaces script                                                        | External deps                    |
| -------------------------- | ---------------------------------------------------------------------- | -------------------------------- |
| `blocklist_aggregator.py`  | `DestroyScammers/scripts/blocklist_checker.py`                         | HTTP to 8 public lists; 6h cache |
| `ctlog_lookup.py` (crt.sh) | `DestroyScammers/scripts/crtsh_lookup.py`                              | crt.sh JSON                      |
| `merklemap_client.py`      | (wraps `merklemap-cli` Rust client via subprocess OR reimpl in Python) | MERKLEMAP_API_KEY                |
| `webarchive.py`            | `DestroyScammers/scripts/webarchive_lookup.py`                         | archive.org CDX + Wayback        |
| `ghunt.py` [DEPRECATED]    | `DestroyScammers/scripts/ghunt_lookup.py`                              | Deprecated and Deleted           |
| `whoxy_reverse.py`         | `DestroyScammers/scripts/whoxy_lookup.py`                              | WHOXY_API_KEY (paid)             |

Existing `virustotal.py`, `urlscan.py`, `whois_lookup.py`, `dns_lookup.py`, `ssl_inspect.py` unchanged.

### 4.2 New ingestion adapters

- `i4g jobs ingest phishdestroy-archive --path <ScamIntelLogs-checkout>` — parses each team directory (`iocs.json`, `chat/`, `user-*-messages.json`, `domains.txt`, `scammers_login.txt`, `successful_thefts/`). Idempotent, resumable, commit-sha-aware.
- `i4g jobs ingest phishdestroy-actors --path <DestroyScammers/data/data.json>` — per-email actor record → `threat_actors` + `actor_identities` + `leak_records` + `registrant_pivots`.
- `i4g jobs ingest destroylist` — pulls `phishdestroy/destroylist` list → `blocklist_hits` with `source="phishdestroy"`.

### 4.3 merklemap tail worker (Cloud Run job, streaming)

Python worker wrapping `merklemap-cli tail` (or direct SSE client). Pipeline:

1. Read stream line → `domain_discoveries` (staging row, cheap).
2. Filter: brand-regex list (Trust Wallet, Coinbase, Ledger, MetaMask, …) OR blocklist hit OR typosquat heuristic (Levenshtein vs protected-brand list).
3. On match → enqueue SSI passive investigation via existing `review_queue` / `ssi_scan` paths.
4. Emit metrics: domains/sec seen, match rate, scans enqueued.

---

## 5. Schema Additions (Alembic migrations, additive)

All new tables include `source_provenance JSON` and standard `created_at`/`updated_at`.

### 5.1 Actor & identity graph

```
threat_actors
  actor_id (uuid, pk)
  display_name       (text, not null)                 -- e.g. "TrustWalletPanel — Lyokha"
  role               (text)                           -- primary_operator | operator | recruiter | social_engineer
  campaign_id        (fk campaigns, nullable)
  real_name          (text, nullable)                 -- PII-gated
  confidence         (numeric(5,4))
  first_seen_at, last_seen_at
  metadata, source_provenance

actor_identities
  identity_id        (uuid, pk)
  actor_id           (fk threat_actors, cascade)
  platform           (text, not null)                 -- telegram | discord | twitter | email | wallet | google
  handle             (text, not null)                 -- @username or email or 0xaddr
  platform_user_id   (text, nullable)                 -- telegram numeric id, google person_id
  username_history   (JSON)                           -- [{username, observed_at}]
  display_name_history (JSON)                         -- [{display_name, observed_at}]
  first_seen_at, last_seen_at
  metadata, source_provenance
  UNIQUE (platform, handle)

actor_identity_edges
  edge_id            (uuid, pk)
  source_identity_id (fk actor_identities)
  target_identity_id (fk actor_identities)
  edge_type          (text)                           -- shared_telegram_group | shared_domain_registrant | shared_wallet
  weight             (numeric)                        -- e.g. shared_groups count
  evidence           (JSON)
  UNIQUE (source_identity_id, target_identity_id, edge_type)
```

### 5.2 Chat / victim engagement

```
chat_sessions
  session_id         (uuid, pk)
  case_id            (fk cases, nullable)
  campaign_id        (fk campaigns, nullable)
  actor_id           (fk threat_actors, nullable)
  chat_ref           (text)                           -- upstream chat number, e.g. "1795"
  message_count      (int)
  language           (text)
  deposit_demand     (bool)
  victim_confirmed_send (bool)
  started_at, last_message_at
  evidence_blob_sha256 (text)                         -- pointer into evidence storage
  metadata, source_provenance

victim_engagements (aggregate per campaign, re-computed from chat_sessions)
  campaign_id, total_sessions, active_responded, deeply_engaged_10plus,
  admin_deposit_demands, victims_confirmed_send, languages JSON, peak_month
```

### 5.3 Financial damage

```
financial_damage_claims
  claim_id           (uuid, pk)
  case_id            (fk cases, nullable)
  campaign_id        (fk campaigns, nullable)
  session_id         (fk chat_sessions, nullable)
  currency           (text)                           -- USDT | ETH | BTC | TRX | USD
  chain              (text)                           -- ethereum | tron | bitcoin | null
  amount_claimed     (numeric(36,18))                 -- as reported in chats
  amount_confirmed   (numeric(36,18), nullable)       -- after on-chain verification
  tx_hash            (text, nullable)
  wallet_address     (text, nullable)                 -- scammer-side receiver
  verification_status (text)                          -- unverified | partial | confirmed
  metadata, source_provenance
  INDEX (campaign_id, currency)
```

### 5.4 Infrastructure profile

```
infrastructure_profiles
  profile_id         (uuid, pk)
  campaign_id        (fk campaigns)
  primary_domain     (text)
  subdomain_roles    (JSON)                           -- {panel: "...", victim_api: "...", admin_api: "...", static_cdn: "..."}
  tech_stack         (JSON)                           -- frontend, backend, auth, web_server, db
  source_maps_exposed (bool)
  auth_model         (text)                           -- e.g. "JWT Bearer + sessionStorage"
  cors_config        (text)
  metadata, source_provenance
```

### 5.5 Enrichment tables

```
leak_records
  leak_id, actor_id, identity_id, source_breach, password_count,
  num_results, observed_at, source_provenance

blocklist_hits
  hit_id, indicator_id, source (MetaMask|ScamSniffer|OpenPhish|SEAL|Enkrypt|destroylist|Polkadot|CryptoFirewall|PhishDestroy),
  first_seen_at, last_seen_at, metadata
  UNIQUE (indicator_id, source)

brand_impersonations
  impersonation_id, indicator_id, brand (text), confidence, detected_by, source_provenance
  INDEX (brand)

registrant_pivots
  pivot_id, pivot_type (email|person|phone|company|google_person_id),
  pivot_value (text, not null), linked_actor_ids JSON, linked_case_ids JSON,
  linked_domains JSON, last_refreshed_at, source_provenance
  UNIQUE (pivot_type, pivot_value)

domain_discoveries   (merklemap staging)
  discovery_id, domain, subject_common_name, not_before, source (merklemap|crtsh),
  seen_at, filter_match (bool), filter_reason (text), enqueued_scan_id, raw JSON
```

All tables include a `source_provenance` JSON column. FKs to `cases`/`campaigns`/`entities` are nullable so ingestion can run before classification catches up.

---

## 6. UI — Actor-Centric Console

New route group in `ui/apps/web/`: `/actors`, `/actors/[id]`. Existing `/reviews` / `/cases` unchanged.

- **Actor list:** filter by role, campaign, activity window, threat-level (blocklist hit count + confirmed financial damage).
- **Actor detail:** identity panel (handles + username timeline), co-membership graph (force-directed), linked campaigns, top chat sessions, financial-damage ledger, screenshot gallery, leak indicators, brand-impersonation badges.
- **Campaign detail** (existing page): add a "Actors" tab + "Infrastructure profile" card + "Damage ledger" card.
- **Discovery feed** (new `/discoveries`): live tail of merklemap matches, analyst can one-click "enqueue passive scan" or "dismiss".
- **RBAC:** PII fields (operator real-name, full chat transcripts, leak passwords) gated to `role=senior_analyst` via existing auth middleware; every view is audit-logged.

---

## 7. Phased Delivery (4 Sprints)

Each sprint is ~2 weeks. "MVP-done" = deployed to `i4g-dev` + smoke tests green.

### Sprint 1 — Foundations + Quick Wins + Merklemap MVP

- Alembic migration 1: `threat_actors`, `actor_identities`, `actor_identity_edges`, `blocklist_hits`, `domain_discoveries`.
- SSI modules: `blocklist_aggregator.py`, `ctlog_lookup.py`, `merklemap_client.py`.
- Ingestion: `i4g jobs ingest destroylist` (first use of `blocklist_hits`).
- Merklemap tail worker deployed as Cloud Run job (dev only); brand-regex filter from a config file; auto-enqueue SSI passive scan.
- Basic `/discoveries` UI page (read-only list + dismiss).
- Docs: `docs/design/phishdestroy-integration.md` describing the provenance model.

**Risk:** merklemap API key pricing + rate limits — validate in Sprint 0 spike.

### Sprint 2 — ScamIntelLogs archive ingestion

- Alembic migration 2: `chat_sessions`, `financial_damage_claims`, `infrastructure_profiles`, `brand_impersonations`.
- `i4g jobs ingest phishdestroy-archive` — parses `iocs.json` + chat exports for one team end-to-end as the contract test (TrustWalletPanel is the richest sample).
- Backfill: run against all ~15 teams in the archive.
- Evidence blobs (chat exports, photos, panel source maps) stored via `storage/evidence.py` with SHA-256 pointers.
- Campaign pages show the new cards (Damage ledger, Infrastructure profile).

**Risk:** Chat exports vary in format per team (JSON vs HTML) — write format-detection with explicit `unknown_format` failure mode; don't guess.

### Sprint 3 — Actor graph + enrichment + UI

- Alembic migration 3: `leak_records`, `registrant_pivots`.
- SSI modules: `whoxy_reverse.py`, `ghunt.py` (Deprecated & Deleted), `webarchive.py`.
- `i4g jobs ingest phishdestroy-actors` — hydrates actor graph from `DestroyScammers/data/data.json` + `registrants.json`.
- Actor list + actor detail UI pages. Co-membership graph rendered from `actor_identity_edges`.
- RBAC gating for PII fields wired to existing role middleware.

**Risk:** [DEPRECATED] GHunt requires Google cookie auth — must live in Secret Manager with a rotation runbook; document failure-mode when cookie expires (Deprecated & Removed).

### Sprint 4 — Polish + ML hook-in + readiness

- Merklemap filter v2: typosquat score (Levenshtein vs. protected-brand list) + blocklist cross-check + brand-regex.
- Pass actor + financial-damage signals to ML team (`ml/` repo) as a new feature group for classifier training (documented handoff only; ML team owns consumption).
- Prod deployment of all Cloud Run jobs; dashboard SLOs.
- Full analyst walkthrough + feedback pass.
- Runbooks for: upstream re-sync, API-key rotation (merklemap, whoxy, virustotal, urlscan, GHunt [DEPRECATED]), PII-access audit review.
- Prepare a collaboration packet for him describing what we built, what he could consume back, and a proposed two-way interface (no code in this sprint — preparation for a future collaboration discussion).

---

## 8. Interfaces with Existing Systems

| Existing system            | Interaction                                                                                                                                                                                                         |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `core/api/review.py`       | New review-queue items can be created by the merklemap worker. No schema change on review side.                                                                                                                     |
| `core/store/structured.py` | New stores: `ThreatActorStore`, `ChatSessionStore`, `FinancialDamageStore`, `InfrastructureProfileStore`, `BlocklistHitStore`, `RegistrantPivotStore`, `DomainDiscoveryStore`. Use existing `factories.py` pattern. |
| `core/reports/`            | Dossier templates extended with actor section + financial-damage ledger + infra profile when present. Guarded by feature flag until templates reviewed.                                                             |
| `ssi/osint/__init__.py`    | Export new modules; orchestrator opts them in via config flags. No change to active recon.                                                                                                                          |
| `core/audit_log`           | Every PII-field read logged with actor identity + reason code.                                                                                                                                                      |
| `ml/` (i4g-ml)             | New feature group: actor-centric features (co-membership degree, cross-campaign domain count, leak count, blocklist hit count) made available via BigQuery view. Consumed by ML team on their timeline.             |

---

## 9. Legal, Ethical, Operational

- **Data origin transparency:** every ingested row carries `source_provenance.source = "phishdestroy"`. UI surfaces the origin. Partners (law enforcement, integrators) can filter.
- **PII handling:** operator real-names, victim transcripts, leak passwords are `sensitive=true` columns at the store level; API requires elevated role + reason; audit-logged.
- **Takedown interactions:** out of scope. If he decides to collaborate on takedowns, a separate PRD.
- **Upstream drift:** ingestion is idempotent by `source_provenance.commit_sha + team + record_id`. Re-running on a newer commit updates in place.
- **Rate limits / costs:** merklemap, urlscan, virustotal, whoxy all metered. Dashboard SLOs include per-service daily-quota utilisation.
- **Attribution risk:** the actor graph mixes confirmed identities (he has chain-of-custody) with his inferences. We carry his confidence scores verbatim and never up-weight them.

---

## 10. Success Metrics

| Metric                                                   | Target (end of Sprint 4)                                                            |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| ScamIntelLogs teams ingested                             | ≥ 15 (all current) with < 1% parse failures                                         |
| Actor profiles hydrated from `DestroyScammers/data.json` | ≥ 1,400 of ~1,500                                                                   |
| Blocklist sources live in aggregator                     | 8/8 sources polling on 6h cadence                                                   |
| Merklemap discoveries → auto-enqueued scans              | p50 ingest-to-enqueue < 60 s                                                        |
| SSI passive-scan enrichment hit rate increase            | +30 % IoC coverage vs. pre-integration baseline (measured on a held-out domain set) |
| Analyst time-to-actor-profile                            | < 10 s from search to rendered detail page                                          |
| Audit trail coverage on PII reads                        | 100 %                                                                               |

---

## 11. Open Questions

1. **Collaboration cadence.** Once the plan is built, do we share read-only API access with him as a gesture before formal collaboration?
2. **destroylist two-way.** Can we auto-contribute newly-confirmed malicious domains back into `phishdestroy/destroylist` via PR? Deferred to post-Sprint 4.
3. **Telegram chat re-distribution.** We ingest and store; do we ever expose chat transcripts in dossier exports to law enforcement partners? Needs counsel sign-off before Sprint 2 ships to prod.
4. **GHunt cookie ops.** [DEPRECATED & DELETED] If Google kills GHunt auth, do we have a fallback? Document the risk and a "disable module" switch.
5. **Actor identity merge UX.** When the same operator appears across teams (Sprint 2+3 integration point), who approves merges? Proposal: `role=senior_analyst` in the new `/actors/merge` flow; default to **suggested-only** never auto-merge.

---

## 12. Source Material Location

Local checkouts (temporary) in `/Users/jerry/Work/project/phishdestroy/`:

- `ScamIntelLogs/` — archive
- `DestroyScammers/` — dashboard + `scripts/` toolchain + `data/*.json`
- `merklemap-cli/` — Rust CT-log tail client

Upstream on GitHub: `github.com/phishdestroy/{ScamIntelLogs,DestroyScammers,merklemap-cli,destroylist}`. Session working notes: `copilot/memories/session/phishdestroy-integration-notes.md` (detailed schema inventory — will be discarded after the PRD is approved).
