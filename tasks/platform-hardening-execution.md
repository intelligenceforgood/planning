# Platform Hardening — Execution Plan

**Created:** 17 April 2026
**Source:** [platform-review-2026-04-17.md](platform-review-2026-04-17.md) (Parts 1–6)
**Model guidance:** See Part 6 of the review for model routing (4.6 vs 4.7) per task.

> **How to use this file:** Check off tasks (`- [x]`) as they are completed. Add the completion
> date and a one-line note after the checkbox. Update `planning/change_log.md` for significant
> changes. Use the `hardening-sprint` Copilot prompt to bootstrap each session.

---

## Phase 0 — Stabilize (Weeks 1–2)

**Goal:** Close every CRITICAL finding. Stop the bleeding.

**Success criteria:**

- No production startup path can run with `disable_auth=true`
- API key compare is `compare_digest`; CI lint prevents `==` on `settings.api.key`
- Prod deploy requires manual approval; tested via dry-run release
- Cloud SQL backup export to a second region is visible; manual restore drill passes
- Evidence buckets show dual-region replication
- `infra/docs/incident_response.md` exists and linked from `copilot/.github/shared/`

### Tasks

- [ ] **0.1** Environment-gate `disable_auth` via Pydantic validator + startup check _(core, XS, model: 4.6)_
  - Add `model_validator(mode="after")` on Settings: raise if `disable_auth=true` and `env != local`
  - Add startup check in `create_app()`
  - Add unit test under `tests/unit/settings/`

- [ ] **0.2** Timing-safe API key compare + require forwarded-user header _(core, XS, model: 4.6)_
  - Replace `token == settings.api.key` with `hmac.compare_digest` in `auth.py`
  - Require `X-I4G-Forwarded-User` for API-key auth, else 401
  - Give service callers minimum-required role, not admin
  - Add unit test

- [ ] **0.3** Rotate API keys + Gemini keys; verify prod LLM works _(infra/secrets, XS, model: 4.6, depends: 0.2)_
  - Rotate API key in Secret Manager
  - Replace Gemini placeholder with real key
  - Verify end-to-end LLM call in dev

- [ ] **0.4** Server-side engagement cookie (`HttpOnly; Secure; SameSite=Lax`) _(ui, S, model: 4.6)_
  - Create `POST /api/engagements/select` Next.js route that sets the cookie server-side
  - Remove `document.cookie` usage in `engagement-cookie.ts`
  - Keep `sessionStorage` copy for optimistic UI if needed
  - Add `Strict-Transport-Security`, `Content-Security-Policy`, `X-Content-Type-Options` headers

- [ ] **0.5** Cloud SQL backup hardening _(infra, M, model: 4.6)_
  - Set `backup_retained_backups_count = 30`, PITR ≥ 7 days in Terraform
  - Create cross-region GCS backup export bucket
  - Weekly export schedule via Cloud Scheduler or Terraform
  - Manual restore drill — document result

- [ ] **0.6** Evidence + reports buckets → dual-region _(infra, S, model: 4.6)_
  - Change evidence buckets (`i4g-*-ssi-evidence`) to dual-region (nam5)
  - Change reports buckets to dual-region
  - Verify replication in console

- [ ] **0.7** CI approval gate: `release/*` branch for prod _(core, ui, M, model: 4.6)_
  - Add `release/*` branch protection rules
  - Add `workflow_dispatch` manual approval step for prod-image promotion
  - Dev auto-deploys on `main`; prod requires approval
  - Test via dry-run release cycle
  - Document in `copilot/docs/` or relevant deployment guide

- [ ] **0.8** Incident runbook v1 _(infra, S, model: 4.6)_
  - Create `infra/docs/incident_response.md`
  - Cover top 5 incidents: Cloud SQL down, API 5xx spike, SSI browser hung, evidence bucket gone, leaked secret
  - Severity definitions, immediate actions, escalation
  - Link from `copilot/.github/shared/`

---

## Phase 1 — Foundation (Weeks 3–6)

**Goal:** Architecture changes that unblock everything else.

**Success criteria:**

- Rate limit and task status survive a two-instance scale-out test
- Every route responds under `/v1`; `/` paths return deprecation headers
- SDK types auto-generate on CI and break the build on contract change
- Only Core contains DDL for all shared tables
- `audit_log` has a hash chain verified by a monthly job
- Report job is safe to restart mid-run

### Tasks

- [ ] **1.1** Redis or DB-backed rate-limit + task-status _(core, infra, M, model: 4.6, depends: 0.5)_
  - Provision Memorystore (Redis) in Terraform, or add `task_status` + `rate_limit_buckets` tables
  - Replace in-memory `REQUEST_LOG` and `TASK_STATUS` in `app.py`
  - Prune old entries on schedule
  - Test with two instances

- [ ] **1.2** API versioning: mount all routers under `/v1` _(core, M, model: 4.6)_
  - Add `V1_PREFIX = "/v1"` and mount all routers
  - Keep unprefixed routes with redirect for one release cycle
  - Publish OpenAPI spec with version in title
  - Update UI proxy paths

