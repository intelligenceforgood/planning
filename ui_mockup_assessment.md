# UI Mockup Assessment & Backend Integration Status

*Date: January 10, 2026*

Based on an assessment of the `ui/` repository and its interaction with the `core/` backend, the following pages have been identified as mockups or incomplete, ranked by the effort required to connect them to the backend independently.

## 1. Taxonomy Page (Low Effort)
*   **Path**: `ui/apps/web/src/app/(console)/taxonomy/page.tsx`
*   **Status**: **Pure Mockup / Static**.
    *   The page currently imports static Enums directly from `@i4g/types` (e.g., `ScamIntentDescriptions`) and renders them. It does **not** attempt to fetch data from the backend.
    *   The backend **already supports** this feature:
        *   Endpoint: `/taxonomy` (defined in `core/src/i4g/api/taxonomy.py`).
        *   Frontend Service: `ui/apps/web/src/lib/server/taxonomy-service.ts` already implements `getTaxonomyTree()`, which is used by the *New Campaign* form but ignored by the main Taxonomy page.
*   **Effort to Hook Up**:
    1.  Update `TaxonomyPage` to be an async Server Component.
    2.  Call `getTaxonomyTree()` (already implemented).
    3.  Refactor the page to render the dynamic tree structure returned by the API instead of the hardcoded static Enums.

## 2. Case Workspace / Detail View (High Effort)
*   **Path**: Missing (Implied by `ui/apps/web/src/app/(console)/cases/page.tsx`)
*   **Status**: **Placeholder UI / Missing Page**.
    *   The *Case List* page works and fetches data. However, the **"Open workspace"** button for each case is a dead placeholder (`type="button"` with no `onClick` or `href`).
    *   There is no routes folder for `cases/[id]`, meaning the detailed investigation view does not exist.
*   **Effort to Hook Up**:
    1.  **Backend**: Update `core/src/i4g/api/cases.py`. It currently only has `list_cases` (returning canned summaries). You need to implement a `get_case(case_id)` endpoint that retrieves full details (timeline, artifacts, graph) from the `ReviewStore`.
    2.  **Frontend**: Create a new route `ui/apps/web/src/app/(console)/cases/[id]/page.tsx`. Implement the full "Workspace" UI layout (likely needing new components for timelines/graphs).

## Note on Other Pages
The following pages are **technically hooked up** but may *appear* as mockups because they have built-in "mock fallbacks" that trigger when `I4G_API_URL` is not set or the backend is unreachable:
*   **Discovery**: Uses `buildMockResponse` in `route.ts` if API is unconnected.
*   **Accounts**: Uses `MOCK_RUNS` in `account-list-service.ts` if API is unconnected.
*   **Search**: Uses `MOCK_HISTORY` in `reviews-service.ts` if API is unconnected.
*   **Analytics / Dashboard**: Call the backend, but the backend implementation (`core/src/i4g/api/analytics.py`) currently returns hardcoded static dictionaries. Hooking these up involves implementing real logic in the **backend Python code**, rather than connecting the frontend.
