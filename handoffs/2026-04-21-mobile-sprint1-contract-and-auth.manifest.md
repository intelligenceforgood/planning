# Mobile Prototype — Sprint 1: Contract Verification + Auth Shell

<contract>
**Role:** Executor
**Planner model:** Claude Opus 4.7
**Manifest version:** 1
**Estimated scope:** L
**Repos touched:** mobile, planning
</contract>

## Goal

Deliver the Sprint 1 exit criteria from the implementation plan: mock sign-in →
`(tabs)/dashboard` renders "Signed in as Local Analyst" populated from a real `/auth/whoami`
call against `i4g-local`. Also land a compiling-but-unwired `google-pkce-iap` provider, the
typed `ApiClient`, all global providers, and Zod schemas for every Sprint 2–4 endpoint.

## Context

- Source plan: [planning/proposals/mobile-prototype/implementation-plan.md](../proposals/mobile-prototype/implementation-plan.md) — Sprint 1 (S1.1–S1.5)
- TDD (ApiClient, errors, auth providers, Zod schemas, behavior table): [planning/proposals/mobile-prototype/tdd.md](../proposals/mobile-prototype/tdd.md) §4, §5, §6, §7, §8, §12
- PRD open questions to resolve: [planning/proposals/mobile-prototype/prd.md](../proposals/mobile-prototype/prd.md) §10
- local-aio runbook (prerequisite for S1.1): `core/docs/runbooks/local-aio.md`
- Sprint 0 deliverables already on disk: `mobile/app/` (Expo SDK 54, not 51 — the TDD §1 decision notes this; do not downgrade)
- Shared standards: [copilot/.github/shared/general-coding.instructions.md](../../copilot/.github/shared/general-coding.instructions.md)

Do **not** restate the TDD here — link sections and implement.

<files>
### Files to create

**API layer**

- `mobile/app/src/api/client.ts` — `createApiClient(auth)` per TDD §4.3. Request wrapper with bearer header, status mapping, Zod `safeParse`, `X-Client` header. `get` / `post` / `patch` / `delete`.
- `mobile/app/src/api/errors.ts` — full hierarchy from TDD §4.2: `ApiError`, `NetworkError`, `AuthError`, `ValidationError`, `NotFoundError`, `ServerError`; plus `buildErrorFromResponse(res)` and `mapErrorToBanner(err)`.
- `mobile/app/src/api/index.ts` — singleton getter. `getApi()` lazily constructs once from the active auth provider; `resetApi()` for tests.
- `mobile/app/__tests__/api/client.test.ts` — unit coverage: happy path, 401 → `AuthError` + `auth.signOut()` called, 404 → `NotFoundError`, 500 → `ServerError`, schema drift → `ValidationError`. Use `global.fetch = jest.fn()` mocks.
- `mobile/app/__tests__/api/errors.test.ts` — `mapErrorToBanner` returns correct copy per error type.

**Auth layer**

- `mobile/app/src/auth/provider.ts` — `AuthProvider` interface + `AuthState` type per TDD §5.1.
- `mobile/app/src/auth/mock.ts` — TDD §5.2. Additionally: on `signIn()`, after setting the local user, call `api.get('/auth/whoami', WhoAmI)` and hydrate `user` from the response; on failure fall back to hard-coded `analyst@local`. `getAccessToken()` returns `null`.
- `mobile/app/src/auth/google-pkce-iap.ts` — TDD §5.3. Must **compile and unit-test**, but do not wire to a real OAuth client. Use `expo-auth-session` `AuthRequest` + `exchangeCodeAsync`. Tokens stored via `expo-secure-store` under namespaced keys (`i4g.idToken`, `i4g.refreshToken`). Refresh when `exp - 60s < now`.
- `mobile/app/src/auth/index.ts` — selector: `config.authProvider === 'mock' ? mockProvider : googlePkceIapProvider`.
- `mobile/app/__tests__/auth/mock.test.ts` — `signIn` sets user, `signOut` clears, `onChange` fires.
- `mobile/app/__tests__/auth/google-pkce-iap.test.ts` — mock `AuthRequest.promptAsync` + `exchangeCodeAsync`; assert tokens are written to SecureStore and `getAccessToken` triggers refresh when expired.

**Feature schemas (Zod)**

