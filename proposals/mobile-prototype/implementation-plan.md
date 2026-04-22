# Implementation Plan — I4G Mobile Prototype

> **Status:** Draft v1.0
> **Usage:** This is the single source of truth for **what work happens when** during the prototype.
> Tick boxes as you complete tasks. If scope changes, amend the PRD and then this file.
> **Cadence:** 5 sprints, each ≈ 1 calendar week of focused work (calibrate to your availability).
> **Prereqs read:** [prd.md](./prd.md), [architecture.md](./architecture.md), [tdd.md](./tdd.md).

## 0. How to use this plan

- Work **one sprint at a time**. Finish its exit criteria before starting the next.
- Each task has a one-line **Acceptance** note. Don't tick until acceptance is true.
- **Handoff-safe:** Every task is small enough for a Planner-authored manifest (see
  `copilot/.github/shared/handoff-manifest.instructions.md`) if you want to split Planner/Executor.
- **Git hygiene:** One PR per task group (usually per top-level bullet). PR description links back
  to the task in this file.

## Sprint 0 — Workspace & methodology (foundations)

> **Goal:** A novice developer can clone, install, and run an empty Expo app on iOS Simulator and
> Android Emulator without reading anything outside `developer-guide.md`. No I4G backend yet.
> **Exit criteria:** simulator + emulator both render "Hello I4G"; CI is green on an empty PR.

### S0.1 Repo scaffolding

- [x] Create `mobile/app/` (do **not** touch `mobile/shared/design-tokens/`).
      _Acceptance: `ls mobile/app/package.json` succeeds._
- [x] Run `pnpm create expo-app@latest app --template tabs-typescript` inside `mobile/` (then move
      files to `mobile/app/`, or use `--name app`). Pin Expo SDK 51.
      _Acceptance: `pnpm -C mobile/app start` prints a QR code._
- [x] Replace generated ESLint/Prettier config with copies from `ui/` (same rules, same version).
      _Acceptance: `pnpm -C mobile/app lint` passes on the template code._
- [x] Add `tsconfig.json` with `strict: true` and path alias `@/*` → `src/*`.
      _Acceptance: `pnpm -C mobile/app typecheck` passes._
- [x] Delete the template's example screens; replace `app/index.tsx` with a single `Hello I4G` view.
      _Acceptance: app renders "Hello I4G" on both simulators._

### S0.2 Dev Client + profiles

- [x] Add `eas.json` with three build profiles: `local`, `dev`, `prod`.
      _Acceptance: `eas build --profile local --platform ios --local` succeeds on the dev's laptop._
- [x] Add `.env.local.example` / `.env.dev.example` / `.env.prod.example` per TDD §3.1.
      _Acceptance: all three committed; `.env.local` is git-ignored._
- [x] Add `app.config.ts` that wires `process.env.EXPO_PUBLIC_*` into `extra` (TDD §3.2).
      _Acceptance: a Hello screen prints `config.profile` from `expo-constants`._
- [x] Install Expo Dev Client; add `pnpm dev:ios` and `pnpm dev:android` scripts.
      _Acceptance: physical iPhone running Dev Client connects to the dev laptop over LAN._

### S0.3 CI

- [x] Add `.github/workflows/mobile-ci.yml`: install → lint → typecheck → test.
      _Acceptance: green on a no-op PR in <10 min._
- [x] Add CI grep rules: forbid `console.log` of tokens/PII, forbid `fetch(` outside `src/api/`,
      forbid `AsyncStorage` (use `SecureStore`).
      _Acceptance: a deliberate violation PR turns red._

### S0.4 Design tokens wiring

- [x] In `mobile/shared/design-tokens/`, run `npm run build` and verify `dist/` outputs are fresh.
      _Acceptance: `dist/tokens.ts` exists and exports a typed theme object._
- [x] From `mobile/app/src/design/theme.ts`, import the generated TS and expose `useTheme()`.
      _Acceptance: Hello screen color comes from `theme.color.surface`._

### S0.5 Documentation

- [x] Write the "Zero to Hello" section of `developer-guide.md` against what actually happened.
      _Acceptance: a teammate follows it and succeeds on a fresh laptop._

## Sprint 1 — Contract verification + auth shell

> **Goal:** Every endpoint the prototype needs is verified against `i4g-local`. The app can
> mock-auth against local-aio and land on a stub Dashboard.
> **Exit criteria:** sign-in (mock) → Dashboard displaying "Signed in as Local Analyst" with a
> real `/auth/whoami` payload.

### S1.1 Endpoint catalog verification (TDD §12)

- [x] Stand up `i4g-local` per `core/docs/runbooks/local-aio.md` on the dev's laptop.
      _Acceptance: `curl http://localhost:8000/docs` opens Swagger._
