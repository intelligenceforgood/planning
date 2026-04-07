# Engagements Phase 1 — Data Model + API + Scoping

> **PRD:** `planning/prd_engagements.md`
> **Sprint target:** Phase 1 (backend only — no UI)
> **Started:** 2026-04-07

---

## Tasks

- [x] **Step 1 — Add `instructor` role** (`core/src/i4g/api/roles.py`)
  - Add `INSTRUCTOR` to `Role` enum between `analyst` and `leo`
  - Update `ROLE_HIERARCHY` (instructor inherits analyst, user, researcher)
  - Update `LEO` and `ADMIN` to include instructor
  - Add tests for new hierarchy

- [x] **Step 2 — Alembic migration + schema** (`core/src/i4g/store/sql.py`, `core/src/i4g/migrations/versions/`)
  - Add `engagements` table to `sql.py`
  - Add `engagement_id` FK column on `cases`
  - Create Alembic migration `20260407_01_add_engagements_table.py`
  - Verify migration runs forward and backward

- [x] **Step 3 — Engagement store** (`core/src/i4g/store/engagement_store.py`)
  - CRUD: create, get, list, update, delete (soft-archive)
  - Case assignment: assign_cases, remove_cases
  - Summary: get_summary (case count, reviewed, completion %)
  - Unit tests

- [x] **Step 4 — Engagement CRUD API router** (`core/src/i4g/api/routers/engagements.py`)
  - POST/GET/PATCH/DELETE /engagements
  - POST/DELETE /engagements/{id}/cases
  - GET /engagements/{id}/summary
  - Pydantic v2 models with camelCase aliases
  - Role guards (instructor+ for writes, analyst+ for reads)
  - Register router in app.py
  - Unit tests

- [x] **Step 5 — `X-Engagement-Id` middleware** (`core/src/i4g/api/middleware/engagement.py`)
  - Extract and validate header
  - Store on `request.state.engagement_id`
  - Register in app.py
  - Unit tests

- [x] **Step 6 — Filter injection: ReviewStore** (`core/src/i4g/store/review_store.py`)
  - Add `engagement_id` param to `get_dashboard_summary()`
  - Apply WHERE clause when present
  - Extend tests

- [x] **Step 7 — Filter injection: HybridSearchQuery** (`core/src/i4g/services/hybrid_search.py`)
  - Add `engagement_id` field to `HybridSearchQuery`
  - Inject filter in `_build_filter_items()`
  - Extend tests

- [x] **Step 8 — Propagate scope to endpoints** (multiple routers)
  - Read `request.state.engagement_id` in affected endpoints
  - Pass to store/service methods
  - Affected: reviews, cases, intelligence, impact, intake
  - Auto-tag intake cases with engagement_id from header

- [x] **Step 9 — Engagement-aware ingestion** (`core/src/i4g/worker/jobs/ingest.py`, `core/src/i4g/store/ingest.py`)
  - Accept `--engagement-id` CLI arg
  - Pass through to `_write_sql_case()`
  - Extend tests

- [x] **Step 10 — Backfill script** (`core/scripts/backfill_engagement.py`)
  - Create engagements from historical ingestion runs
  - Set engagement_id on existing cases
  - Dry-run by default; `--commit` to apply

- [x] **Step 11 — Settings extension** (`core/src/i4g/settings/`)
  - Add `EngagementSettings` section
  - Env var: `I4G_ENGAGEMENT__*`
  - Tests

- [x] **Step 12 — Integration smoke test**
  - Create engagement → ingest cases → verify scoped queries
  - Verify unscoped queries still return all cases

---

## Manual Actions (post-merge)

- `conda run -n i4g alembic upgrade head` on dev
- Same on prod after dev validation
- Run backfill script once per environment
- Document `instructor` role in `docs/config/`

## Risks

| Risk                                                             | Mitigation                                                   |
| ---------------------------------------------------------------- | ------------------------------------------------------------ |
| Engagement filter missed on query path                           | Test matrix: every case-returning endpoint × scoped/unscoped |
| New `instructor` role breaks existing checks                     | Backward-compatible hierarchy subsumption                    |
| Nullable `engagement_id` → orphan cases invisible in scoped mode | "All Engagements" mode + backfill script                     |
