**Objective:** Revamp the Analyst Console Dashboard to leverage new backend analytics, threat campaigns, and engagement-scoped metrics, providing a more informative, actionable, and aesthetically pleasing landing experience.

### 1. Milestones

- **Phase 1: Backend & Data Contract** - Ensure `GET /dashboard/overview` and related endpoints expose the latest aggregated metrics (campaign risk scores, engagement completion %, loss linkages).
- **Phase 2: UI Components & SDK** - Update SDK types and build modern, responsive UI components (e.g., KPI sparkline cards, engagement progress rings).
- **Phase 3: Integration & Testing** - Wire the new components to the dashboard page, replacing the stale text, and verify rendering and engagement scoping with tests.

### 2. Task Checklist

- [x] Step 1: Extend backend dashboard endpoint to return campaign alerts, engagement completion %, and loss linkages.
  - `@file:core/src/i4g/api/dashboard.py`
  - `@file:core/src/i4g/api/response_models.py`

- [ ] Step 2: Update UI SDK types to reflect the expanded dashboard payload and remove any remaining `.passthrough()` schemas.
  - `@file:ui/packages/sdk/src/domain.ts`
  - `@folder:ui/packages/sdk/src/schemas/`

- [ ] Step 3: Create responsive KPI Sparkline Cards and Engagement Progress components utilizing the updated design tokens.
  - `@folder:ui/packages/ui-kit/src/components/`
  - `@file:ui/apps/web/src/components/dashboard-kpi-cards.tsx`

- [ ] Step 4: Redesign the main dashboard page layout to replace stale text with interactive metrics, alerts, and recent activity feeds.
  - `@file:ui/apps/web/src/app/(console)/dashboard/page.tsx`
  - `@file:ui/apps/web/src/app/(console)/dashboard/loading.tsx`

- [ ] Step 5: Update unit and Playwright smoke tests to verify the new dashboard rendering and engagement-scoping logic.
  - `@file:ui/apps/web/tests/smoke/dashboard.spec.ts`
  - `@file:ui/apps/web/tests/unit/dashboard.test.tsx`
