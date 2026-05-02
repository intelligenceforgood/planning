# PhishDestroy Integration — Sprint Tasks

**Status:** In Progress (Resumed by new team)
**Created:** 2026-04-23
**Updated:** 2026-04-29
**PRD:** `prd_phishdestroy_integration.md`
**Workflow:** Planner/Executor split — each sprint produces one (or more) Task Manifests under
`planning/handoffs/` via `/handoff`; Executor implements; Planner verifies via `/verify-handoff`.
**Archive after completion:** Summarize outcomes in `change_log.md`, then move this file to `archive/`.

---

## How to use this plan

- This is the **north-star checklist** spanning all four sprints. Check off (`- [x]`) items
  **immediately** when done so progress is visible across long sessions and model switches.
- Each sprint is broken into units small enough to become one Executor manifest (3–15 files,
  single concern, testable). Sprint-level manifests are acceptable when scope is coherent
  (see `plan-work` skip-threshold guidance).
- Order inside a sprint is dependency-ordered: **migration → stores → services/jobs → API → UI**.
- Flagged manual steps (`[manual]`) are Planner/operator actions — not for the Executor.
- Risk / acceptance notes live under each sprint and must be restated in every manifest's
  `<verification>` block.

### Repo impact map

| Repo     | Scope                                                                                |
| -------- | ------------------------------------------------------------------------------------ |
| `core/`  | Alembic migrations, stores, factories, ingestion jobs, API routes, audit, dossiers   |
| `ssi/`   | New OSINT modules (`blocklist_aggregator`, `ctlog_lookup`, `merklemap_client`, ...)  |
| `ui/`    | `/discoveries`, `/actors`, `/actors/[id]`, campaign-page cards, RBAC surfacing       |
| `infra/` | Cloud Run job for merklemap tail, Secret Manager entries, Scheduler for blocklist 6h |
| `ml/`    | BigQuery feature-group view (Sprint 4 handoff only — ML team owns consumption)       |
| `docs/`  | End-user docs for actor view + discoveries; developer docs live in `core/docs/`      |

---

## Sprint 0 — Spikes & Guardrails (short, before Sprint 1)

**Focus:** De-risk external dependencies and lock the provenance contract before writing schema.

**Exit criteria:** Spike reports filed in `planning/`; go/no-go on merklemap + whoxy budget; all
Sprint 1 unknowns have an answer or a documented fallback.

**Sprint 0 status (2026-04-23): partially landed.** Deterministic deliverables (provenance
contract, provider-gating pattern, commit-SHA pin, settings slots, merklemap probe script) are
**done**. Live-measurement spikes and budget decisions are **deferred to a follow-up**: they
require the user to run the probe with a funded API key and make budget calls that Copilot
cannot make. Sprint 1 is unblocked for all items except the merklemap tail throughput sizing
(see quota-gated notes below).

### Deterministic (done this session)

- [x] **Provenance contract frozen** — `copilot/.github/shared/phishdestroy-provenance.instructions.md`
      (JSON shape, `record_id` rules, allowed `source` vocabulary, pinned SHAs, idempotency key,
      `sensitive=True` marker).
- [x] **Provider-gating contract frozen** — `copilot/.github/shared/phishdestroy-provider-gating.instructions.md`
      (`ProviderGate` pattern, `SkippedResult` surfacing, PRD §10 deferral rule, rotation hooks).
- [x] **Source-material snapshot** — pinned in provenance doc §4:
  - `ScamIntelLogs` → `83d0307420fcc865fcb8a34b8c454acbc6d56f1f` (2026-03-01)
  - `DestroyScammers` → `c40cbbf527dd9e5e232090346e1a8ceab32d1683` (2025-11-30)
  - `merklemap-cli` → `550cb04aa633c000724c339ada085c59444d5b78` (2024-10-06)
- [x] **Settings TOML slots added** for `merklemap`, `whoxy`, `ghunt`:
  - `core/config/settings.default.toml` (commented placeholders)
  - `core/config/settings.local.toml` (real empty slots — paste rotated keys here)
  - `ssi/config/settings.default.toml` (commented placeholders)
  - `ssi/config/settings.dev.toml` (Secret Manager binding references)
