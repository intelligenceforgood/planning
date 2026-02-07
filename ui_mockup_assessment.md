# UI Mockup Assessment & Backend Integration Status

*Date: February 7, 2026*

Based on an assessment of the `ui/` repository and its interaction with the `core/` backend, the following pages have been identified as mockups or incomplete, ranked by the effort required to connect them to the backend independently.

### 1. Search History
*   **Location**: `ui/apps/web/src/app/(console)/search`
*   **Status**: Mock Fallback.
*   **Backend**: Unverified.
*   **Notes**: Uses `MOCK_HISTORY` in `reviews-service.ts` if API is unconnected.

## Note on Other Pages
The following pages are **technically hooked up** but may *appear* as mockups because they have built-in "mock fallbacks" that trigger when `I4G_API_URL` is not set or the backend is unreachable:
*   (See above list - moving items to active assessment)

## Completed
*   **Accounts Integration**: Fully verified.
    *   **Backend**: `POST /accounts/extract`, `GET /accounts/runs` (Core: `i4g.api.account_list`, UI: `account-list-service.ts`).
    *   **Config**: `I4G_API_URL` set in `.env.local`. Verified `GET /accounts/runs` health check.
    *   **Features**: `POST /accounts/extract` smoke test passed (Run `account-run-33a51e7f`).
    *   **Artifacts**: Implemented `GET /accounts/artifacts/{filename}` for local report serving. GCS/Drive links verified for production.
*   **Discovery Integration**: Integrated with `GET /discovery/search`. Backend uses `HybridSearchService` (local DB) or Google Vertex AI. Static mock fallbacks removed.
*   **Analytics & Reporting**: Fully integrated with `GET /analytics/overview` and redesigned to match application standards.
*   **Case Workspace / Detail View**: Full end-to-end flow working with Real DB (SQLite/ReviewStore). Includes Dashboard, Filtering, and Detail views.
*   **Taxonomy Page**: The page `ui/apps/web/src/app/(console)/taxonomy/page.tsx` is now an async Server Component that fetches data from the backend `/taxonomy` endpoint via `taxonomy-service.ts`.
