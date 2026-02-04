# UI Mockup Assessment & Backend Integration Status

*Date: February 3, 2026*

Based on an assessment of the `ui/` repository and its interaction with the `core/` backend, the following pages have been identified as mockups or incomplete, ranked by the effort required to connect them to the backend independently.


## Note on Other Pages
The following pages are **technically hooked up** but may *appear* as mockups because they have built-in "mock fallbacks" that trigger when `I4G_API_URL` is not set or the backend is unreachable:
*   **Discovery**: Uses `buildMockResponse` in `route.ts` if API is unconnected.
*   **Accounts**: Uses `MOCK_RUNS` in `account-list-service.ts` if API is unconnected.
*   **Search**: Uses `MOCK_HISTORY` in `reviews-service.ts` if API is unconnected.

## Completed
*   **Case Workspace / Detail View**: Full end-to-end flow working with Real DB (SQLite/ReviewStore). Includes Dashboard, Filtering, and Detail views.
*   **Taxonomy Page**: The page `ui/apps/web/src/app/(console)/taxonomy/page.tsx` is now an async Server Component that fetches data from the backend `/taxonomy` endpoint via `taxonomy-service.ts`.