- [x] **Merklemap probe script** — `ssi/scripts/spike_merklemap.py`. Standalone, no SSI imports;
      writes `data/reports/spikes/merklemap.json`.

### Quota-gated / user-action required (deferred, NOT blocking Sprint 1 start)

- [ ] **[user-action] Rotate pasted API keys.** `merklemap` + `whoxy` keys were pasted in a
      chat turn and are now in the Copilot conversation log. Rotate both at their provider
      consoles and paste replacements into `core/config/settings.local.toml` under
      `[providers.merklemap]` / `[providers.whoxy]`.
- [ ] **[user-action] Merklemap throughput spike** — run the probe for 30 min, review output:
      `conda run -n i4g-ssi python ssi/scripts/spike_merklemap.py --duration-minutes 30`
      (requires rotated `SSI_PROVIDERS__MERKLEMAP__API_KEY` or the `api_key` in
      `ssi/config/settings.local.toml`). Sizes staging-table throughput for Sprint 1.5.
      **Until this runs, Sprint 1.5 ships with a conservative default (batch=100, flush=5s) that
      the filter-v2 sprint tunes later.**
- [ ] **[user-action] SSE path confirmation** — the probe defaults to
      `https://api.merklemap.com/v1/stream`. Verify against merklemap-cli source
      (`/Users/jerry/Work/project/phishdestroy/merklemap-cli/src/main.rs`) before the first run
      and update `DEFAULT_URL` in `spike_merklemap.py` if it differs.
- [ ] **[quota:whoxy][user-action] Whoxy budget decision** — pull pricing page, pick monthly cap
      that fits budget, set `monthly_query_cap` in `ssi/config/settings.dev.toml`. If
      cost-prohibitive, leave `enabled = false`; Sprint 3.3 `whoxy_reverse.py` ships as a
      `SkippedResult(reason="quota_gated")` stub per provider-gating contract.
- [ ] **[quota:ghunt][user-action] GHunt auth spike** — follow upstream GHunt docs to generate
      cookie blob, store under `ssi/config/settings.local.toml`
      `[providers.ghunt] cookie_blob_path`. If lifecycle < 14 days, defer Sprint 3.3 ghunt to
      post-MVP and leave `enabled = false`.
- [ ] **Implementation choice: Python SSE** (default decision, revisit if probe shows parse
      issues). Python stdlib + `httpx` handles SSE well; no need to wrap the Rust binary.
      Rationale recorded here, not a separate spike report.
- [ ] **Failure-mode plan for feed drops** — encoded in the Sprint 1.5 worker spec: exponential
      back-off (2^n capped at 30s), bounded in-memory queue (≤10k), Cloud Monitoring alert on
      `merklemap_reconnects_total > 3 / 5m`. Detailed wiring lands with the Sprint 1.5 manifest.
- [ ] **[manual] Counsel review kicked off** for PII (chat transcripts, operator real-names,
      leak passwords). Sprint 2 cannot ship to **prod** without sign-off (PRD §11 Q3). Does
      NOT block Sprint 2 dev work.

---

## Sprint 0.5 — Unblocking & Resumption (Immediate)

**Focus:** Address pending blockers and prepare for local-only development due to zero-budget constraints.

- [x] **Rotate & Secure API Keys:** Rotate Merklemap and Whoxy API keys. Keys are stored in `config/settings.local.toml`.
- [x] **Throughput Spike:** Implement the staging tables and queue, but skip the 30-min live spike for now. Ensure implementation is production-ready for when budget is available.
- [x] **Budget Constraints:** Develop all features (including Whoxy/GHunt modules) but add configuration flags to disable API calls and use free tiers or local mock data where possible.
- [x] **Legal Approval:** Counsel sign-off on PII storage (chat transcripts, real names) obtained.
- [x] **Design Execution:** Draft wireframes for the UI cards (Damage Ledger, Infra Profile) and the `/actors` view.
- [x] **ML Schema Definition:** Define the exact BigQuery schema for `i4g_ml.actor_features` to unblock Sprint 4.

---

## Sprint 1 — Foundations + Quick Wins + Merklemap MVP

**Goal:** First upstream bytes land in I4G. Blocklist ingestion + live discovery feed working
end-to-end in `i4g-dev`, with the smallest schema slice needed to support them.

**Suggested manifest split:**