- [x] For each row in TDD §12, `curl` the endpoint against local-aio and capture the real payload.
      Paste findings into a scratch note; update the Zod schemas in `src/features/*/types.ts` to match.
      _Acceptance: every assumed path + payload is either verified or noted as a gap._
- [x] **Resolve PRD §10 open questions** via the Swagger exploration. Amend PRD if needed.
      _Acceptance: PRD §10 has no open items marked "blocker"._

### S1.2 ApiClient

- [x] Implement `ApiClient` per TDD §4 with unit tests (happy, 401, 404, 500, schema-drift).
      _Acceptance: unit tests pass; coverage of `src/api/` ≥ 80%._
- [x] Add `createApiClient(auth)` + singleton getter; wire into `_layout.tsx` root.
      _Acceptance: `useReviewsQueue()` called from a stub screen fetches data from local-aio._

### S1.3 Auth (mock)

- [x] Implement `mockProvider` per TDD §5.2 with a `/auth/whoami` bootstrap call.
      _Acceptance: on launch, Dashboard shows the mock user's email and roles._
- [x] Implement Sign-in screen with a single button `Continue as Local Analyst`.
      _Acceptance: tapping it calls `auth.signIn()` and navigates to Dashboard._

### S1.4 Auth (google-pkce-iap) — stubbed

- [x] Implement `google-pkce-iap` per TDD §5.3 but gated behind `config.authProvider`. Do **not**
      wire to a real OAuth client yet; just make the module compile and the unit tests pass.
      _Acceptance: unit test with a mocked `AuthRequest` + token exchange passes; screen flow compiles._

### S1.5 Global state + providers

- [x] Set up TanStack Query provider, Zustand store, Error Boundary, Toast host in `_layout.tsx`.
      _Acceptance: a deliberately-thrown error in a screen shows the boundary UI, not a red-screen._

## Sprint 2 — Dashboard + Reviews Queue

> **Goal:** The two list-centric screens work end-to-end against local-aio.
> **Exit criteria:** J2 and J3 from the PRD are demo-able.

### S2.1 Dashboard

- [x] Implement `useDashboard()` hook; shape depends on §12 verification.
      _Acceptance: Dashboard shows 3 counts and a recent-items list, refreshing on pull._
- [x] Add skeleton loading + empty state + inline error (TDD §8 row for Dashboard).
      _Acceptance: disabling network shows the error banner with retry._

### S2.2 Reviews Queue

- [x] Implement `useReviewsQueue(params)` with pagination (`offset`/`limit`).
      _Acceptance: scrolling to bottom triggers next-page fetch._
- [x] Filter bar: status (pending | approved | rejected | in*review), priority.
      \_Acceptance: changing filter re-keys the query and re-fetches.*
- [x] Search box: debounced 300 ms; clears with an "x".
      _Acceptance: typing doesn't fire a request per keystroke (verified via network inspector)._
- [x] Pull-to-refresh + scroll-to-top button.
      _Acceptance: both work on a physical device._

### S2.3 Testing

- [x] Component tests for Queue row, filter bar, empty/error states.
- [x] Contract tests with MSW: queue happy + paginated + error.
- [x] Update Maestro happy-path to include "sign-in → queue loads".

## Sprint 3 — Case Detail, Evidence, Reports

> **Goal:** Read-side is feature-complete for the slice.
> **Exit criteria:** J4 + J5 demo-able; one hard-coded "tricky" case (many evidence items, a PDF
> report, an audit log with 50+ entries) renders correctly.

### S3.1 Case Detail

- [x] Implement `useCase(id)` + `CaseDetail` screen. Sections: header, summary, classification,
      timeline, evidence grid, audit log (collapsible).
      _Acceptance: all sections render; each has its own error boundary._
- [x] Header action: a single "Decide…" button (opens a sheet — wired in Sprint 4).
      _Acceptance: button is visible only for `pending` / `in_review` statuses._

### S3.2 Evidence Detail

- [x] Use `expo-image` for thumbnails and full images; support pinch-to-zoom via a community lib or
      simple gesture handler.
      _Acceptance: large images don't crash on a 3 GB-RAM Android emulator._
- [x] Metadata pane: capture-time, source, hash, classification tags.

### S3.3 Report viewer

- [x] Use `react-native-pdf`. Handle signed-URL vs bearer cases per §12 verification.
      _Acceptance: approved report opens and scrolls on both platforms._

### S3.4 Testing

- [x] Component snapshot for each section.
- [x] Maestro flow extended to open a case + preview one evidence item + open report.

## Sprint 4 — The write: Approve / Reject