- `mobile/app/src/features/reviews/types.ts` — all schemas from TDD §6: `ReviewStatus`, `ReviewSummary`, `ReviewsQueue`, `CaseDetail`, `DecisionRequest`, `DecisionResponse`. Plus `WhoAmI` (`{ email, name, roles }`).
- `mobile/app/src/features/reviews/queries.ts` — `useReviewsQueue`, `useCase`, `useDecide` per TDD §7. Sprint 1 only needs `useWhoAmI()` to be call-able from Dashboard; the rest may be present but unused.
- `mobile/app/src/features/dashboard/types.ts` — placeholder: `DashboardCounts` shape as `{ pending: number; inReview: number; approved: number }` with TODO marker referencing `sprint1-endpoint-verification.md`.
- `mobile/app/src/features/dashboard/queries.ts` — `useDashboard()` hook that calls `/reviews/search?limit=0&status=pending` (or the endpoint confirmed in S1.1); if verification is still pending, return a hard-coded zero payload and log a `logger.warn` once.
- `mobile/app/__tests__/features/reviews/types.test.ts` — each Zod schema parses a representative payload and rejects a known-bad one.

**Lib & state**

- `mobile/app/src/lib/query-client.ts` — `QueryClient` with retries (3, exp backoff), `staleTime: 60_000`, `refetchOnAppFocus` enabled globally (screens opt out).
- `mobile/app/src/lib/error-boundary.tsx` — class component catching render errors; renders theme-aware fallback UI with retry button.
- `mobile/app/src/lib/logger.ts` — `logger.info|warn|error(tag, data)`. In `local`/`dev` pretty-prints; in `prod` routes to Sentry breadcrumb (no-op when Sentry disabled).
- `mobile/app/src/lib/redact.ts` — `redactEvent(event)` + PII allowlist array. Exported for Sentry `beforeSend` wiring in Sprint 5.
- `mobile/app/__tests__/lib/redact.test.ts` — asserts `email`, `token`, `authorization`, `idToken`, `refreshToken` are removed from nested objects.
- `mobile/app/src/store/ui.ts` — Zustand store: `{ toasts: Toast[], pushToast(t), dismissToast(id), user: User | null, setUser(u), clearUser() }`.

**Screens**

- `mobile/app/app/sign-in.tsx` — single button "Continue as Local Analyst" (or "Continue with Google" when `authProvider === 'google-pkce-iap'`). On press calls `auth.signIn()`, then `router.replace('/(tabs)/dashboard')`.
- `mobile/app/app/(tabs)/_layout.tsx` — bottom tab router with three tabs: `dashboard`, `queue`, `settings`. Queue and Settings are stubs that render `<Text>Coming in Sprint 2/5</Text>`.
- `mobile/app/app/(tabs)/dashboard.tsx` — renders `Signed in as {user.name}` from the Zustand store. Calls `useWhoAmI()`; shows loading skeleton per TDD §8.
- `mobile/app/app/(tabs)/queue.tsx` — stub.
- `mobile/app/app/(tabs)/settings.tsx` — stub.

**Verification scratch note**

- `planning/proposals/mobile-prototype/sprint1-endpoint-verification.md` — one row per TDD §12 endpoint. Columns: Purpose | Assumed path | Verified? | Real payload (truncated) | Schema delta needed. At least fill the Purpose + Assumed path columns for every row; fill the rest when local-aio is reachable (see Step 1).

### Files to modify

- `mobile/app/app/_layout.tsx` — wrap `<Slot />` in: `QueryClientProvider` → `ErrorBoundary` → toast host (read from `store/ui.ts`). Call `auth.initialize()` in a top-level effect and gate rendering until resolved; if `user == null`, `router.replace('/sign-in')`.
- `mobile/app/app/index.tsx` — replace "Hello I4G" with a `<Redirect href="/sign-in" />` (auth gating handled in `_layout`).
- `mobile/app/package.json` — add deps (pin to SDK-54-compatible versions found via `npx expo install`): `@tanstack/react-query`, `zustand`, `expo-auth-session`, `expo-web-browser`, `expo-secure-store`, `expo-crypto`. Dev: `msw` (optional for Sprint 1 contract tests; use `fetch` mocks if MSW is painful). Do not upgrade Expo SDK.
- `planning/proposals/mobile-prototype/implementation-plan.md` — check off (`- [x]`) every S1.x task you completed. Leave unchecked with a one-line note any task that was blocked (e.g., local-aio unreachable).
- `planning/proposals/mobile-prototype/prd.md` — if any §10 open question is resolved by S1.1 verification, edit the answer inline and remove the "blocker" tag. Do not invent answers; only record what you verified.

### Files NOT to touch