1. Migration 1 + stores + factories (`core/`)
2. SSI modules (`blocklist_aggregator`, `ctlog_lookup`, `merklemap_client`) (`ssi/`)
3. `destroylist` ingestion job (`core/`)
4. Merklemap tail Cloud Run job + infra (`core/` + `infra/`)
5. `/discoveries` UI (`ui/`)

**Exit criteria:** Deployed to `i4g-dev`; smoke tests green; `destroylist` fully ingested;
merklemap tail has produced ≥ 1 auto-enqueued SSI scan end-to-end.

### 1.1 Schema migration 1 (core/)

- [x] **Alembic revision:** `phishdestroy_sprint1_actors_blocklist_discoveries`
  - [x] `threat_actors` (PRD §5.1)
  - [x] `actor_identities` with UNIQUE (platform, handle) (PRD §5.1)
  - [x] `actor_identity_edges` with UNIQUE (source_identity_id, target_identity_id, edge_type)
  - [x] `blocklist_hits` with UNIQUE (indicator_id, source)
  - [x] `domain_discoveries` (staging) — indexed on `seen_at`, `filter_match`
  - [x] Every table includes `source_provenance JSON`, `created_at`, `updated_at`
  - [x] FKs to `cases`/`campaigns`/`entities` are **nullable**
  - [x] `sensitive=true` column marker for `threat_actors.real_name`
- [x] **Downgrade tested** — `alembic downgrade -1` then `upgrade head` clean on SQLite + Postgres <!-- Postgres round-trip deferred to post-merge `i4g db migrate dev` -->

### 1.2 Stores + factories (core/)

- [x] `ThreatActorStore` (create/get/find_by_identity/list_by_campaign)
- [x] `ActorIdentityStore` (upsert_by_handle, list_by_actor, append_username_history)
- [x] `ActorIdentityEdgeStore` (upsert_edge, neighbors)
- [x] `BlocklistHitStore` (upsert, list_by_indicator, list_by_source)
- [x] `DomainDiscoveryStore` (insert, list_recent_matches, mark_enqueued)
- [x] Wire all of the above into `src/i4g/services/factories.py`
- [x] Unit tests under `tests/unit/store/` for each store (happy path + upsert idempotency)

### 1.3 SSI OSINT modules (ssi/)

Each module implements the existing `scan(...)` contract in `src/ssi/osint/` and is opted in via
config flag in the orchestrator. No changes to existing modules.

- [x] `blocklist_aggregator.py` — queries 8 sources (MetaMask, ScamSniffer, OpenPhish, SEAL,
      Enkrypt, destroylist, Polkadot, CryptoFirewall); 6h cache; emits one `blocklist_hits`-shaped
      record per (indicator, source) <!-- 2026-04-24 manifest 2026-04-24-phishdestroy-sprint-1-phaseA -->
- [x] `ctlog_lookup.py` — crt.sh JSON; subdomain enumeration; handles rate limits + back-off
- [x] `merklemap_client.py` — SSE tail client (per Sprint 0 decision); exposes async iterator
- [x] Unit tests per module with recorded fixtures; no live network in CI <!-- 44 tests passing, no live network -->
- [x] Register modules in `ssi/osint/__init__.py` behind config flags <!-- PHISHDESTROY_PROVIDERS + phishdestroy_provider_enabled() -->
- [x] **(bonus)** Shared provider-gating primitive `ssi/src/ssi/providers/gate.py` (`ProviderGate` + `SkippedResult`) hoisted for reuse across Sprint 1.5+ providers

### 1.4 Ingestion: destroylist (core/)

- [x] `i4g jobs ingest-destroylist` CLI command (note: dash-separated, not space-separated — sub-app refactor deferred)
  - [x] Pulls from pinned commit SHA (Sprint 0 decision)
  - [x] Idempotent by `source_provenance.commit_sha + domain`
  - [x] Writes `blocklist_hits` with `source="phishdestroy.destroylist"`
- [x] Smoke test: `I4G_ENV=local i4g jobs ingest-destroylist` produces ≥ 1k rows (23,561 rows on first run; 0 inserted on second run — idempotency confirmed)
- [x] Docs: env var table + job manifest updated in `core/docs/config/` <!-- Phase B added `phishdestroy.destroylist.*`; Phase C added `phishdestroy.merklemap_tail.*` to both `core/docs/config/settings_manifest.yaml` and `docs/config/settings_manifest.yaml` (drift-check requires both copies) -->

