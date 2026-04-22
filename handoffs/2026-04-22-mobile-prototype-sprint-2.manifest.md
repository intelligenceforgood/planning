# Mobile Prototype — Sprint 2 (Dashboard + Reviews Queue)

<contract>
**Role:** Executor
**Planner model:** Claude Opus 4.7
**Manifest version:** 1
**Estimated scope:** M (~15–20 Executor turns)
**Repos touched:** mobile
</contract>

## Goal

Make the Dashboard and Reviews Queue screens work end-to-end against `i4g-local` so that
PRD journeys **J2 (Dashboard)** and **J3 (Reviews Queue)** are demo-able. All UI states
(loading, empty, error) must render; list interactions (filter, search, pull-to-refresh,
pseudo-pagination) must work on a physical device.

## Context

- Source plan: [planning/proposals/mobile-prototype/implementation-plan.md](../proposals/mobile-prototype/implementation-plan.md) §Sprint 2.
- PRD journeys J2 + J3: [planning/proposals/mobile-prototype/prd.md](../proposals/mobile-prototype/prd.md).
- TDD reference (auth, ApiClient, theme usage, state shape): [planning/proposals/mobile-prototype/tdd.md](../proposals/mobile-prototype/tdd.md).
- **Authoritative endpoint shapes:** [planning/proposals/mobile-prototype/sprint1-endpoint-verification.md](../proposals/mobile-prototype/sprint1-endpoint-verification.md) — use these payload shapes, not the TDD §12 guesses.
- Shared standards: `copilot/.github/shared/general-coding.instructions.md`.
- Architecture cross-cut: `copilot/.github/shared/architecture-cheatsheet.instructions.md` — Mobile↔Core flows mirror UI↔Core.

### Backend constraints discovered in Sprint 1 (important)

`GET /reviews/queue` (see [core/src/i4g/api/review_queue.py](../../core/src/i4g/api/review_queue.py) `list_queue`) only accepts two query params:

- `status` — single value (default `"new"`)
- `limit` — integer (default 25)

It does **not** support `offset`, `priority` filtering, or text search. The response is `{ items, count }` with no `nextOffset`.

**Implication for this sprint:**

- Server-side filter: use `status` only.
- Priority filter and search: **client-side** filter over the already-fetched `items` array.
- Pagination: implement as **progressive `limit`** — initial `limit=25`, "load more" bumps `limit` by 25 and refetches. This is the prototype-grade compromise; it is acceptable because the local dataset is small and this mirrors what the `ui/` analyst console does today.

<files>
### Files to modify

- `mobile/app/app/(tabs)/dashboard.tsx` — replace the Sprint 1 whoami-only screen with a full Dashboard: header greeting, `metrics[]` grid (3+ cards), recent-activity list, pull-to-refresh, skeleton / empty / error states.
- `mobile/app/app/(tabs)/queue.tsx` — replace the "Coming in Sprint 2" stub with the full Reviews Queue screen (list + filter bar + search box + pull-to-refresh + scroll-to-top + load-more).
- `mobile/app/src/features/dashboard/queries.ts` — keep the existing `useDashboard()` behavior (it already calls `/dashboard/overview` and returns a zero payload on error) but remove the try/catch swallow so TanStack Query's own `isError` path drives the UI. Keep the `staleTime` and `queryKey`.
- `mobile/app/src/features/reviews/queries.ts` — extend `useReviewsQueue` to accept `{ status?: string; limit?: number }` params, pass them as query string, and key the query on those params (`['reviews-queue', { status, limit }]`). Keep `useWhoAmI`, `useCase`, `useAuditLog`, `useDecide` untouched.
- `mobile/app/src/features/reviews/types.ts` — no schema changes expected. Only touch if the verification doc says so.
- `mobile/app/src/features/dashboard/types.ts` — no schema changes expected.

### Files to create

