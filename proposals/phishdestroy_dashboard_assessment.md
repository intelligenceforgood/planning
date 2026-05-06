# PhishDestroy Dashboard Integration Assessment

**Date:** 2026-05-06
**Context:** Feasibility and engineering effort assessment for adopting the PhishDestroy Threat Intelligence Dashboard (`DestroyScammers/index.html`) into the I4G project.

---

## 1. Data Schema Feasibility

**Assessment:** **Sufficient.** 
The database schema in `i4g/core/src/i4g/store` fully supports all charts, tables, and graphs present in the PhishDestroy dashboard. The backend data integration plan (`prd_phishdestroy_integration.md`) has been successfully mapped and implemented via additive schema tables.

**Schema Mapping:**
- **Dashboard Stats (Actors, Domains, Registrars):** Covered by `threat_actor_store` and `domain_discovery_store`.
- **Relationship Graph (Nodes & Links):** Supported by `actor_identities` (nodes) and `actor_identity_edges` (links) via `actor_identity_store.py` and `actor_identity_edge_store.py`.
- **Threat Actors Table:** Hydrated via `threat_actor_store.py` along with `financial_damage_store.py` for theft ledgers.
- **Active Threats (Malware/Phishing/Brand Pills):** Captured via `blocklist_hit_store.py` and `brand_impersonation_store.py`.

---

## 2. UI Engineering Efforts (Native React App)

**Assessment:** **Moderate to High Effort**
The `ui` repository is a modern React 19 monorepo managed by Turborepo (`pnpm workspace`). The original PhishDestroy dashboard is built using vanilla HTML, raw CSS, and `d3.js` for graph rendering.

**Key Engineering Tasks:**
1. **Component Translation:** Converting raw HTML/CSS into reusable React components within the `@i4g/ui-kit` library.
2. **API Integration:** Building intermediate API routes (or tRPC endpoints) to serve data from the Python core `store` to the frontend React components. 
3. **Graph Rendering:** Wrapping the `d3.js` relationship graph logic inside React `useEffect` hooks to ensure it plays nicely with React's DOM rendering lifecycle, or replacing it with a React-native graph library (e.g., React Flow).

---

## 3. Layout Strategy: Tabs vs. Collapsible Sections

**Recommendation:** **Tabs (Sub-routing)**

The original dashboard relies on a sidebar that mimics tabbed navigation. Since this dashboard contains dense data grids and a computationally heavy force-directed graph, a single long page with collapsible sections is discouraged.

**Why Tabs?**
- **Performance:** Rendering massive D3 DOM nodes alongside heavy data tables in a single view can cause significant lag. Tabs allow React to unmount the D3 canvas when viewing tables, freeing up browser memory.
- **Deep Linking:** Implementing tabs as native route groups (e.g., `/threat-intel`, `/threat-intel/graph`, `/threat-intel/actors`) enables analysts to share direct links to specific views.

---

## 4. Evaluation of the Looker Alternative

**Recommendation:** **Build natively in the I4G UI.**

While Looker is exceptional for deep historical analytics and BigQuery data aggregations, it is the wrong tool for this specific dashboard for three reasons:

1. **Operational Nature:** The PhishDestroy dashboard is an *operational* pane. Analysts need to investigate specific actors and interact with live discovery feeds. Looker is designed for high-level BI reporting, not entity-level triage.
2. **Interactive Visualizations:** The core feature of the dashboard is the interactive Threat Actor Relationship Graph. Looker is highly restrictive when it comes to custom, interactive, force-directed network graphs.
3. **Workflow Actions:** As noted in the PRD, the real-time discovery feed (`domain_discoveries`) requires analysts to take actions like "enqueue passive scan". Implementing write-back operational workflows in Looker is cumbersome and creates a disjointed user experience. 

If deep historical analysis of threat trends over years is later required, a separate Looker dashboard can be created, but the primary investigative dashboard must remain in the native React app.