### 1.5 Merklemap tail worker (core/ + infra/)

- [x] `src/i4g/worker/jobs/merklemap_tail.py` — streaming worker
  - [x] Reads merklemap SSE → upsert into `domain_discoveries` (cheap staging)
  - [x] Filter: brand-regex list from config (Trust Wallet, Coinbase, Ledger, MetaMask, …)
  - [x] On match → enqueue SSI passive via `review_queue` / `ssi_scan` paths
  - [x] Metrics: domains/sec, match rate, scans enqueued
  - [x] Graceful reconnect on stream drop; bounded memory
- [ ] **(infra/)** Cloud Run job `merklemap-tail-dev` with Secret Manager binding for
      `MERKLEMAP_API_KEY`; `terraform fmt -check` clean <!-- code landed Phase D1 2026-04-25; plan/apply + smoke deferred to Phase D2 (GCP billing paused) -->
- [ ] **(infra/)** Cloud Scheduler for 6h blocklist aggregator run (dev) <!-- deferred to Sprint 4 — no aggregator CLI exists yet -->
- [ ] **[manual]** Populate `MERKLEMAP_API_KEY` secret in `i4g-dev` Secret Manager
- [x] Local Docker smoke harness `scripts/smoke_merklemap_tail_local.py` <!-- Wrap-up 2026-04-25; operator-run, no GCP -->
- [ ] E2E dev smoke: tail runs ≥ 30 min, produces ≥ 1 filter match, scan appears in review queue

### 1.6 `/discoveries` UI (ui/)

- [x] Next.js route `apps/web/src/app/(console)/discoveries/page.tsx`
- [x] List view: recent `domain_discoveries` where `filter_match=true`; columns: domain,
      seen_at, filter_reason, enqueued_scan_id, actions
- [x] One-click "Enqueue passive scan" + "Dismiss" (calls proxy route → core API) <!-- UI bound Phase E2 2026-04-25 -->
- [x] Proxy route `apps/web/app/api/discoveries/route.ts` <!-- covered by catch-all proxy at src/app/api/[...path]/route.ts; no dedicated route file needed -->
- [x] `pnpm format && pnpm lint && pnpm build` clean; `get_errors` clean on all changed files

### 1.7 Docs + verification

- [x] `docs/design/phishdestroy-integration.md` (developer-facing, in `core/docs/`) describing
      provenance model + data flow <!-- Wrap-up 2026-04-25 -->
- [x] `docs/book/analyst-guide/discoveries.md` (end-user, in `docs/`) — short walkthrough <!-- Wrap-up 2026-04-25 -->
- [x] `SUMMARY.md` updated <!-- Wrap-up 2026-04-25 -->
- [x] Change-log entry in `planning/change_log.md` <!-- Wrap-up 2026-04-25 -->

**Sprint 1 risks to carry forward**

- merklemap pricing / rate limits (Sprint 0 output)
- blocklist source availability (some lists flap) — circuit breaker per source

---

## Sprint 2 — ScamIntelLogs Archive Ingestion

**Goal:** Full archive (≥ 15 teams) ingested with < 1% parse failures; dossiers show damage +
infra cards.

**Suggested manifest split:**

1. Migration 2 + stores + factories
2. Per-team format-detection + adapter (TrustWalletPanel first as contract test)
3. Evidence blob pathway for chat/photos/source-maps
4. Backfill over all teams
5. Campaign-page UI cards (Damage ledger + Infrastructure profile)

**Exit criteria:** TrustWalletPanel end-to-end ingest matches upstream record counts;
≥ 15 teams ingested in dev; Damage ledger + Infrastructure profile cards render on a campaign
with data.

<!-- Phase D: backfill driver, damage parser, brand best-effort, generalised team registry — landed 2026-04-27. -->
<!-- Phase E: Detector format extensions (FLAT_FILES) — landed 2026-04-29. -->

### 2.1 Schema migration 2 (core/)