- `mobile/shared/design-tokens/**` — token source and wrappers are frozen for Sprint 1.
- `mobile/app/eas.json`, `mobile/app/app.config.ts`, `mobile/app/.env.*.example`, `mobile/app/tsconfig.json`, `mobile/app/.eslintrc.js`, `mobile/app/.prettierrc.js` — Sprint 0 deliverables; do not edit unless a concrete Sprint 1 bug forces it (document the edit in `change_log.md` if so).
- `.github/workflows/mobile-ci.yml` — Sprint 0 deliverable; do not edit.
- `core/`, `ssi/`, `ui/`, `infra/`, `ml/`, `docs/`, `mobile/shared/**` — out of scope.
- Any Sprint 2+ screens (case detail, evidence, reports, decision sheet) — only the stubs listed above.
  </files>

## Step-by-step

### Step 1 — S1.1 endpoint verification (best-effort)

1. Try to stand up `i4g-local` per `core/docs/runbooks/local-aio.md`.
2. If `curl http://localhost:8000/docs` returns Swagger, walk every TDD §12 row: issue the `curl`, capture a truncated payload (≤ 20 lines per endpoint), and record findings in `planning/proposals/mobile-prototype/sprint1-endpoint-verification.md`.
3. If local-aio cannot be brought up, create the verification note with all rows marked `Verified?: No — local-aio unreachable` and fill Purpose + Assumed path only. Continue to Step 2 — **do not block the manifest on backend setup.**
4. For every **confirmed** delta between TDD §6 schemas and the real payload, update `src/features/reviews/types.ts`. For every **unverified** endpoint, add a `// TODO(sprint1-verify)` comment above the schema.
5. Update PRD §10 only for items you actually verified.

### Step 2 — API client + errors

1. Implement `src/api/errors.ts` first (pure classes, no deps).
2. Implement `src/api/client.ts` against the interface in TDD §4.1. Keep the client thin — no retry logic here (that lives in TanStack Query).
3. Implement `src/api/index.ts` singleton. `getApi()` reads the active auth provider from `src/auth/index.ts`.
4. Write `__tests__/api/client.test.ts` and `__tests__/api/errors.test.ts`.

**Checkpoint:** `pnpm -C mobile/app test -- api` passes with ≥ 80% line coverage of `src/api/`.

### Step 3 — Auth providers

1. Define the `AuthProvider` interface in `src/auth/provider.ts`.
2. Implement `src/auth/mock.ts`. After `signIn()` sets the local user object, fire-and-forget a `whoami` call — use dynamic import to break the circular dep between `auth` and `api` (`const { getApi } = await import('@/api')`).
3. Implement `src/auth/google-pkce-iap.ts`. Guard the `expo-auth-session` hook usage: the module must export a plain object (not a component), so wrap the PKCE call in a function that accepts a pre-constructed `AuthRequest` passed in by the screen — see TDD §5.3 note about `promptAsync`. Store tokens under `i4g.idToken` / `i4g.refreshToken` in SecureStore.
4. Implement `src/auth/index.ts` selector.
5. Write both `__tests__/auth/*.test.ts` files. Mock `expo-secure-store` and `expo-auth-session` at the module level.

**Checkpoint:** `pnpm -C mobile/app test -- auth` passes.

### Step 4 — Lib, state, and feature schemas

1. Add deps to `package.json` via `npx expo install <pkg>` (run from `mobile/app/`) so versions match SDK 54.
2. Implement `src/lib/query-client.ts`, `src/lib/error-boundary.tsx`, `src/lib/logger.ts`, `src/lib/redact.ts`.
3. Implement `src/store/ui.ts` (Zustand).
4. Implement `src/features/reviews/types.ts` with every schema in TDD §6 plus `WhoAmI`. Export both Zod schemas and inferred TS types.
5. Implement `src/features/reviews/queries.ts` with all three hooks from TDD §7 — only `useWhoAmI` needs to be reachable this sprint; the rest may be exported but unused.
6. Implement `src/features/dashboard/{types,queries}.ts`.
7. Write `__tests__/lib/redact.test.ts` and `__tests__/features/reviews/types.test.ts`.

### Step 5 — Screens and root wiring

1. Modify `app/_layout.tsx`: wrap `<Slot />` in `QueryClientProvider` → `ErrorBoundary` → toast host. Call `auth.initialize()` in an effect; while pending, render a full-screen spinner. After init, if `store.user == null`, `router.replace('/sign-in')`.
2. Replace `app/index.tsx` with `<Redirect href="/sign-in" />`.
3. Implement `app/sign-in.tsx` with a single primary button. Label depends on `config.authProvider`.
4. Implement `app/(tabs)/_layout.tsx` with three tabs.
5. Implement `app/(tabs)/dashboard.tsx` — calls `useWhoAmI()`; renders `Signed in as {user.name}` + user email/roles. Skeleton while loading; error banner + retry on failure.
6. Stub `queue.tsx` and `settings.tsx`.

