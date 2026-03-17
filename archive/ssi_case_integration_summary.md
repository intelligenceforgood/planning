# SSI ↔ Cases Deep Integration: Summary

> **Completed:** March 2026
> **Source Proposal:** `planning/proposals/ssi_case_integration_spike.md`
> **Source PRD:** `planning/prd_scam_site_investigator.md`
> **Repos:** core, ssi, ui, docs

---

## What Was Built

Four integration features connecting SSI scam-site investigations to the case management system: case-triggered investigations, one-to-many case↔investigation linking, URL deduplication, and background task visibility on case detail.

---

## Phase 1 — Data Model & Foundational Linking

**Goal:** Establish the relational schema and foundational utilities that all subsequent phases depend on.

**Delivered:** `case_investigations` join table (composite PK on `case_id`, `scan_id`, with `trigger_type` and `created_at`) via Alembic migration, `site_scans.normalized_url` column with composite index for dedup queries. URL normalization utility (`normalize_url()` — lowercases, strips default ports/fragments/tracking params, sorts query params, handles IDN). Evidence path utility (`evidence_path()` — 2-level hex-prefix sharding, 65K shards). Backfill scripts for both `case_investigations` and `normalized_url`. `ScanStore.create_case_record()` updated to write to both `site_scans.case_id` and `case_investigations` atomically (SQLite + PostgreSQL dialect compat). `ScanStore.create_scan()` populates `normalized_url`. `AutoInvestigateSettings` model added to Settings (enabled, staleness_days, max_concurrent, domain_blocklist) with env var overrides (`I4G_AUTO_INVESTIGATE__*`).

## Phase 2 — URL Dedup & Auto-Investigation Engine

**Goal:** Prevent redundant investigations and automate investigation triggering for URLs found in ingested cases.

**Delivered:** `check_url_duplicate()` utility with staleness window logic (fresh/stale/in-progress/no-prior-scan). `InvestigationTriggerResponse` model with dedup info (existing scan_id, risk score, days since scan). `force` parameter to bypass dedup for re-investigations. `is_domain_blocked()` utility with subdomain matching and default blocklist (Google, Facebook, etc.). Extended `linkage_extract.py` with `--mode=cases` to extract URL indicators from batch-ingested case narratives. `auto_investigate` worker job — queries cases with uninvestigated URL indicators, deduplicates by normalized URL, filters through domain blocklist, triggers SSI investigations, links results via `case_investigations` with `trigger_type='auto'`. CLI: `i4g jobs auto-investigate [--dry-run] [--limit N]`. `TaskStatusReporter` integration for progress visibility.

## Phase 3 — API Enrichment & Case Activity Backend

**Goal:** Expose investigation data and background task status through the API for the UI to consume.

**Delivered:** `GET /cases/{id}` enriched with `investigations: CaseInvestigationSummary[]` (scan_id, url, status, risk_score, trigger_type, linked_at). `GET /investigations/ssi/{scan_id}` enriched with `linkedCases: LinkedCaseSummary[]`. New `GET /cases/{id}/activity` endpoint aggregating classification, linkage extraction, and SSI investigation activities with `hasRunning` flag for UI polling decisions. New `POST /cases/{id}/investigate` endpoint — manual investigation trigger with dedup check, `force` bypass, audit logging. Evidence path sharding integrated into SSI's `EvidenceStorageClient` (new scans use sharded paths; old flat paths still resolvable). `metadata.json` manifest generation per scan with SHA-256 hashes. SDK types (`CaseInvestigationSummary`, `CaseActivity`, `CaseActivityResponse`, `InvestigationTriggerResponse`) with Zod schemas and client methods.

## Phase 4 — UI: Case Detail Activity & Investigation UX

**Goal:** Give analysts visibility into background tasks and the ability to trigger/manage SSI investigations directly from case detail.

**Delivered:** `useCaseActivity` polling hook (10s interval, auto-stops when all activities terminal). Activity bar at top of case detail — pill badges for classification, linkage extraction, SSI investigations with state-appropriate styling (grey/amber/green/red) and animated transitions. URL investigation status panel — rows per URL with status badges, risk scores, and action buttons (Investigate / View Result / Retry / Re-investigate). `InvestigateButton` component with loading state and error feedback. Dedup warning modal — shows existing scan info ("investigated N days ago"), offers View Existing or Re-investigate Anyway. Investigation history timeline — latest result prominently displayed, expandable list of prior scans with risk score change indicators. Case detail page converted to server/client hybrid (`case-detail-client.tsx` wrapper). Skeleton loading states. Full keyboard accessibility (`aria-label`, `aria-live`, focus trap in modal).

## Phase 5 — Evidence Migration, Docs & E2E Validation

**Goal:** Migrate evidence storage layout, update documentation, and validate the full integration end-to-end.

**Delivered:** Evidence path migration script (`migrate_evidence_paths.py`) supporting local and GCS backends with dry-run and idempotency. Evidence manifest generation script (`generate_evidence_manifests.py`). Settings manifest updated in YAML, JSON, and README with all `auto_investigate` env vars. Architecture docs: case↔investigation linking model, auto-investigation trigger mechanism, evidence sharding scheme. Analyst guide (`auto-investigation.md`) covering dedup behavior, re-investigation, domain blocklist. E2E smoke test (`test_ssi_case_integration_e2e.py`) validating the full flow: ingest case → extract URLs → auto-investigate → verify API responses.

---

## New Environment Variables

| Variable                                 | Type      | Default | Description                                         |
| ---------------------------------------- | --------- | ------- | --------------------------------------------------- |
| `I4G_AUTO_INVESTIGATE__ENABLED`          | bool      | `false` | Enable automatic SSI investigation for case URLs    |
| `I4G_AUTO_INVESTIGATE__STALENESS_DAYS`   | int       | `30`    | Days before a URL investigation is considered stale |
| `I4G_AUTO_INVESTIGATE__MAX_CONCURRENT`   | int       | `3`     | Max concurrent auto-investigations per job run      |
| `I4G_AUTO_INVESTIGATE__DOMAIN_BLOCKLIST` | list[str] | `[]`    | Domains to skip during auto-investigation           |

## Advisory for Future Work

1. **Redis migration:** The activity endpoint uses the in-memory `TASK_STATUS` dict for ephemeral tasks. When core migrates to Redis-backed task tracking, the activity endpoint should query Redis directly for real-time status and fall back to `review_actions` for historical activities.
2. **Evidence GCS migration:** The migration script supports GCS but requires careful copy-then-verify-then-delete execution. Validate on `i4g-dev` bucket before prod.
3. **Auto-investigate production activation:** Feature is disabled by default (`enabled=false`). Enable via `I4G_AUTO_INVESTIGATE__ENABLED=true` on the auto-investigate Cloud Run Job after validating the domain blocklist covers known legitimate domains in the case corpus.