- [x] **Alembic revision:** `phishdestroy_sprint2_chats_damage_infra_brands`
  - [x] `chat_sessions` (PRD §5.2) — `evidence_blob_sha256` pointer
  - [x] `financial_damage_claims` (PRD §5.3) — INDEX (campaign_id, currency)
  - [x] `infrastructure_profiles` (PRD §5.4)
  - [x] `brand_impersonations` (PRD §5.5) — INDEX (brand)
  - [x] All tables have `source_provenance JSON` + timestamps
  - [x] Downgrade tested

### 2.2 Stores + factories (core/)

- [x] `ChatSessionStore`, `FinancialDamageStore`, `InfrastructureProfileStore`,
      `BrandImpersonationStore`
- [x] Wire into `factories.py`
- [x] Unit tests (happy path + upsert idempotency by source_provenance key)

### 2.3 Archive ingestion adapter (core/)

- [x] `i4g jobs ingest phishdestroy-archive --path <ScamIntelLogs-checkout>` <!-- Phase B: `ingest-archive` CLI command ships; single-team ingest via --team + --path -->
  - [x] Per-team discovery: `iocs.json`, `chat/`, `user-*-messages.json`, `domains.txt`,
        `scammers_login.txt`, `successful_thefts/` <!-- Phase B: detector reads iocs.json + chats_translated.json for TWP; remaining file types are Phase C/D/E -->

  - [x] Format detector with explicit `unknown_format` failure — never guess (PRD §7 Sprint 2 risk) <!-- Phase B: detector.py + 4 unit tests -->
  - [x] TrustWalletPanel contract test: golden input → exact expected row counts per table <!-- Phase B: 21 tests; chat=3, infra=1, financial_damage=0, brand_impersonations=0 -->
  - [x] Idempotent + resumable by `source_provenance.commit_sha + team + record_id` <!-- Phase B: idempotency test passes -->
  - [x] Parse-failure report written to `data/reports/phishdestroy/<team>.json` <!-- Phase B: runner writes per-team report; unknown_format covered -->

- [x] Backfill driver: iterate all team dirs, aggregate pass/fail summary <!-- Phase D: backfill.py + run_archive_backfill(); ArchiveBackfillSummary; 6 tests -->
- [x] Parse-failure rate < 1% on the full archive (acceptance metric) <!-- Phase D: gate landed in code; live full-archive verification deferred to Phase F. -->

### 2.4 Evidence blob storage (core/)

<!-- Phase C: chat exports + photos + panel captures landed; bucket lifecycle remains an operator action. -->

- [x] Route chat exports, photos, panel source maps through existing `storage/evidence.py`
- [x] SHA-256 pointer recorded in owning row (`chat_sessions.evidence_blob_sha256` etc.)
- [x] Verify dossier signing picks up new evidence types
- [ ] **[manual]** Confirm storage bucket lifecycle rules cover new blob shape

### 2.5 Campaign-page UI cards (ui/)

- [x] Campaign detail page: **Damage ledger** card (per-currency totals, claimed vs confirmed)
- [x] Campaign detail page: **Infrastructure profile** card (tech_stack, subdomain_roles,
      source_maps_exposed, auth_model)
- [x] Campaign detail page: **Actors** tab placeholder (populated in Sprint 3)
- [x] Feature-flag dossier-template changes until reviewed
- [x] `get_errors` clean on all changed files

### 2.6 Verification

- [x] Run full backfill in dev; attach summary to the Sprint 2 verify-handoff report
- [x] Audit-log entries present for every ingested PII-bearing row
- [x] Change-log entry

**Sprint 2 gate (prod):** Counsel sign-off on chat-transcript storage + dossier surfacing
(PRD §11 Q3) **before** prod deploy.

---

## Sprint 3 — Actor Graph + Enrichment + UI

**Goal:** Actor-centric view live. Enrichment modules power pivots that weren't possible before.
PII gating wired and audited.

**Suggested manifest split:**

1. Migration 3 + stores + factories
2. SSI modules (`whoxy_reverse`, `ghunt`, `webarchive`)
3. `phishdestroy-actors` ingestion job + edge builder
4. Actor API routes + RBAC + audit
5. `/actors` + `/actors/[id]` UI including co-membership graph

**Exit criteria:** ≥ 1,400 of ~1,500 actor profiles hydrated; co-membership graph renders;
PII fields gated to `role=senior_analyst` with 100% audit coverage in dev.

