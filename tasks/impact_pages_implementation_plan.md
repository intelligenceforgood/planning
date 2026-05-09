# Impact Pages Modernization Implementation Plan

Based on the review of the current UI implementation (`ui/apps/web/src/app/(console)/impact/*`) and the backend API capabilities (`core/src/i4g/api/impact.py`), there is a significant gap between the rich data the backend provides and what is currently visualized.

Here is the proposed implementation plan to modernize the Impact pages.

## Executive Summary of Gaps

1. **Missing Capabilities:** The backend exposes a `/impact/victims` endpoint providing detailed demographic breakdowns (age, contact channel, country) that is entirely absent from the UI.
2. **Primitive Visualizations:** The `TaxonomyExplorer` relies on basic HTML structures (e.g., `div`-based sparklines, HTML `table` heatmaps, and a simple list for the Sankey flow).
3. **Suboptimal Charting:** `ImpactCharts` uses a basic vertical BarChart for "Loss by Taxonomy", despite the intention to have a hierarchical "treemap-style" view.
4. **Geographic Representation:** The `GeographyView` uses a standard list UI instead of an actual map, limiting the visual impact of global threat data.

---

## Phase 1: Dashboard & Analytics Overhaul (`/impact`)

- [x] **1. Surface Victim Demographics:**

* **Backend:** Ensure `/impact/victims` is fully documented in the SDK.
* **Frontend Data Fetching:** Update `getI4GClient()` in the UI to fetch `getVictimAnalytics()`.
* **Component (`page.tsx`):** Create a new `VictimDemographics` section below the KPI cards. Use Recharts' `PieChart` or `RadialBarChart` to display the distribution of victim Age Ranges, Contact Channels, and top Countries.

- [x] **2. Upgrade the Loss by Taxonomy Chart:**

* **Component (`impact-charts.tsx`):** The current implementation uses a vertical `BarChart`. Refactor this to use the actual `Treemap` component from Recharts. This provides a much better visual hierarchy of which taxonomy categories cause the most financial damage.

## Phase 2: Taxonomy Explorer Modernization (`/impact/taxonomy-explorer`)

The current `taxonomy-explorer.tsx` relies heavily on standard DOM elements. We will replace these with proper charting implementations.

- [x] **1. True Sankey Flow Diagram:**

* **Action:** Deprecate the two-column HTML list in `SankeyView`.
* **Implementation:** Utilize the Recharts `Sankey` component. Map the backend `nodes` and `links` directly into the Sankey component to visually demonstrate how high-level categories flow into specific subcategories.

- [x] **2. Interactive Heatmap:**

* **Action:** Replace the standard HTML `<table>` in `HeatmapView`.
* **Implementation:** Build a robust SVG-based Heatmap (or use `ScatterChart` in Recharts). Incorporate standard tooltips (`<Tooltip />`) so users can hover over a block to see the exact time period, category, and case volume, rather than relying on the native `title` attribute.

- [x] **3. Advanced Trend Analysis:**

* **Action:** Remove the `div`-based sparklines in `TrendView`.
* **Implementation:** Implement a multi-series `LineChart` or `AreaChart` from Recharts. Add an interactive legend allowing the analyst to toggle specific taxonomy categories on/off to compare historical trends clearly.

## Phase 3: Geography View Enhancement (`/impact/geography`)

- [x] **1. Visual Map Integration:**

* **Action:** The current `GeographyView` is a text list sorted by case volume.
* **Implementation:** Introduce an interactive SVG world map (e.g., using `react-simple-maps` or a custom D3/SVG projection) as the primary focal point. Color-code (Choropleth) the countries based on the `case_count` or `total_loss` from the `GeographySummary` API.

- [x] **2. Richer Drill-Down Context:**

* **Action:** Enhance the right-hand slide-over panel.
* **Implementation:** When an analyst clicks a country (either on the new map or the list), display not only the individual case records but also the aggregate victim metrics (`victim_count` is already returned by the `/impact/geography` endpoint).

## Phase 4: Architecture & Data Fetching Refactor

- [x] **1. Shift to Server-Side Fetching (Where Applicable):**

* **Action:** Both `GeographyView` and `TaxonomyExplorer` currently use `useEffect` for data fetching, resulting in client-side loading spinners.
* **Implementation:** Transition these to React Server Components (fetching data at the page level) similar to how `ImpactPage` currently operates, passing the initial payload as props. Use client-side fetching only when the user changes filters (e.g., changing the time period from `90d` to `30d`).

- [x] **2. Navigation Consolidation:**

* **Action:** Evaluate `/impact/taxonomy/page.tsx` (currently just exporting the explorer) and consolidate the navigation menu if "Taxonomy" and "Taxonomy Explorer" point to redundant experiences.
