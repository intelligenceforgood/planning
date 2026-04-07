# Engagements Phase 2 — UI + Real-Time Dashboard

> **PRD:** `planning/prd_engagements.md` (Phase 2, Section 11)
> **Prerequisite:** Phase 1 complete (`planning/tasks/engagements_phase1.md` — all 12 steps done)
> **Sprint target:** Phase 2 (UI — engagement selector, management page, scoped dashboard)
> **Started:** 2026-04-07

---

## Architecture Decisions

### Engagement persistence: cookie + sessionStorage hybrid

The PRD specifies `sessionStorage` (tab-scoped). However, Next.js server components cannot
read `sessionStorage`. To avoid converting all dashboard/case pages to client components:

- **Cookie (`i4g-engagement-id`)** stores the selected engagement ID — readable server-side
  via `cookies()` and automatically sent with every request to the Next.js proxy.
- **React context (`EngagementProvider`)** provides client-side reactivity and syncs the
  cookie on selection change.
- **URL query param (`?engagement=<id>`)** overrides cookie for deep links.
- The Next.js catch-all proxy reads the cookie and injects `X-Engagement-Id` header before
  forwarding to Core. No SDK interceptor changes needed.

### `manager` role in UI

Phase 1 added `manager` to the Core backend role hierarchy. The UI `UserRole` type and
`ROLE_HIERARCHY` need updating to match (Step 1).

---

## Tasks

- [x] **Step 1 — Add `manager` role to UI auth context** (`ui/apps/web/src/lib/auth-context.tsx`)
  - Add `"manager"` to `UserRole` union type (between `analyst` and `leo`)
  - Update `ROLE_HIERARCHY` to match backend: manager inherits analyst, user, researcher
  - Update `leo` and `admin` sets to include manager
  - Verify existing role checks still pass (`pnpm build`)

- [x] **Step 2 — Add engagement TypeScript types** (`ui/packages/sdk/src/`)
  - Define types matching Core Pydantic models:
    - `Engagement` (matches `EngagementResponse`: camelCase fields)
    - `EngagementCreate`, `EngagementUpdate`
    - `EngagementSummary` (extends Engagement with case_count, progress fields)
    - `CaseAssignment`, `CaseAssignmentResult`
  - Export from SDK package

- [x] **Step 3 — Add engagement client methods to SDK** (`ui/packages/sdk/src/`)
  - `listEngagements(params?: { status?: string })` → `GET /engagements`
  - `getEngagement(id: string)` → `GET /engagements/{id}`
  - `createEngagement(data: EngagementCreate)` → `POST /engagements`
  - `updateEngagement(id: string, data: EngagementUpdate)` → `PATCH /engagements/{id}`
  - `deleteEngagement(id: string)` → `DELETE /engagements/{id}`
  - `assignCases(id: string, caseIds: string[])` → `POST /engagements/{id}/cases`
  - `removeCases(id: string, caseIds: string[])` → `DELETE /engagements/{id}/cases`
  - `getEngagementSummary(id: string)` → `GET /engagements/{id}/summary`

- [x] **Step 4 — Engagement cookie + proxy header injection** (`ui/apps/web/`)
  - Create `lib/engagement-cookie.ts`: helpers to get/set/clear the `i4g-engagement-id` cookie
  - Modify catch-all proxy (`app/api/[...path]/route.ts`): read cookie, inject
    `X-Engagement-Id` header before forwarding to Core
  - Also handle dedicated proxy routes if any forward to Core (search, reviews, etc.)

- [x] **Step 5 — EngagementProvider context + useEngagement hook** (`ui/apps/web/src/lib/`)
  - Create `engagement-context.tsx`:
    - `EngagementProvider` — wraps console layout, fetches engagements list on mount
    - `useEngagement()` hook — returns `{ engagement, engagements, select, clear, loading }`
    - On selection: update cookie + trigger router refresh (server components re-fetch)
    - On mount: check URL `?engagement=` param → cookie → auto-select single active
  - Provider placed in `(console)/layout.tsx` inside `AuthProvider`

- [x] **Step 6 — Engagement selector component** (`ui/apps/web/src/components/engagement-selector.tsx`)
  - Dropdown button in header area showing current engagement name
  - Sections: "Active" engagements, "Past" (completed) with read-only badge
  - "All Engagements" option visible only to manager+ and admin
  - "Manage Engagements" link for manager+ role
  - Uses `useEngagement()` hook from context
  - Follows existing Tailwind + Radix popover pattern from ui-kit

