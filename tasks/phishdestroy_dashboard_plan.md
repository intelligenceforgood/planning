# Plan: PhishDestroy Dashboard Integration

**Objective:** Implement the PhishDestroy Threat Intelligence Dashboard natively in the I4G React UI monorepo. This involves migrating from the original vanilla HTML/D3.js dashboard (`DestroyScammers/index.html`) to native React components, and wiring them to the I4G core backend stores. This plan is designed to be fully self-contained so the implementation team will not need access to the `phishdestroy/ScamIntelLogs` or `phishdestroy/DestroyScammers` repositories.

### Scope & Extraction Note
All necessary context from the external `ScamIntelLogs` and `DestroyScammers` repositories has been extracted into this plan. The UI will strictly consume from the I4G core API, meaning the frontend team only needs to know the shape of the I4G API responses and the required visual components (Stats, Tables, Graph), which are detailed below.

### 1. Milestones
*   **Phase 1: Backend API Endpoints** (Expose I4G core stores to the frontend)
*   **Phase 2: UI Kit Components** (Translate raw HTML/CSS into React components)
*   **Phase 3: UI Dashboard Routing & Integration** (Build the tabbed pages and wire to the API)

### 2. Task Checklist

**Phase 1: Backend API**
- [x] **Step 1:** Create an API router for Dashboard Stats. Must aggregate data from `threat_actor_store` and `domain_discovery_store` (e.g., total actors, active domains, registrars).
  - **Files:** `@folder:i4g/core/src/i4g/api/` (new router file, e.g., `dashboard_router.py`)
- [x] **Step 2:** Create an API router for Threat Actors & Active Threats lists. Combine data from `threat_actor_store`, `financial_damage_store`, `blocklist_hit_store`, and `brand_impersonation_store`.
  - **Files:** `@folder:i4g/core/src/i4g/api/` 
- [x] **Step 3:** Create an API router for the Relationship Graph. Must return a JSON structure with `nodes` (from `actor_identities`) and `links` (from `actor_identity_edges`).
  - **Files:** `@folder:i4g/core/src/i4g/api/`

**Phase 2: UI Kit Components**
- [ ] **Step 4:** Build React Stats Card components (to display Total Actors, Active Domains, etc.).
  - **Files:** `@folder:i4g/ui/packages/ui-kit/src/components/stats/`
- [ ] **Step 5:** Build React Data Table components for "Threat Actors" and "Active Threats". Columns needed: Actor Name, Aliases, Target Brands, Associated Domains, Financial Damage.
  - **Files:** `@folder:i4g/ui/packages/ui-kit/src/components/tables/`
- [ ] **Step 6:** Build the Relationship Graph component. Wrap `d3.js` in a `useEffect` hook or implement using React Flow to render the `nodes` and `links` from the API.
  - **Files:** `@folder:i4g/ui/packages/ui-kit/src/components/graph/`

**Phase 3: UI Dashboard Integration**
- [ ] **Step 7:** Implement the sub-routed layout based on the assessment recommendation. Create native route groups for tabs: `/threat-intel` (Overview), `/threat-intel/graph` (Network Graph), `/threat-intel/actors` (Actor Table).
  - **Files:** `@folder:i4g/ui/apps/web/app/(dashboard)/threat-intel/`
- [ ] **Step 8:** Integrate API data fetching (via tRPC or React Query) into the new page routes to hydrate the UI components.
  - **Files:** `@folder:i4g/ui/apps/web/app/(dashboard)/threat-intel/`

### 3. Required Data Schemas (Extracted Context)
To prevent the need to view the original logs, here is the necessary UI data shape mapping:
*   **Graph Data:** Needs `{ "nodes": [{ "id": string, "group": number, "label": string }], "links": [{ "source": string, "target": string, "value": number }] }`.
*   **Actor Table:** Needs `[ { "name": string, "aliases": string[], "stolen_amount": number, "domains": string[], "status": "active" | "inactive" } ]`.