> **Goal:** One mutation proves the full round-trip.
> **Exit criteria:** J6 demo-able including optimistic update, rollback-on-error, audit-log
> reflection.

### S4.1 Decision Sheet

- [ ] Bottom sheet with a segmented control (Approve | Reject) + free-text comment + "Submit".
      _Acceptance: submitting calls `useDecide().mutate(…)`._
- [ ] Optimistic update per TDD §7; rollback on error with an inline banner.
      _Acceptance: disable network → submit → banner appears → re-enable → submit succeeds._

### S4.2 Post-mutation UX

- [ ] Toast "Approved" / "Rejected" on success.
- [ ] Auto-invalidate `reviews-queue` and `["case", id]`.
- [ ] If the case is removed from the current filter view, pop to queue; otherwise stay on detail.
      _Acceptance: tested both cases._

### S4.3 Testing

- [ ] Component test for the sheet (Approve, Reject, cancel).
- [ ] Contract test for the mutation including optimistic rollback path.
- [ ] Maestro happy path now includes the approve step and verifies status text changes.

## Sprint 5 — Settings, telemetry, polish, dogfood

> **Goal:** Prototype is ready to hand to a second developer for the acceptance test.
> **Exit criteria:** README Definition-of-Done is fully checkable.

### S5.1 Settings screen

- [ ] Profile label (e.g., `LOCAL · direct · mock`) + app version + Sentry-enabled toggle.
- [ ] Sign-out button (works in both providers).
- [ ] (Dev-only) profile switcher that re-reads env and reloads the app.
      _Acceptance: switching from `local` to `dev` reconnects without rebuild._

### S5.2 Telemetry

- [ ] Wire Sentry per TDD §10 behind `config.sentryDsn`.
- [ ] Add `redactEvent` with unit tests asserting email, tokens, and known PII fields are removed.
- [ ] Confirm crash reports reach Sentry in the dev profile.

### S5.3 Remote profile smoke

- [ ] Configure the OAuth client for the mobile redirect scheme (developer-guide step — document
      the exact GCP console clicks).
- [ ] Sign in against `dev.intelligenceforgood.org`; verify Dashboard loads against real data.
      _Acceptance: one screenshot per screen recorded for the change-log entry._

### S5.4 Docs finalization

- [ ] Finish `developer-guide.md` with every gotcha hit during the prototype.
- [ ] Migrate the "keep forever" bits to `mobile/docs/`: README, contributing, token flow, release
      flow (placeholder).
- [ ] Write the change-log entry in `planning/change_log.md` with sprint-by-sprint summary.
- [ ] Run the **acceptance test**: a second developer clones, runs local-aio, and reaches the
      approve flow on their own phone in <4 hours. Fix the guide for whatever they stumble on.

### S5.5 Cleanup

- [ ] Delete `planning/mobile/*.md` (already superseded; confirm nothing external references them).
- [ ] Confirm `mobile/shared/design-tokens/` still builds.
- [ ] Tag prototype as `mobile-prototype-v0.1` in git.

## Cross-cutting task checklist (applies every sprint)

- [ ] Every PR has a passing CI run.
- [ ] Every new module has at least one unit test.
- [ ] Every new screen has a loading, empty, and error state.
- [ ] Every new hook has a `queryKey` that's unique and parameter-stable.
- [ ] No PR introduces `fetch(` outside `src/api/`, a raw `AsyncStorage` write, or a new lib without
      the PR description saying why.

## Risk register (live during execution)

Maintain this in-place. When a new risk appears, add it and note the mitigation.

| ID   | Risk                                                        | State | Owner | Mitigation                                                      |
| ---- | ----------------------------------------------------------- | ----- | ----- | --------------------------------------------------------------- |
| R-01 | Backend endpoint assumed to exist doesn't                   | open  | dev   | S1.1 verifies up-front. Block sprint 2 on resolution.           |
| R-02 | IAP + PKCE token handoff doesn't work first try             | open  | dev   | Dedicate S5.3 to it; fallback is "document and defer".          |
| R-03 | Vitest + Expo RN friction eats a day                        | open  | dev   | Fall back to Jest + `jest-expo` after half a day.               |
| R-04 | Physical iPhone won't reach laptop LAN IP (corporate Wi-Fi) | open  | dev   | Use `expo start --tunnel` as fallback; documented in dev guide. |

## Sprint exit template (paste at end of each sprint in PR description)

```
Sprint N exit
- Done: <list>
- Skipped (and why): <list>
- Carried to next sprint: <list>
- Gotchas added to dev guide: <list>
- New risks: <list>
```

---

Next: [developer-guide.md](./developer-guide.md) — your day-one ramp-up.
