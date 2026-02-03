# UI Mockup Assessment & Backend Integration Status

*Date: February 3, 2026*

Based on an assessment of the `ui/` repository and its interaction with the `core/` backend, the following pages have been identified as mockups or incomplete, ranked by the effort required to connect them to the backend independently.

## 1. Case Workspace / Detail View (High Effort)
*   **Path**: `ui/apps/web/src/app/(console)/cases/[id]/page.tsx`
*   **Status**: **Hooked Up (Mock Backend)**.
    *   The page fetches data from `GET /cases/{id}`.
    *   Currently displaying "Static Mock" data served by the Python backend (Phase 1).
    *   Ready for Phase 2 (Real DB Integration).

## Note on Other Pages
The following pages are **technically hooked up** but may *appear* as mockups because they have built-in "mock fallbacks" that trigger when `I4G_API_URL` is not set or the backend is unreachable:
*   **Discovery**: Uses `buildMockResponse` in `route.ts` if API is unconnected.
*   **Accounts**: Uses `MOCK_RUNS` in `account-list-service.ts` if API is unconnected.
*   **Search**: Uses `MOCK_HISTORY` in `reviews-service.ts` if API is unconnected.

## Completed
*   **Case Workspace / Detail View**: Full end-to-end flow working with backend-served mock data.
*   **Taxonomy Page**: The page `ui/apps/web/src/app/(console)/taxonomy/page.tsx` is now an async Server Component that fetches data from the backend `/taxonomy` endpoint via `taxonomy-service.ts`.