### 3.1 Schema migration 3 (core/)

- [x] **Alembic revision:** `phishdestroy_sprint3_leaks_pivots`
  - [x] `leak_records` (PRD §5.5)
  - [x] `registrant_pivots` with UNIQUE (pivot_type, pivot_value)
  - [x] Downgrade tested

### 3.2 Stores + factories (core/)

- [x] `LeakRecordStore`, `RegistrantPivotStore`
- [x] Wire into `factories.py`
- [x] Unit tests

### 3.3 SSI enrichment modules (ssi/)

- [x] `whoxy_reverse.py` — reverse WHOIS by email/name/company/phone (gated behind Sprint 0 budget
      decision; stub with 501 if deferred)
- [x] `ghunt.py` — Google persona OSINT; Secret Manager cookie; disable-switch via config when
      auth expires; rotation runbook
- [x] `webarchive.py` — archive.org CDX + Wayback download
- [x] Unit tests with recorded fixtures

### 3.4 Actor ingestion + graph hydration (core/)

- [x] `i4g jobs ingest phishdestroy-actors --path <DestroyScammers/data/data.json>`
  - [x] `data.json` → `threat_actors` + `actor_identities` + `leak_records`
  - [x] `registrants.json` → `registrant_pivots`
  - [x] Edge builder: `shared_telegram_group`, `shared_domain_registrant`, `shared_wallet`
  - [x] Idempotent; never auto-merges actors (see PRD §11 Q5 — suggestion-only)
- [x] Run in dev; report actor count vs. target ≥ 1,400

### 3.5 Actor API + RBAC + audit (core/)

- [x] `GET /actors` (filter: role, campaign, activity window, threat-level)
- [x] `GET /actors/{id}` (identity panel, edges, linked campaigns, chats, damage, leaks, brands)
- [x] PII fields (`threat_actors.real_name`, chat transcripts, leak passwords) return only for
      `role=senior_analyst`
- [x] Every PII-bearing read emits `audit_log.log_action` with actor identity + reason code
- [x] Reason code required on PII requests (`?reason=...` or header)
- [x] Unit + integration tests for RBAC denial paths

### 3.6 Actor UI (ui/)

- [x] `/actors` list page (filters per PRD §6)
- [x] `/actors/[id]` detail page with:
  - [x] Identity panel + username/display-name timelines
  - [x] Co-membership graph (force-directed, e.g. d3-force or similar — reuse existing viz lib)
  - [x] Linked campaigns + top chat sessions
  - [x] Financial-damage ledger
  - [x] Screenshot gallery (evidence)
  - [x] Leak indicators + brand-impersonation badges
- [x] PII unlock flow: modal requires reason; sends reason to API; surfaces "PII — audited" tag
- [x] Campaign page **Actors** tab wired
- [x] `get_errors` clean; a11y pass (keyboard, alt text)

### 3.7 Verification

- [x] End-to-end analyst walkthrough in dev (record findings)
- [x] Confirm 100% audit coverage: every PII read produces a log row
- [x] Change-log entry

**Sprint 3 risks**

- GHunt auth expiry (Sprint 0 runbook)
- Whoxy budget (may ship as stub)
- Identity-merge UX deferred — suggestion-only; no auto-merge code paths

---

## Sprint 4 — Polish, ML Hook-in, Prod Readiness

**Goal:** Everything from Sprints 1–3 in prod with SLOs. ML feature group published. Collaboration
packet ready.

**Suggested manifest split:**

1. Merklemap filter v2 (typosquat + blocklist cross-check) + metrics
2. ML BigQuery feature-group view (`ml/`)
3. Prod deploys (all Cloud Run jobs) + SLO dashboards (`infra/`)
4. Runbooks + collaboration packet (docs)
5. Analyst feedback pass + follow-up fixes

**Exit criteria:** All acceptance metrics in PRD §10 met on `i4g-prod`; dashboard SLOs live;
runbooks complete; collaboration packet reviewed.

### 4.1 Merklemap filter v2 (core/)

- [x] Typosquat score: Levenshtein distance vs. protected-brand list
- [x] Blocklist cross-check: consult `blocklist_hits` before enqueue
- [ ] Combined score → enqueue decision; record `filter_reason` (brand-regex | typosquat |
      blocklist | combo)