**Checkpoint:** `pnpm -C mobile/app typecheck` passes. Manual launch on iOS simulator: tap sign-in → see Dashboard text sourced from `/auth/whoami` (if local-aio is up) or from the mock fallback (if not).

### Step 6 — Plan & PRD bookkeeping

1. Tick off every completed S1.x box in `planning/proposals/mobile-prototype/implementation-plan.md`. For anything skipped, leave the box unchecked and add a one-line `(blocked: <reason>)` inline.
2. Update PRD §10 only for verified items.
3. Do **not** write a `change_log.md` entry — that is the Planner's job in `/verify-handoff`.

<do_not>

- Do not upgrade or downgrade Expo SDK (stay on SDK 54).
- Do not introduce React Navigation directly — use Expo Router only.
- Do not introduce a form library, styled-components, or NativeWind (see TDD §16).
- Do not add retry or backoff logic inside `ApiClient` — that's TanStack Query's job.
- Do not wire `google-pkce-iap` to a real OAuth client; it must compile and pass unit tests only.
- Do not use `AsyncStorage` anywhere — tokens go in `expo-secure-store` only.
- Do not put raw `fetch(` calls outside `src/api/` (the Sprint 0 CI grep will fail the PR).
- Do not log request/response bodies, tokens, emails, or any PII field — use `logger` + `redact`.
- Do not refactor Sprint 0 files for style. If something is broken, fix the minimum and note it in `planning/change_log.md` as a follow-up for the Planner.
- Do not guess payload shapes when backend verification fails — leave TDD §6 schemas as-is with `TODO(sprint1-verify)` markers.
- Do not add a `change_log.md` entry; the Planner writes it during verification.
  </do_not>

<verification>

### Acceptance criteria

Every item below must pass before reporting complete. Record the output of each command in your final summary.

- [ ] `pnpm -C mobile/app install` completes with no peer-dep errors.
- [ ] `pnpm -C mobile/app lint` exits 0.
- [ ] `pnpm -C mobile/app typecheck` exits 0.
- [ ] `pnpm -C mobile/app test` exits 0 and reports ≥ 80% line coverage for `src/api/`. (Use `jest --coverage --collectCoverageFrom='src/api/**/*.ts'`.)
- [ ] `pnpm -C mobile/app test -- auth` exits 0 including the `google-pkce-iap` mocked flow.
- [ ] `pnpm -C mobile/app test -- redact` exits 0 and the assertions explicitly cover `email`, `token`, `authorization`, `idToken`, `refreshToken`.
- [ ] `grep -RE "(^|[^.])fetch\(" mobile/app/src mobile/app/app | grep -v "src/api/"` prints nothing.
- [ ] `grep -R "AsyncStorage" mobile/app/src mobile/app/app` prints nothing.
- [ ] `planning/proposals/mobile-prototype/sprint1-endpoint-verification.md` exists with one row per TDD §12 endpoint.
- [ ] `planning/proposals/mobile-prototype/implementation-plan.md` has every completed S1.x task checked off; blocked items are annotated inline.
- [ ] Manual: `pnpm -C mobile/app start`, open iOS simulator, tap "Continue as Local Analyst" — Dashboard renders `Signed in as Local Analyst` (or real whoami name if local-aio is reachable). Record the outcome in the final summary.

### Commands to run

```bash
cd mobile/app
pnpm install
pnpm lint
pnpm typecheck
pnpm test --coverage --collectCoverageFrom='src/api/**/*.ts' --collectCoverageFrom='src/auth/**/*.ts' --collectCoverageFrom='src/lib/redact.ts'

# Security greps (must print nothing)
cd ../..
grep -RE "(^|[^.])fetch\(" mobile/app/src mobile/app/app | grep -v "src/api/" || true
grep -R "AsyncStorage" mobile/app/src mobile/app/app || true

# Manual smoke (record result)
cd mobile/app && pnpm start
```

</verification>

## If blocked

Run `/clarify` with a short structured question and stop. Do not guess.

Likely blockers and what to ask about:

- **local-aio won't start** — continue per Step 1 fallback; do not block the manifest. Record in verification note and final summary.
- **Jest + `jest-expo` chokes on `expo-auth-session` / `expo-secure-store` native modules** — ask whether to add a manual `jest.mock` at the top of each test file or a shared `__mocks__/` fixture. Do not swap test runners.
- **TDD §6 schema conflicts with real payload in a way that breaks Sprint 2 design** — stop and `/clarify`; schema drift that only changes field names is safe to fix inline, but shape changes (e.g., nested vs flat, array vs paginated) are a design call.
- **Sprint 0 files need changes to unblock Sprint 1** — stop and `/clarify` before editing any file in the "Files NOT to touch" list.
