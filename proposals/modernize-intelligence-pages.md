# Implementation Plan: Modernize Intelligence Pages

## Objective
Update the `Intelligence` navigation group within the I4G Analyst Console (`ui`) to better utilize the latest backend (`core`) capabilities. The focus is on improving data visualization, adding temporal graph analysis, enabling bulk entity management, and allowing actionable campaign management.

## Key Files & Context
- **UI Pages (`apps/web/src/app/(console)/intelligence/`):**
  - `page.tsx` (Dashboard)
  - `graph/network-graph.tsx` & `graph/page.tsx`
  - `entities/entity-explorer.tsx` & `entities/entity-detail-panel.tsx`
  - `campaigns/[id]/page.tsx` & `campaigns/page.tsx`
- **Backend API Routes (`core/src/i4g/api/intelligence.py`):**
  - `/dashboard`
  - `/charts/share`, `/charts/{token_id}/embed`
  - `/graph/temporal`, `/graph/clusters`
  - `/entities/bulk`, `/entities/status`
  - `/campaigns/{campaign_id}/manage`

## Implementation Steps

### Phase 1: Intelligence Dashboard Enhancements
1.  **Refactor Loss Trend Visualization:**
    -   Modify `apps/web/src/app/(console)/intelligence/page.tsx` to render a `Recharts` sparkline or area chart for the `lossTrend` data, replacing the static single-value display.
2.  **Implement Chart Sharing:**
    -   Add a "Share" button to the dashboard header or individual widget cards.
    -   Create a client-side function to hit the `/api/intelligence/charts/share` endpoint and display the resulting `/api/intelligence/charts/{token_id}/embed` link in a toast or modal.

### Phase 2: Advanced Graph Analytics
1.  **Temporal Analysis Slider:**
    -   In `apps/web/src/app/(console)/intelligence/graph/network-graph.tsx`, introduce a timeline slider component.
    -   Wire the slider to fetch data from `/api/intelligence/graph/temporal` and dynamically update the visible nodes and edges in the graph based on the selected timeframe.
2.  **Cluster Highlighting:**
    -   Add a "Detected Clusters" sidebar to the network graph view.
    -   Fetch data from `/api/intelligence/graph/clusters` and allow users to click a cluster in the sidebar to highlight the corresponding nodes in the main graph view.

### Phase 3: Entity and Campaign Management
1.  **Bulk Entity Operations:**
    -   Update the grid in `apps/web/src/app/(console)/intelligence/entities/entity-explorer.tsx` to include checkbox selection.
    -   Implement a bulk action bar (e.g., "Change Status", "Add to Watchlist") that calls the `/api/intelligence/entities/bulk` endpoint.
2.  **Entity Status Toggling:**
    -   In `apps/web/src/app/(console)/intelligence/entities/entity-detail-panel.tsx`, add a dropdown or toggle switch to manually update the entity status using the `/api/intelligence/entities/status` endpoint.
3.  **Campaign Management Modal:**
    -   In `apps/web/src/app/(console)/intelligence/campaigns/[id]/page.tsx`, add a "Manage Campaign" button.
    -   Implement a modal or slide-over that allows users to edit campaign details (status, severity, etc.) and submit changes via the `/api/intelligence/campaigns/{campaign_id}/manage` endpoint.

## Verification & Testing
-   **Dashboard:** Verify that the loss trend chart renders correctly with historical data and that the sharing links generate valid, embeddable URLs.
-   **Graph:** Test the temporal slider to ensure nodes appear/disappear smoothly based on timestamps. Verify that cluster selection accurately highlights groups within the network graph.
-   **Management:** Test bulk entity selection and action submission. Verify that single entity status updates reflect immediately in the UI. Ensure the campaign management modal correctly persists changes to the backend.
