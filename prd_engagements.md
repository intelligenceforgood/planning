# PRD: Engagements — Bounded Work Periods for Case Scoping & Analytics

> **Document Version**: 1.0
> **Last Updated**: April 7, 2026
> **Owner**: Product & Engineering
> **Status**: v1.0 — Draft for Cross-Functional Review

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [What We Have Today — Honest Assessment](#3-what-we-have-today--honest-assessment)
4. [Personas](#4-personas)
5. [Naming Decision](#5-naming-decision)
6. [Design: Engagement Model](#6-design-engagement-model)
7. [Design: Operational Scoping](#7-design-operational-scoping)
8. [Design: UI — Engagement Selector](#8-design-ui--engagement-selector)
9. [Design: Analytics & Leaderboard](#9-design-analytics--leaderboard)
10. [Build vs. Looker Decision](#10-build-vs-looker-decision)
11. [Phased Delivery](#11-phased-delivery)
12. [Success Metrics](#12-success-metrics)
13. [Risks & Mitigations](#13-risks--mitigations)
14. [Open Questions](#14-open-questions)
15. [Technical References](#15-technical-references)

---

## 1. Executive Summary

The I4G Platform originated as a tool for structured inter-university competitions where
students review pre-collected fraud cases within bounded time periods (semesters,
competitions, exercises). Each period produces its own analytics — classification accuracy,
top performers, detection velocity — and culminates in awards for exceptional analysts.

The platform currently has **no first-class representation of this bounded work period**.
Cases carry an `ingestion_batch_id` for operational provenance and can be grouped into
`threat_campaigns` for intelligence attribution, but neither concept represents the
educational/operational unit of "the Spring 2026 competition." Students see every case ever
ingested; analytics are global; performance comparisons span unrelated time periods.

This PRD introduces **Engagements** — a lightweight scoping mechanism that groups cases into
bounded work periods. An engagement answers: "Which cases should this group of analysts be
working on right now, and how do we measure their performance against that specific set?"

| Lens                   | Without Engagements                             | With Engagements                                    |
| ---------------------- | ----------------------------------------------- | --------------------------------------------------- |
| **Student experience** | Sees all 2,000+ cases; unclear which to work on | Sees only the 50 cases assigned to Spring 2026      |
| **Manager analytics**  | Ad-hoc SQL to filter by date range              | Per-engagement dashboard: accuracy, speed, coverage |
| **Multi-university**   | All data co-mingled; no isolation               | Each university/competition is its own engagement   |

---

## 2. Problem Statement

### 2.1 Origin Story

I4G began as cross-university fraud case review competitions. Each semester, organizers:

1. Collected a batch of real-world fraud cases from law enforcement partners
2. Assigned them to student teams
3. Ran a time-bounded review period (typically 4–8 weeks)
4. Measured performance: classification accuracy, review throughput, intelligence quality
5. Awarded top performers

This cycle is the fundamental unit of work in the platform's educational deployment.

### 2.2 The Gap

When the platform was productionized, the focus shifted to threat intelligence features
(campaigns, entity graphs, indicator linking). The competition-round concept was documented
in early design notes but never elevated to a first-class system concept. The
`ingestion_batch_id` on `cases` tracks how data arrived — not what working context it
belongs to. The `threat_campaigns` model tracks adversary behavior — not analyst work
boundaries.

### 2.3 Consequences

| Problem                                                       | Impact                                                           |
| ------------------------------------------------------------- | ---------------------------------------------------------------- |
| Students see all cases, not just their assigned set           | Confusion, accidental work on wrong cases, data integrity risk   |
| No per-competition analytics                                  | Managers resort to spreadsheets or manual BigQuery queries       |
| No performance comparison within a bounded period             | Awards are subjective instead of data-driven                     |
| Multi-university deployment requires manual case partitioning | Onboarding a new university partner is a custom engineering task |
| Historical competition results are not queryable              | Institutional knowledge lost after each semester                 |

---

## 3. What We Have Today — Honest Assessment

### 3.1 Existing Infrastructure That Helps

- **`ingestion_runs` table** — tracks import jobs with `dataset`, `source_bundle`,
  timestamps, and case counts. Could serve as a building block but lacks semantic meaning
  (an ingestion run is not a competition).
- **`cases.ingestion_batch_id`** — UUID column linking cases to their import origin.
  Nullable, not consistently populated.
- **`threat_campaigns`** — first-class M:N campaign model with lifecycle management. Good
  design precedent but wrong concept (intelligence attribution ≠ work scoping).
- **`HybridSearchQuery` filters** — the search system already supports filter injection.
  Adding one more filter dimension is straightforward.
- **`ReviewStore.get_dashboard_summary(filters)`** — dashboard queries accept a filters
  dict. Engagement scoping can piggyback on this.
- **Role-based access** (`api/roles.py`) — role hierarchy already gates what users see.

### 3.2 What's Missing

- No `engagements` table or concept in the data model
- No session-level scoping mechanism in the API (no way to say "scope all my queries to
  engagement X")
- No engagement selector in the UI
- No per-engagement analytics breakdowns in `platform_kpis` or TIFAP dashboards
- No leaderboard or analyst performance model
- `ingestion_batch_id` is operational metadata, not a user-facing concept

---

## 4. Personas

### 4.1 Competition Organizer (Manager)

**Profile:** University professor or I4G staff member who manages competitions.

**Goals:**

- Create an engagement for each competition round with a defined case set
- Monitor student progress during the engagement (who's reviewed what, accuracy so far)
- Generate per-engagement analytics reports after completion
- Compare performance across students within an engagement
- Archive completed engagements without losing data

**Journey:** Creates "Spring 2026 — UAB" engagement → ingests 50 cases tagged to it →
assigns students → monitors dashboard during the 6-week period → closes engagement →
exports leaderboard and analytics PDF → presents results at awards ceremony.

### 4.2 Student Analyst

**Profile:** Graduate student in criminology, data science, or cybersecurity.

**Goals:**

- See only the cases relevant to their current competition
- Not be overwhelmed by historical data from prior competitions
- Understand their own performance relative to peers
- Switch between engagements if participating in multiple programs

**Journey:** Logs in → sees engagement selector defaulted to "Spring 2026 — UAB" →
dashboard shows 50 cases, 12 reviewed, 38 remaining → works through queue → checks
leaderboard position → engagement ends → sees final stats in read-only mode.

### 4.3 Platform Administrator

**Profile:** I4G operations team member managing the platform across universities.

**Goals:**

- Create and manage engagements across multiple universities
- View cross-engagement analytics (platform-wide KPIs)
- Ensure data isolation between concurrent engagements at different institutions
- Bulk-assign cases to engagements

**Journey:** Creates engagements for UAB, GWU, and CMU → bulk-ingests cases per engagement
→ monitors all three from "All Engagements" view → generates cross-engagement comparison
report at end of semester.

### 4.4 Law Enforcement Partner

**Profile:** LEA analyst contributing cases or consuming intelligence products.

**Goals:**

- Not affected by engagement scoping (LEA users typically work in "All Engagements" mode)
- Access cross-engagement intelligence products (entity graphs, indicator feeds)

---

## 5. Naming Decision

### 5.1 Candidates Evaluated

| Term           | Pros                                       | Cons                                                  |
| -------------- | ------------------------------------------ | ----------------------------------------------------- |
| **Batch**      | Familiar in data contexts                  | Developer jargon; conflates with `ingestion_batch_id` |
| **Cohort**     | Academic resonance                         | Implies people, not work periods                      |
| **Campaign**   | Common in security                         | Already taken (`threat_campaigns`)                    |
| **Exercise**   | CTF / military precedent                   | Implies training, not real-world work                 |
| **Program**    | Bug bounty precedent (HackerOne)           | Too broad; conflicts with "university program"        |
| **Collection** | Intelligence community usage               | Implies data gathering, not review work               |
| **Engagement** | Neutral; fits education + professional LEA | Slight ambiguity with "user engagement" metrics       |
| **Season**     | Sports/media precedent                     | Too informal for LEA context                          |

### 5.2 Decision: **Engagement**

**Engagement** best describes a bounded period of purposeful work with defined scope,
participants, and outcomes. It works for both the educational use case ("Spring 2026
Engagement") and professional deployment ("Q2 2026 LEA Engagement"). It avoids collision
with existing system concepts (`campaign`, `batch`, `ingestion_run`).

**UI label:** "Engagement"
**API/DB identifier:** `engagement_id`
**URL slug:** `/engagements/`

---

## 6. Design: Engagement Model

### 6.1 Data Model

```sql
CREATE TABLE engagements (
    engagement_id   UUID PRIMARY KEY,
    name            TEXT NOT NULL,               -- "Spring 2026 — UAB"
    description     TEXT,
    status          TEXT NOT NULL DEFAULT 'draft',
    starts_at       TIMESTAMPTZ,                 -- optional: scheduled start
    ends_at         TIMESTAMPTZ,                 -- optional: scheduled end
    created_by      TEXT REFERENCES accounts(email),
    metadata        JSONB,                       -- university, program, notes
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- FK on cases (nullable for backward compatibility)
ALTER TABLE cases ADD COLUMN engagement_id UUID REFERENCES engagements(engagement_id)
    ON DELETE SET NULL;
CREATE INDEX idx_cases_engagement_id ON cases (engagement_id);
```

### 6.2 Lifecycle

```
draft → active → completed → archived
```

| State       | Behavior                                                                                              |
| ----------- | ----------------------------------------------------------------------------------------------------- |
| `draft`     | Engagement exists but is not visible to students. Organizer can assign cases.                         |
| `active`    | Visible in the engagement selector. Students can review cases. Analytics accumulate.                  |
| `completed` | No longer appears as default in selector. Cases are read-only for student role. Analytics are frozen. |
| `archived`  | Hidden from all non-admin views. Data retained for historical queries.                                |

Transitions:

- `draft → active`: Manual (organizer clicks "Activate")
- `active → completed`: Manual or automatic (when `ends_at` passes)
- `completed → archived`: Manual (admin action)
- Any state can revert to `draft` (admin override for corrections)

### 6.3 Engagement CRUD API

| Method | Path                        | Description                                                    | Required Role       |
| ------ | --------------------------- | -------------------------------------------------------------- | ------------------- |
| POST   | `/engagements`              | Create a new engagement                                        | `manager` or higher |
| GET    | `/engagements`              | List engagements (filtered by status, user role)               | `analyst` or higher |
| GET    | `/engagements/{id}`         | Engagement detail                                              | `analyst` or higher |
| PATCH  | `/engagements/{id}`         | Update name, description, dates, status                        | `manager` or higher |
| DELETE | `/engagements/{id}`         | Soft-delete (sets `archived`)                                  | `admin` only        |
| POST   | `/engagements/{id}/cases`   | Bulk-assign case IDs to engagement                             | `manager` or higher |
| DELETE | `/engagements/{id}/cases`   | Remove case assignments                                        | `manager` or higher |
| GET    | `/engagements/{id}/summary` | Stats snapshot: case count, review progress, top-level metrics | `analyst` or higher |

### 6.4 Case Assignment

Cases are assigned to engagements in two ways:

1. **At ingestion time.** The ingest job accepts an optional `engagement_id` parameter.
   All cases created during that ingestion run are tagged with the engagement.
2. **Post-hoc assignment.** The `POST /engagements/{id}/cases` endpoint accepts a list of
   `case_id` values and sets their `engagement_id`. This supports the workflow of curating
   an existing case pool into a competition set.

A case belongs to **at most one engagement** (1:N, not M:N). This is a deliberate
simplicity choice — competitions don't share cases, and a case appearing in multiple
engagements would complicate analytics. If future needs require M:N, a junction table can
be introduced without breaking the 1:N API contract.

### 6.5 Relationship to Existing Concepts

| Concept              | Relationship to Engagement                                                                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ingestion_batch_id` | Orthogonal. A single ingestion run may feed into one engagement, but the batch tracks provenance while the engagement tracks work scope.                    |
| `threat_campaigns`   | Orthogonal. A campaign groups cases by adversary behavior across any engagement. A case can belong to one engagement AND multiple campaigns simultaneously. |
| `dataset`            | An engagement may span multiple datasets. The engagement is a higher-order grouping.                                                                        |

---

## 7. Design: Operational Scoping

### 7.1 API Scoping Mechanism

A new request header `X-Engagement-Id` (optional) carries the active engagement context.
When present, all case-returning endpoints filter results to cases matching that
`engagement_id`.

**Middleware implementation** (`src/i4g/api/middleware/engagement.py`):

```python
# Pseudocode — actual implementation in TDD
async def engagement_middleware(request, call_next):
    engagement_id = request.headers.get("X-Engagement-Id")
    if engagement_id:
        # Validate engagement exists and is accessible to the user's role
        request.state.engagement_id = engagement_id
    else:
        request.state.engagement_id = None  # "All Engagements" mode
    return await call_next(request)
```

### 7.2 Affected Endpoints

Every endpoint that returns case data respects the engagement scope:

| Router                   | Endpoints | Scoping Behavior                                           |
| ------------------------ | --------- | ---------------------------------------------------------- |
| `/reviews/search`        | GET, POST | Add `WHERE cases.engagement_id = :eid` when header present |
| `/reviews/queue`         | GET       | Filter queue entries by engagement                         |
| `/reviews/search/schema` | GET       | Facet counts scoped to engagement                          |
| `/cases`                 | GET       | Filter case list                                           |
| `/intelligence/*`        | All       | Entity/indicator stats scoped to engagement's cases        |
| `/impact/*`              | All       | KPIs computed for engagement's case set                    |
| `/intakes`               | POST      | Auto-tag with engagement from header                       |

### 7.3 Scoping Rules by Role

| Role                  | Default Behavior                       | Can Select "All Engagements"?               |
| --------------------- | -------------------------------------- | ------------------------------------------- |
| `student` / `analyst` | Scoped to their active engagement      | No — must have an engagement selected       |
| `manager`             | Scoped to their engagement, can switch | Yes                                         |
| `admin`               | "All Engagements" by default           | Yes (always)                                |
| `researcher`          | Engagement-scoped if header present    | Yes (data is anonymized per existing rules) |

### 7.4 Not a Security Boundary

Engagement scoping is a **convenience filter**, not an authorization boundary. It reduces
noise, not access. If a student constructs a direct API call without the header, they still
see only cases their role permits — they just see all of them instead of the engagement
subset.

This is critical: engagement is NOT multi-tenancy. Data is not physically isolated. Making
it a security boundary would require row-level security, cross-engagement access policies,
and significantly more complexity. The current role-based access model handles authorization.

If future deployments require hard data isolation between universities, that is a
multi-tenancy feature — separate from engagements — and should be its own PRD.

---

## 8. Design: UI — Engagement Selector

### 8.1 Component: Engagement Switcher

A persistent dropdown in the top navigation bar, similar to AWS's region selector or
Slack's workspace switcher.

```
┌──────────────────────────────────────────────────────────────┐
│  I4G Console    [📋 Spring 2026 — UAB ▼]       🔔  👤 Jane  │
├──────────────────────────────────────────────────────────────┤
│  Dashboard  │  Cases  │  Intelligence  │  Impact  │ Reports  │
└──────────────────────────────────────────────────────────────┘
```

**Dropdown contents:**

- Active engagements the user has access to (sorted by `starts_at` descending)
- "All Engagements" option (visible only to `manager` and above)
- Completed engagements in a "Past" section (read-only badge)
- "Manage Engagements" link for `manager` role (navigates to admin page)

### 8.2 Persistence

The selected engagement is stored in `sessionStorage` (browser tab-scoped) and included as
`X-Engagement-Id` on every API call via the SDK's request interceptor.

Default selection logic on page load:

1. If `sessionStorage` has a valid engagement → use it
2. Else if URL contains `?engagement=<id>` → use it and store
3. Else if user has exactly one active engagement → auto-select it
4. Else → show the engagement picker as a modal prompt

### 8.3 Deep Links

URLs encode the engagement context as a query parameter:
`/cases/abc123?engagement=spring-2026-uab`

Shared links include the engagement context so recipients see the same scoped view.

### 8.4 Edge Cases

| Scenario                                                    | Behavior                                                                                    |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| User has no active engagements                              | Show onboarding prompt: "No active engagements. Contact your manager."                      |
| Selected engagement transitions to `completed`              | Show banner: "This engagement has ended. Data is read-only." Student cannot submit reviews. |
| User switches engagement mid-workflow                       | Dashboard, queue, and search results refresh. Unsaved form data triggers "discard?" prompt. |
| Case viewed via deep link belongs to a different engagement | Display the case but show info badge: "This case belongs to [Other Engagement]."            |

### 8.5 Engagement Management Page

Available to `manager` and above at `/settings/engagements`:

- List all engagements (filterable by status)
- Create new engagement (name, description, dates)
- Edit engagement details
- Bulk-assign cases (file upload of case IDs, or filter-and-assign from global case list)
- View engagement summary stats
- Transition lifecycle state (activate, complete, archive)

---

## 9. Design: Analytics & Leaderboard

### 9.1 Engagement-Scoped Analytics

The existing TIFAP aggregation pipeline (`analytics_aggregation.py`) extends to compute
per-engagement breakdowns:

| Table             | Change                                                                                                                                 |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `platform_kpis`   | Add `engagement_id` column. Compute one row per (period_type, period_start, engagement_id) plus one global row (engagement_id = NULL). |
| `entity_stats`    | No change — entity stats are global (an entity may appear across engagements).                                                         |
| `indicator_stats` | No change — same reasoning.                                                                                                            |
| `campaign_stats`  | No change — campaigns are cross-engagement intelligence concepts.                                                                      |

New table for analyst performance:

```sql
CREATE TABLE engagement_analyst_stats (
    engagement_id    UUID NOT NULL REFERENCES engagements(engagement_id),
    analyst_email    TEXT NOT NULL REFERENCES accounts(email),
    cases_reviewed   INTEGER NOT NULL DEFAULT 0,
    avg_review_time  INTERVAL,
    classification_accuracy  NUMERIC(5, 4),  -- vs. ground truth or consensus
    risk_score_mae   NUMERIC(5, 2),          -- mean absolute error vs. consensus
    actions_logged   INTEGER NOT NULL DEFAULT 0,
    last_activity_at TIMESTAMPTZ,
    computed_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (engagement_id, analyst_email)
);
```

### 9.2 Leaderboard

API endpoint: `GET /engagements/{id}/leaderboard`

Response: Ranked list of analysts within the engagement, sorted by a composite score:

```
composite = (accuracy_weight × classification_accuracy)
          + (throughput_weight × normalized_review_count)
          + (quality_weight × (1 - normalized_risk_mae))
```

Default weights configurable via `I4G_ANALYTICS__LEADERBOARD_WEIGHTS`.

Leaderboard is visible to:

- `manager` and above: full leaderboard with all names
- `analyst` / `student`: their own rank + anonymized neighbors (e.g., "You are #3 of 12")

### 9.3 Engagement Summary Endpoint

`GET /engagements/{id}/summary` returns:

```json
{
  "engagement_id": "...",
  "name": "Spring 2026 — UAB",
  "status": "active",
  "case_count": 50,
  "cases_reviewed": 32,
  "cases_remaining": 18,
  "review_completion_pct": 64.0,
  "avg_review_time_hours": 2.4,
  "classification_distribution": { "fraud": 28, "legitimate": 4 },
  "top_classifications": ["pig_butchering", "romance_scam", "investment_fraud"],
  "analyst_count": 8,
  "days_remaining": 14,
  "days_elapsed": 28
}
```

---

## 10. Build vs. Looker Decision

Two distinct needs exist. The right answer is **both**, stratified by use case:

| Need                                                                                            | Solution | Rationale                                                                             |
| ----------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------- |
| **Operational scoping** (students see only their cases)                                         | Built-in | Looker cannot filter the API/UI at runtime. This is a UX + data-integrity concern.    |
| **Real-time engagement dashboard** (progress, leaderboard)                                      | Built-in | Must update as students work. Looker refresh latency (minutes–hours) is insufficient. |
| **Post-hoc cross-engagement analytics** (semester-over-semester trends, university comparisons) | Looker   | Ad-hoc, infrequent, exploratory. BigQuery + Looker is the right tool.                 |
| **Executive reporting** (board-level impact metrics across all engagements)                     | Looker   | Custom visualizations, PDF export, scheduling — Looker's strength.                    |

**Phase 1 builds the operational scoping and real-time dashboard.** The Looker path is
enabled "for free" once `engagement_id` exists on cases — the BigQuery export (already
planned in the TIFAP TDD Section 2.3) carries the engagement dimension into the warehouse.

---

## 11. Phased Delivery

### Phase 1: Data Model + API + Scoping (1 sprint)

**Deliverables:**

- `engagements` table + Alembic migration
- `engagement_id` FK on `cases`
- Engagement CRUD API (`/engagements/*`)
- Bulk case assignment endpoint
- `X-Engagement-Id` middleware + filter injection in `ReviewStore`, `HybridSearchQuery`
- Engagement-aware ingestion (optional `engagement_id` param on ingest jobs)
- Unit tests for all new endpoints and filter injection paths
- Backfill script: set `engagement_id` on historical cases based on `ingestion_batch_id`
  or date ranges (one-time migration helper)

**Exit criteria:** A developer can create an engagement, assign cases, and verify that API
queries scoped by `X-Engagement-Id` return only the correct subset. Unscoped queries
continue to return all cases.

### Phase 2: UI + Real-Time Dashboard (1 sprint)

**Deliverables:**

- Engagement selector component in top nav
- `sessionStorage` persistence + SDK request interceptor
- Engagement management page (`/settings/engagements`)
- Engagement-scoped dashboard KPIs
- Engagement summary card on dashboard home
- Deep link support (`?engagement=`)
- Edge case handling (no engagement, completed engagement, mid-switch)

**Exit criteria:** A student analyst can log in, select their engagement, and navigate
the entire console seeing only their engagement's cases. A manager can create an
engagement, assign cases, and monitor progress.

### Phase 3: Analytics + Leaderboard (1 sprint — can be deferred)

**Deliverables:**

- `engagement_analyst_stats` table + aggregation job extension
- `GET /engagements/{id}/leaderboard` endpoint
- `GET /engagements/{id}/summary` endpoint (extended analytics)
- Leaderboard UI component
- Per-engagement analytics export (PDF/CSV)
- Engagement comparison view for managers (side-by-side stats)

**Exit criteria:** At the end of a competition, a manager can view a ranked leaderboard,
export a summary PDF, and compare engagement results across semesters.

### Phase 4: Looker + Cross-Engagement Intelligence (future)

**Deliverables:**

- BigQuery export includes `engagement_id` dimension
- Looker dashboard templates for cross-engagement analytics
- Semester-over-semester trend analysis
- University partnership comparison reports

**Exit criteria:** Executive stakeholders can view cross-engagement KPIs in Looker without
engineering involvement.

---

## 12. Success Metrics

### Platform Adoption

| Metric                        | Phase 1 Target         | Phase 2 Target                          |
| ----------------------------- | ---------------------- | --------------------------------------- |
| Engagements created           | ≥ 1 (validation)       | ≥ 3 (multi-university)                  |
| Cases assigned to engagements | 100% of new ingestions | 100% of new + 80% of historical         |
| Engagement selector usage     | N/A (no UI yet)        | 90% of student sessions use scoped mode |

### Data Quality

| Metric                                             | Target                   |
| -------------------------------------------------- | ------------------------ |
| Cases with `engagement_id` populated               | > 95% of active cases    |
| Engagement lifecycle transitions logged            | 100% (audit trail)       |
| Stale engagement detection (active past `ends_at`) | Auto-detected within 24h |

### Educational Impact

| Metric                                     | Target                             |
| ------------------------------------------ | ---------------------------------- |
| Time to generate competition report        | < 5 min (vs. hours of manual SQL)  |
| Student confusion reports (wrong case set) | → 0 after Phase 2                  |
| Manager adoption of leaderboard            | ≥ 80% of active engagements use it |

### Operational Efficiency

| Metric                                | Target                                |
| ------------------------------------- | ------------------------------------- |
| Query overhead from engagement filter | < 5% latency increase                 |
| New university onboarding time        | < 1 hour (create engagement + ingest) |

---

## 13. Risks & Mitigations

| Risk                                                                      | Likelihood | Impact                               | Mitigation                                                                                                                                               |
| ------------------------------------------------------------------------- | ---------- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Filter injection bugs — engagement filter missed on some query paths      | Medium     | High — students see wrong cases      | Test matrix: every case-returning endpoint × scoped/unscoped. Integration test suite validates no data leakage.                                          |
| Aggregation job performance — per-engagement passes multiply compute time | Low        | Medium — analytics lag               | O(active engagements) is bounded (<20). Add circuit breaker: skip engagement breakdown if > 50 active engagements.                                       |
| M:N demand emerges — cases need to be in multiple engagements             | Low        | Medium — requires schema migration   | 1:N is sufficient for known use cases. If M:N needed, migrate to junction table. API contract (`engagement_id` on case) can alias to primary engagement. |
| Manager creates too many engagements, polluting the selector              | Low        | Low — UX clutter                     | Auto-archive completed engagements after 90 days. Separate "active" vs. "past" sections in dropdown.                                                     |
| Engagement scoping mistaken for security boundary                         | Medium     | High — false sense of data isolation | Documentation, UI copy, and API docs explicitly state: "Engagement scoping is a convenience filter, not an access control boundary."                     |

---

## 14. Open Questions

1. **Should engagement assignment be required for new cases?** Phase 1 makes it optional
   (`engagement_id` is nullable). Should Phase 2 enforce that all new ingestions specify an
   engagement? This depends on whether non-competition use cases (e.g., LEA direct intake)
   should operate without engagement context.

2. **Auto-complete lifecycle transitions.** Should the system automatically move `active →
completed` when `ends_at` passes? Or should this always require manager action? The
   risk of auto-completion is interrupting a competition that ran over schedule.

3. **Cross-engagement entity/indicator views.** When viewing an entity in Intelligence,
   should the engagement filter apply? An entity (e.g., a domain) may appear across many
   engagements. Scoping Intelligence views to an engagement could hide important
   cross-engagement intelligence. Recommendation: Intelligence views default to "All
   Engagements" regardless of selector state, with a toggle to scope.

4. **Ground truth for accuracy scoring.** The leaderboard requires "classification
   accuracy," which implies a ground truth. Options: (a) manager-provided answer key,
   (b) consensus of multiple reviewers, (c) post-engagement expert adjudication. This is a
   Phase 3 design decision.

5. **Engagement-level permissions.** Should managers be scoped to only their own
   engagements, or can any manager see all engagements? For multi-university deployment,
   managers should probably only manage their own institution's engagements. This may
   require an `engagement_members` junction table — evaluate in Phase 2.

---

## 15. Technical References

| Document                                                                    | Path                                                             |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Threat Intelligence Analytics TDD (campaign model, aggregation pipeline)    | `core/docs/design/threat_intelligence_analytics_tdd.md`          |
| Threat Intelligence Analytics PRD (ingestion batch vs. campaign separation) | `planning/prd_threat_intelligence_analytics.md` Section 7        |
| Production PRD (university partnerships, FERPA, graduate students)          | `planning/prd_production.md` Sections 3, 11                      |
| Data model (SQLAlchemy table definitions)                                   | `core/src/i4g/store/sql.py`                                      |
| Review store (filter injection point)                                       | `core/src/i4g/store/review_store.py`                             |
| Hybrid search (query filter extension point)                                | `core/src/i4g/services/hybrid_search.py`                         |
| API roles (role hierarchy)                                                  | `core/src/i4g/api/roles.py`                                      |
| Architecture cheatsheet                                                     | `copilot/.github/shared/architecture-cheatsheet.instructions.md` |