- `mobile/app/src/features/dashboard/components/MetricCard.tsx` — presentational card for a single `DashboardMetric`.
- `mobile/app/src/features/dashboard/components/ActivityRow.tsx` — presentational row for a `DashboardActivityItem`.
- `mobile/app/src/features/reviews/components/QueueRow.tsx` — presentational row for a `ReviewQueueItem`. Shows case id (short), status badge, priority badge, queued-at (relative), assignee or "Unassigned".
- `mobile/app/src/features/reviews/components/FilterBar.tsx` — segmented control for status (`pending | approved | rejected | in_review`) + priority chip group (`low | medium | high | critical`). Emits `onChange({ status, priority })`. "All" must be one of the options in each group so users can clear the filter.
- `mobile/app/src/features/reviews/components/SearchBox.tsx` — text input with 300 ms debounce and an "x" clear button. Emits `onDebouncedChange(q: string)`.
- `mobile/app/src/lib/useDebouncedValue.ts` — generic `useDebouncedValue<T>(value: T, delayMs: number): T` hook.
- `mobile/app/__tests__/features/reviews/QueueRow.test.tsx` — render one row, assert it shows status, priority, case id.
- `mobile/app/__tests__/features/reviews/FilterBar.test.tsx` — assert segmented control changes emit the right payload; "All" clears filters.
- `mobile/app/__tests__/features/reviews/SearchBox.test.tsx` — assert debounced emit (use `jest.useFakeTimers()`).
- `mobile/app/__tests__/features/reviews/queue-screen.test.tsx` — contract-style test: mock `global.fetch` to return happy, empty, paginated (two calls with different `limit`), and error responses; assert the screen renders the right state for each. Pull-to-refresh must trigger a refetch.
- `mobile/app/__tests__/features/dashboard/dashboard-screen.test.tsx` — contract-style test: mock `global.fetch` for happy, empty, error paths; assert metrics render, empty state renders, error banner renders with retry button.
- `mobile/app/__tests__/lib/useDebouncedValue.test.ts` — standard debounce hook test with fake timers.
- `mobile/app/e2e/flows/happy-path.yaml` — Maestro flow: launch → sign-in screen → tap "Continue as Local Analyst" → assert Dashboard metrics visible → tap "Queue" tab → assert at least one queue row visible. No approve step yet (that is Sprint 4).
- `mobile/app/e2e/README.md` — one paragraph on how to run Maestro locally (link to Maestro install docs; no shell scripts required this sprint).

### Files NOT to touch

- `mobile/app/src/api/**` — `ApiClient` is fine as-is from Sprint 1. Do not add retries, caching, or interceptor changes.
- `mobile/app/src/auth/**` — no auth changes this sprint.
- `mobile/app/src/store/**` — Zustand store stays as-is.
- `mobile/app/app/sign-in.tsx` — untouched.
- `mobile/app/app/_layout.tsx` — providers are already wired (Sprint 1.5). Do not modify.
- `mobile/app/app/(tabs)/settings.tsx` — untouched this sprint.
- `mobile/app/app/(tabs)/_layout.tsx` — untouched.
- `mobile/shared/design-tokens/**` — do not regenerate, move, or edit.
- Any `core/**`, `ssi/**`, `ui/**`, `infra/**` file — this sprint is mobile-only. If you think a backend change is needed, `/clarify`.

</files>

## Step-by-step

1. **Read Sprint 1 verification doc** at `planning/proposals/mobile-prototype/sprint1-endpoint-verification.md`. Confirm the `ReviewQueueItem` and `DashboardOverview` shapes in `mobile/app/src/features/*/types.ts` still match. Do not change the Zod schemas unless you find a real mismatch when curling local-aio.

2. **Create the debounce hook** `mobile/app/src/lib/useDebouncedValue.ts` + its test. Run `pnpm test -- useDebouncedValue` before moving on.

3. **Build the reviews queue UI primitives** in this order:
   - `components/QueueRow.tsx` (+ test)
   - `components/FilterBar.tsx` (+ test) — include an explicit "All" option for both status and priority.
   - `components/SearchBox.tsx` (+ test) — uses the debounce hook.
     Run `pnpm test -- features/reviews` after each component lands.

4. **Extend `useReviewsQueue`** in `src/features/reviews/queries.ts`:
   - Accept `{ status?: string; limit?: number }` params (default `limit = 25`, `status` undefined → omit from query string so backend uses its default `"new"`).
   - Build the URL with `URLSearchParams` — do not hand-concatenate.
   - Query key: `['reviews-queue', { status, limit }]`.

5. **Rewrite `app/(tabs)/queue.tsx`**:
   - Local state: `status` (from `FilterBar`), `priority` (client-side filter), `q` (search), `limit` (progressive pagination; starts at 25).
   - Call `useReviewsQueue({ status, limit })`.
   - Client-side derive `visibleItems = items.filter(matchesPriority).filter(matchesSearch)` where search matches `case_id` or `review_id` (case-insensitive substring).
   - `FlatList` with `refreshControl` for pull-to-refresh (`queryClient.invalidateQueries({ queryKey: ['reviews-queue', …] })`).
   - "Load more" button at the footer: bumps `limit` by 25; hidden when `items.length < limit` (server returned fewer than requested, so there is no more).
   - Scroll-to-top button appears after scrolling past ~5 rows; uses `FlatList.scrollToOffset({ offset: 0, animated: true })`.
   - States: skeleton list (~3 placeholder rows) on initial load; empty state with friendly copy; error banner + retry (reuse the pattern already in `dashboard.tsx`).

6. **Rewrite `app/(tabs)/dashboard.tsx`**:
   - Keep the whoami hydration block at the top (existing Sprint 1 logic — analyst name and roles still render).
   - Add `useDashboard()` and render a 2-column grid of `MetricCard` for `overview.metrics`, then a "Recent activity" list from `overview.activity` via `ActivityRow`.
   - Pull-to-refresh: `ScrollView` with `refreshControl` that invalidates both `['whoami']` and `['dashboard-overview']`.
   - Loading: skeleton placeholders for metrics + activity.
   - Empty: if `metrics.length === 0 && activity.length === 0`, render "Nothing to show yet" empty state.
   - Error: error banner + retry (reuse existing pattern).