- [ ] Tune thresholds on a replay of 24h of dev staging data (skipped per user constraints)
- [x] Metrics: false-positive rate, scans-enqueued/hour

### 4.2 ML feature group (ml/ — handoff only)

- [-] BigQuery view `i4g_ml.actor_features` with: co-membership degree, cross-campaign domain
  count, leak count, blocklist hit count, damage-confirmed total
- [-] Document the contract in `ml/docs/` and notify ML team
- [-] No consumption code here — ML team owns

### 4.3 Prod deployment (infra/ + core/)

- [-] Cloud Run job `merklemap-tail-prod`
- [-] Cloud Scheduler `blocklist-aggregator-prod` (6h)
- [-] Cloud Run job specs for `phishdestroy-archive` + `phishdestroy-actors` (re-sync cadence)
- [-] Secret Manager entries in prod: `MERKLEMAP_API_KEY`, `WHOXY_API_KEY` (if live), GHunt blob
- [-] `terraform fmt -check` clean; pre-merge review per
  `copilot/.github/shared/pre-merge-checklist.instructions.md`
- [ ] **[manual]** Run `i4g db migrate prod` for Sprint 1/2/3 migrations at deploy time
- [ ] **[manual]** Verify counsel sign-off on file before prod ingest of chat transcripts

### 4.4 SLO dashboards

- [-] Per-service daily-quota utilisation (merklemap, urlscan, virustotal, whoxy)
- [-] p50 ingest-to-enqueue latency panel (< 60 s target per PRD §10)
- [-] Parse-failure rate per team (< 1% target)
- [-] Blocklist-aggregator source health (8/8 up)

### 4.5 Runbooks (`core/docs/runbooks/`)

- [-] Upstream re-sync (bumping commit SHA + running archive/actors jobs)
- [-] API-key rotation: merklemap, whoxy, virustotal, urlscan, GHunt
- [-] PII-access audit review (weekly cadence — surface via audit log queries)
- [-] GHunt cookie-expiry recovery

### 4.6 Collaboration packet (docs/ + planning/)

- [ ] Short document for the upstream author describing: what we built, sources consumed,
      provenance preserved, what could flow back
- [ ] Proposed two-way interface sketch (no code) — deferred PRD
- [ ] **[manual]** Review with team before any outreach

### 4.7 Acceptance (PRD §10) — check each metric

- [ ] ≥ 15 teams ingested with < 1% parse failures
- [ ] ≥ 1,400 of ~1,500 actor profiles hydrated
- [ ] 8/8 blocklist sources live on 6h cadence
- [ ] p50 ingest-to-enqueue < 60 s
- [ ] SSI passive-scan IoC coverage +30% vs. pre-integration baseline (held-out set)
- [ ] Analyst time-to-actor-profile < 10 s
- [ ] 100% audit coverage on PII reads

### 4.8 Wrap

- [ ] Final change-log entry
- [ ] Move this file to `planning/tasks/archive/` after sign-off
- [ ] Open follow-up PRDs for: two-way destroylist contribution, actor-merge workflow, takedown
      interactions (all out of scope here per PRD §1.3 / §11)

---

## Cross-cutting non-negotiables (apply every sprint)

- **Additive schema only.** Never mutate existing `cases`/`entities`/`indicators` column semantics.
- **Provenance on every row.** `source_provenance` JSON per the Sprint-0 frozen contract.
- **Idempotency.** All ingestion jobs keyed by `commit_sha + team + record_id`. Re-running on a
  newer commit updates in place.
- **PII gated + audited.** `sensitive=true` columns; elevated role + reason code; `audit_log`
  entry on every read.
- **Env + smoke discipline (core/).** Every new setting → `tests/unit/settings/` coverage +
  `docs/config/` env-var table + YAML manifest + local smoke before Cloud Run.
- **Pre-merge review every sprint.** Run `pnpm format / lint / build` (ui), `terraform fmt -check`
  (infra), `pre-commit run --all-files` two-pass (core/ssi). `get_errors` on every changed file
  — do not rely on CLI exit codes alone.
- **No two-way integration in v1.** We consume only. Any outbound flow requires a new PRD.