- [x] **Step 7 — Wire selector into console layout** (`ui/apps/web/src/app/(console)/layout.tsx`)
  - Add `EngagementProvider` to layout wrapper chain
  - Place `EngagementSelector` in the header area above `<main>` content
  - Pass server-side engagement list as initial data to avoid loading flash

- [x] **Step 8 — Engagement management page** (`ui/apps/web/src/app/(console)/admin/engagements/`)
  - `page.tsx` — list all engagements (table with status, dates, case count)
  - Create engagement form (name, description, starts_at, ends_at)
  - Edit engagement (inline or modal)
  - Lifecycle transitions: Activate, Complete, Archive (buttons per status)
  - Bulk case assignment: text input for case IDs or filter-and-assign
  - Role guard: manager+ for full access
  - Follow existing admin page patterns (`admin/users/`)

- [x] **Step 9 — Add "Engagements" to navigation** (`ui/apps/web/src/app/(console)/navigation.tsx`)
  - Add nav item: `{ href: "/admin/engagements", label: "Engagements", minRole: "manager" }`
  - Place in appropriate section (top-level or under a "Manage" group)

- [x] **Step 10 — Dashboard engagement summary card** (`ui/apps/web/src/app/(console)/dashboard/`)
  - When engagement is scoped: show summary card at top of dashboard
    - Engagement name, status badge, date range, days remaining
    - Progress bar: cases reviewed / total
    - Classification distribution mini-chart
    - Analyst count
  - Fetch from `GET /engagements/{id}/summary`
  - When "All Engagements" or no engagement: hide the card

- [x] **Step 11 — Deep link support** (multiple files)
  - Read `?engagement=<id>` from URL in `EngagementProvider` on mount
  - If present: validate engagement exists, select it, update cookie
  - Include `?engagement=<id>` in shareable links (case detail, search results)
  - When user switches engagement: update URL query param via `router.replace()`

- [x] **Step 12 — Edge case handling** (multiple files)
  - **No active engagements:** Show onboarding prompt for analyst role
    ("No active engagements. Contact your manager.")
  - **Completed engagement selected:** Show banner "This engagement has ended. Data is
    read-only." Disable review submission buttons.
  - **Mid-switch warning:** If user has unsaved form data when switching engagement,
    show "Discard changes?" confirmation dialog.
  - **Cross-engagement deep link:** If case belongs to different engagement than selected,
    show info badge: "This case belongs to [Other Engagement]."

- [x] **Step 13 — Quality gate**
  - `pnpm format` (Prettier)
  - `pnpm lint` (ESLint)
  - `pnpm build` (full build — catches type errors)
  - `pnpm test` (unit tests)
  - Manual smoke test: selector → dashboard scoping → management page → deep links

---

## Exit Criteria

From PRD Section 11, Phase 2:

> A student analyst can log in, select their engagement, and navigate the entire console
> seeing only their engagement's cases. A manager can create an engagement, assign
> cases, and monitor progress.

Verify:

1. Student sees engagement selector defaulted to their active engagement
2. Dashboard KPIs, search results, case lists are all scoped
3. Manager can create/edit/activate engagements from management page
4. Manager can bulk-assign cases to an engagement
5. Deep links with `?engagement=<id>` work correctly
6. "All Engagements" mode works for manager+ roles
7. Completed engagement shows read-only banner

---

## Risks

| Risk                                                                | Mitigation                                                                                 |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Cookie-based engagement ID diverges from sessionStorage PRD spec    | Cookie is functionally equivalent + works with server components. Document decision above. |
| `manager` role addition breaks existing UI role checks              | Backward-compatible hierarchy: manager subsumes analyst. `pnpm build` catches type errors. |
| Engagement selector adds layout shift on page load                  | Server-side fetch engagement list; pass as prop to avoid hydration flash.                  |
| Proxy header injection missed on dedicated routes (search, reviews) | Audit all Next.js API routes that forward to Core; add header injection to each.           |
| Large engagement list makes dropdown unusable                       | Cap at 20 active + search/filter for past. Pagination on management page.                  |

---

## Dependencies

| What                                         | Where                               | Status         |
| -------------------------------------------- | ----------------------------------- | -------------- |
| `engagements` CRUD API                       | Core `/engagements/*`               | Done (Phase 1) |
| `X-Engagement-Id` middleware                 | Core `api/middleware/engagement.py` | Done (Phase 1) |
| Filter injection (ReviewStore, HybridSearch) | Core stores/services                | Done (Phase 1) |
| Engagement-aware dashboard endpoints         | Core `api/dashboard.py`             | Done (Phase 1) |
| Engagement-aware ingestion                   | Core worker/ingest                  | Done (Phase 1) |
