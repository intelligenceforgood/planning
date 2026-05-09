**Objective:** Update the `Intelligence` navigation group within the I4G Analyst Console to better utilize the latest backend capabilities.

### 1. Milestones

- **Phase 1: Dashboard Enhancements** (Frontend + API Verification)
- **Phase 2: Advanced Graph Analytics** (Frontend + API Verification)
- **Phase 3: Entity and Campaign Management** (Frontend + API Verification)

### 2. Task Checklist

- [x] Step 1: **Dashboard - Loss Trend Visualization**
  Refactor Loss Trend Visualization to render a `Recharts` sparkline or area chart for the `lossTrend` data, replacing the static single-value display.
  @file:ui/apps/web/src/app/(console)/intelligence/page.tsx

- [x] Step 2: **Dashboard - Chart Sharing**
  Add a "Share" button to the dashboard header or individual widget cards and implement client-side logic to use `/api/intelligence/charts/share` and display `/api/intelligence/charts/{token_id}/embed` link.
  @file:ui/apps/web/src/app/(console)/intelligence/page.tsx
  @file:core/src/i4g/api/intelligence.py

- [x] Step 3: **Graph Analytics - Temporal Analysis Slider**
  Introduce a timeline slider component and wire it to fetch data from `/api/intelligence/graph/temporal` to dynamically update visible nodes/edges.
  @file:ui/apps/web/src/app/(console)/intelligence/graph/network-graph.tsx
  @file:core/src/i4g/api/intelligence.py

- [x] Step 4: **Graph Analytics - Cluster Highlighting**
  Add a "Detected Clusters" sidebar and fetch data from `/api/intelligence/graph/clusters` allowing users to highlight corresponding nodes.
  @file:ui/apps/web/src/app/(console)/intelligence/graph/page.tsx
  @file:ui/apps/web/src/app/(console)/intelligence/graph/network-graph.tsx
  @file:core/src/i4g/api/intelligence.py

- [x] Step 5: **Entity Management - Bulk Entity Operations**
  Update the entity explorer grid to include checkbox selection and implement a bulk action bar that calls `/api/intelligence/entities/bulk`.
  @file:ui/apps/web/src/app/(console)/intelligence/entities/entity-explorer.tsx
  @file:core/src/i4g/api/intelligence.py

- [x] Step 6: **Entity Management - Entity Status Toggling**
  Add a dropdown or toggle switch to manually update entity status using the `/api/intelligence/entities/status` endpoint.
  @file:ui/apps/web/src/app/(console)/intelligence/entities/entity-detail-panel.tsx
  @file:core/src/i4g/api/intelligence.py

- [x] Step 7: **Campaign Management Modal**
  Add a "Manage Campaign" button and implement a modal/slide-over to edit campaign details, submitting changes via `/api/intelligence/campaigns/{campaign_id}/manage`.
  @file:ui/apps/web/src/app/(console)/intelligence/campaigns/[id]/page.tsx
  @file:core/src/i4g/api/intelligence.py