7. **Remove the silent try/catch** from `useDashboard()` so TanStack Query's `isError` path drives the UI. The screen handles fallback UI; the hook should surface errors.

8. **Write the two screen-level contract tests** (`queue-screen.test.tsx`, `dashboard-screen.test.tsx`) using `global.fetch` mocked via `jest.spyOn(global, 'fetch')`. Do **not** install MSW — it is not a project dependency. One test per state (happy, empty, paginated where applicable, error).

9. **Author the Maestro flow** `e2e/flows/happy-path.yaml`. Use `launchApp → tapOn "Continue as Local Analyst" → assertVisible` pattern. Do not wire it into CI this sprint — just the file plus a short README explaining how to run it locally. The Sprint 5 cleanup pass will handle CI integration.

10. **Run the verification commands below**. If any fail, fix before reporting done.

11. **Check off Sprint 2 items** in `planning/proposals/mobile-prototype/implementation-plan.md` (§S2.1, §S2.2, §S2.3) using `- [x]` as each item is verifiably complete.

<do_not>

- Do not install new npm packages. Use only what is already in `mobile/app/package.json`. If you believe one is required (e.g. `msw`, `date-fns`, `react-native-gesture-handler`), stop and `/clarify`.
- Do not modify the Zod schemas in `features/*/types.ts` unless a live `curl` against local-aio proves the schema is wrong. Record any mismatch found in `sprint1-endpoint-verification.md` under a new "Sprint 2 updates" section.
- Do not hand-write fetch calls anywhere outside `src/api/` — all data fetching goes through `getApi().get(...)` / `.post(...)`. CI has a grep rule that will fail the build otherwise.
- Do not use `AsyncStorage`. Secure storage is `expo-secure-store`, and UI state lives in Zustand.
- Do not add offset-based pagination. The backend does not support it; use progressive `limit`.
- Do not wire Maestro into CI this sprint. File only.
- Do not refactor `api/client.ts`, `auth/**`, or `store/**`. If you feel the urge, add a line to `planning/change_log.md` as a follow-up and move on.
- Do not use hard-coded colors. Pull from `useTheme()` in `src/design/theme.ts`.
- Do not log PII or case identifiers with `console.log`. Use `logger` from `src/lib/logger.ts`. CI will fail on `console.log` of identifiers.
  </do_not>

<verification>

### Acceptance criteria (each must pass before you report done)

- [ ] `pnpm -C mobile/app lint` exits 0.
- [ ] `pnpm -C mobile/app typecheck` exits 0.
- [ ] `pnpm -C mobile/app test` exits 0. New tests listed in `<files>` are present and pass.
- [ ] `pnpm -C mobile/app test --coverage --collectCoverageFrom='src/features/**/*.{ts,tsx}'` reports ≥ 70% lines for `src/features/reviews/` and `src/features/dashboard/`.
- [ ] Running the app against `i4g-local` on a simulator: Dashboard renders 3+ metric cards and a recent-activity list; pull-to-refresh triggers a refetch (visible in the Metro/network log).
- [ ] Queue screen renders rows from `/reviews/queue`, filter bar changes `status` and re-fetches, priority chip filters client-side, search box debounces (verified by network log: typing "foo bar" at normal speed produces ≤ 2 requests, not 7).
- [ ] Airplane-mode check: disabling the laptop's network and pulling to refresh on both screens shows the inline error banner + retry button (no red box / no crash).
- [ ] `e2e/flows/happy-path.yaml` is syntactically valid Maestro YAML (validated by opening it; no need to run Maestro in CI).
- [ ] `planning/proposals/mobile-prototype/implementation-plan.md` §S2.1, §S2.2, §S2.3 items are checked off.

### Commands to run (copy-paste verbatim)

```bash
cd mobile/app
pnpm install                                  # idempotent; should be a no-op
pnpm lint
pnpm typecheck
pnpm test
pnpm test --coverage --collectCoverageFrom='src/features/**/*.{ts,tsx}'
```

### Manual device smoke (document in your final report)

```bash
# In terminal A — start local-aio per core/docs/runbooks/local-aio.md, ensure it responds:
curl -s http://localhost:8000/dashboard/overview | head -c 400
curl -s http://localhost:8000/reviews/queue?status=new&limit=5 | head -c 400

# In terminal B — launch the app against local profile:
cd mobile/app
pnpm dev:ios       # or pnpm dev:android
```

Report: one screenshot of Dashboard, one of Queue, and one of the Queue error banner (airplane mode).

</verification>

## If blocked

Run `/clarify` with a short structured question. Typical expected blockers:

- A Zod schema parse fails because the real response differs from what the verification doc claims.
- The `FilterBar` status values do not match any rows in the local DB (local seed may only have `new`).
- Maestro YAML schema uncertainty (stop and ask rather than guessing).

Do not invent a new endpoint or synthesize missing backend support. Stop and ask.