- [ ] **1.3** Generate UI SDK types from OpenAPI _(ui, M, model: 4.6, depends: 1.2)_
  - Add `openapi-typescript` to `ui/packages/sdk`
  - CI step: fetch OpenAPI from Core, generate types, fail on diff
  - Remove `.passthrough()` from Zod schemas
  - Update imports across `apps/web/`

- [ ] **1.4** Unified DB schema: Core owns all DDL _(core, ssi, L, model: 4.7 preferred — see sub-tasks for 4.6)_
  - [ ] **1.4a** Inventory all SSI table definitions (`site_scans`, `harvested_wallets`, `agent_sessions`, `pii_exposures`, `ecx_enrichments`, etc.)
  - [ ] **1.4b** Create Core-owned SQLAlchemy models for all shared tables in `core/src/i4g/store/sql.py`
  - [ ] **1.4c** Write Alembic migration to align schema — **human review checkpoint here**
  - [ ] **1.4d** Update SSI imports to use Core-owned models (SSI depends on Core's schema package)
  - [ ] **1.4e** Remove `METADATA.create_all()` from SSI startup; require Alembic migration
  - [ ] **1.4f** Document the Core-owned schema contract in `planning/architecture/integration_contracts.md`

- [ ] **1.5** Audit-log hash chain + PII policy for `detail` _(core, M, model: 4.6)_
  - Add `prev_hash` column to `audit_log`
  - Write `SHA256(prev_hash || canonical_row_json || salt)` on each insert
  - Monthly verification job
  - Document which events must be logged (PII decryption, review approvals, LEO exports)
  - Define PII policy for `detail` column (what can be stored, retention)

- [ ] **1.6** FK indexes audit + migration _(core, S, model: 4.6)_
  - Audit: `review_actions.review_id`, `entity_mentions.entity_id`, `indicator_sources.entity_id`, `intake_attachments.intake_id`
  - One Alembic migration to add missing indexes
  - Verify against prod schema

- [ ] **1.7** Soft-delete consistency: `cases_active` view _(core, M, model: 4.6, depends: 1.6)_
  - Create `cases_active` DB view filtering `is_deleted = false`
  - Apply view in store query methods
  - Test soft-delete lifecycle

- [ ] **1.8** Report job idempotency + lease/heartbeat _(core, M, model: 4.6, depends: 1.1)_
  - Add `report_generated_at`, `locked_by`, `lock_expires_at` columns (or `job_leases` table)
  - Conditional UPDATE on pick-up; skip if already generated
  - Heartbeat every 30s; release on success/failure
  - Test restart-mid-run scenario

- [ ] **1.9** UI catch-all proxy hardening _(ui, S, model: 4.6)_
  - Add path-prefix allowlist to `[...path]/route.ts`
  - Reject `..` segments explicitly
  - Whitelist forwarded headers (not blacklist)
  - Add test

- [ ] **1.10** eCX submission dead-letter table + retry _(ssi, S, model: 4.6)_
  - Create `ecx_submission_failures` table
  - On failure, insert to DLQ instead of swallowing
  - Retry on schedule (Cloud Scheduler or background task)
  - Alert when DLQ depth > threshold

---

## Phase 2 — Quality (Weeks 7–12)

**Goal:** Tests, observability, docs, onboarding.

**Success criteria:**

- Critical-path tests exercise DB and storage
- Nightly smoke passes 95%+ over a month
- Alerts fire in drills; on-call escalation tested
- New developer: clone to "hello world" in < 30 minutes
- Accessibility axe score ≥ 95 on every console page
- End-user docs cover analyst, LEO, admin, victim personas

### Tasks

- [ ] **2.1** Rewrite test theater: ~30 unit tests → DB-integration assertions _(core, M, model: 4.6, depends: 1.4)_
  - Identify tests that only assert mock call counts
  - Rewrite to use SQLite and assert DB state
  - Focus on: auth, intake encryption, review queue transitions, SSI persistence, report generation

- [ ] **2.2** End-to-end smoke suite _(core, ui, L, model: 4.6, depends: 0.7)_
  - Ingest → search → enqueue → report → LEO package
  - Nightly + pre-deploy trigger
  - Run against dev environment

- [ ] **2.3** Alert policies _(infra, M, model: 4.6)_
  - SSI failure rate > 10%/h
  - eCX submission fail > 0
  - Core 5xx > 1%/5m
  - API p95 latency > 2s/10m
  - Cloud SQL CPU > 80%/15m
  - Uptime check per service (`/healthz`)
  - Slack channel (dev) + PagerDuty (prod)

- [ ] **2.4** SSI orchestrator hardening _(ssi, M, model: 4.6)_
  - `finally` blocks for terminal-state writes with retry
  - Outer timeouts on agent
  - Browser cleanup in `finally`
  - Emit `ssi_terminal_state_write_failure` metric

- [ ] **2.5** Accessibility audit + fixes _(ui, M, model: 4.6)_
  - Run axe on each console page
  - Set accessibility floor in CI (`@axe-core/playwright`)
  - Fix critical/serious issues
  - Document in `ui/docs/accessibility.md`

- [ ] **2.6** Docker Compose onboarding + shell helpers _(core, ssi, ml, M, model: 4.6)_
  - `docker compose up` for SQLite+Chroma+mock LLM
  - `make shell-core`, `make shell-ssi`, `make shell-ml` helpers
  - Update `copilot/docs/onboarding.md`

- [ ] **2.7** Finish LEO guide and victim user guide _(docs, M, model: 4.6)_
  - Complete `docs/book/law-enforcement-guide/`
  - Complete `docs/book/user-guide/`
  - Add "Coming soon" banners to remaining stubs

- [ ] **2.8** Data retention policy doc + aligned code _(core, planning, S, model: 4.6)_
  - Write `planning/architecture/data_retention_policy.md`
  - PII retention window, soft-delete lifecycle, hard-delete timing, evidence retention for LE
  - Align `retention-purge` scheduler code with policy
  - Add test

- [ ] **2.9** Dependabot + Trivy + SBOM _(all repos, S, model: 4.6)_
  - Enable Dependabot for all 9 repos
  - Add Trivy scan to Docker build workflow
  - Generate CycloneDX SBOM per release

- [ ] **2.10** Analyst engagement UX review + spec _(planning, ui, S, model: 4.6)_
  - Walk through engagement switching with cross-engagement edge cases
  - Deep link behavior, saved-query scoping
  - Write spec in `planning/prd_engagements.md`

---

## Phase 3 — Scale (Weeks 13–20)

**Goal:** Performance, hardening, production-readiness for real scale.

**Success criteria:**

- p95 search latency holds under 2× current volume
- DR restore drill runs monthly, unattended, and passes
- ML labeled dataset ≥ 1,000; NER in production as shadow model
- No human has `roles/owner` on prod

### Tasks

- [ ] **3.1** Normalize JSON columns → structured columns _(core, L, model: 4.6, depends: 1.6)_
  - `classification_result` → intent, channel, risk, confidence columns
  - `tags` → PG `ARRAY`
  - Keep JSON only for opaque provider payloads
  - Migration + backfill

- [ ] **3.2** Cloud Armor + per-user rate limit _(infra, core, M, model: 4.6, depends: 1.1)_
  - Cloud Armor security policy on external LB
  - 50 investigations/day per user; 1,000 req/min per IP
  - Challenge-response on anomalies

- [ ] **3.3** Vector-store fallback metric + alert _(core, S, model: 4.6, depends: 2.3)_
  - Increment metric on fallback in `retriever.py`
  - Alert if fallback active > 5 minutes

- [ ] **3.4** Quarterly DR restore drill automation _(infra, M, model: 4.6, depends: 0.5)_
  - Automated restore-to-staging script
  - Monthly schedule
  - Report results to Slack

- [ ] **3.5** Per-service `max_instances` + budget alerts _(infra, XS, model: 4.6)_
  - Set `max_instances` on every Cloud Run service
  - GCP budget alert at 80% of monthly nonprofit credit

- [ ] **3.6** ML data push: label 500+ cases _(ml, planning, L, model: 4.7 — strategic decision)_
  - Define labeling protocol and quality bar
  - Label 500+ new cases to unblock NER + fraud-taxonomy
  - Revert ML PRD status to "Phase 3 partial" until dataset gates pass

- [ ] **3.7** Admin IAM least-privilege refactor _(infra, M, model: 4.6)_
  - Split admin + break-glass groups
  - Admin gets `roles/viewer` + resource-level bindings
  - Break-glass group has owner only under monitored conditions

- [ ] **3.8** Zero-downtime migration discipline _(core, S, model: 4.6)_
  - Write `core/docs/design/migration_strategy.md`
  - Expand-migrate-contract pattern
  - Forbid column deletes in the same release that adds usages
  - CI check if feasible

---

## Phase 4 — Evolve (Ongoing)

Resume feature development with **one active PRD at a time**:

1. **Engagements to v1 shipped** (closest to done)
2. **Fraud Taxonomy v1** (depends on Engagements + sufficient ML data)
3. **Entity Extraction v2** (long, modular — ship behind a flag)
4. **eCX Integration** (Contribute + Orchestrate phases)

TIFAP remains continuous-improvement background work.

---

## Progress Tracker

| Phase     | Total           | Done  | %      |
| --------- | --------------- | ----- | ------ |
| Phase 0   | 8               | 0     | 0%     |
| Phase 1   | 10 (+6 sub)     | 0     | 0%     |
| Phase 2   | 10              | 0     | 0%     |
| Phase 3   | 8               | 0     | 0%     |
| **Total** | **36 (+6 sub)** | **0** | **0%** |

_Update this table as tasks are completed._
