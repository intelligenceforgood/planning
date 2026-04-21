# PRD — I4G Mobile Prototype

> **Status:** Draft v1.0
> **Decision deadline:** before the first sprint of the implementation plan starts
> **Owner:** Chief Product Lead (consolidated role; in practice: whoever runs the Planner/Executor loop)
> **Target release:** prototype only — this is not a shippable product

## 1. Problem statement

Analysts and LEO partners use the I4G web console (`ui/apps/web/`) at their desks. A meaningful
fraction of their work — triage, quick review approvals, checking case status while coordinating with
a partner — happens away from a desk. Today that work is blocked or awkward because:

- The web console is laid out for wide screens and mouse input.
- VPN / IAP setup on a partner's laptop is brittle and slow.
- Phones are always in hand; laptops aren't.

We also have zero institutional knowledge about building mobile software. Every future mobile feature
will re-pay a setup tax unless we build the methodology now.

## 2. Goals

### 2.1 Product goals

- **G1.** Give analysts a focused mobile surface for "on-the-go" tasks: see the queue, see a case, see
  evidence and reports, and act on a review decision.
- **G2.** Preserve every privacy guarantee the web console preserves — no raw PII on the device, no
  API shortcut that bypasses audit logging.
- **G3.** Work against the local-aio Docker image with **zero** backend changes, and against the GCP
  dev environment with only config changes.

### 2.2 Process / enablement goals (equally important)

- **G4.** A developer with **no prior mobile experience** can follow the developer guide and ship a
  working build to their own iPhone **and** Android phone in **under one working day**.
- **G5.** Establish a repeatable development methodology (toolchain, repo layout, CI, release flow)
  that every future mobile effort inherits without rediscovery.
- **G6.** Every architectural decision that would be expensive to reverse is captured in the
  architecture doc with alternatives considered.

## 3. Non-goals

- Not a shippable 1.0. No App Store / Play Store release.
- Not feature parity with the web console. We pick a **coherent slice**, not a breadth test.
- Not a new backend. We consume existing endpoints as-is. If something isn't exposed, it's out of
  scope for the prototype.
- Not a rewrite of the web console in mobile form. Design tokens are shared; layouts are native.
- Not multi-tenant offline. A last-viewed cache (TanStack Query default) is all we target.
- Not push notifications. Designed for, not implemented.

## 4. Primary persona — "On-the-go Analyst"

- **Who:** A volunteer I4G analyst. Mid-week evening, away from her desk, on a phone.
- **What she needs in 60 seconds or less:** "What's waiting for me? Is anything urgent? Can I clear
  one or two items now so tomorrow is lighter?"
- **Constraints:** Possibly on cellular. One-handed use. Screen brightness in public. Interrupted
  workflow (phone rings, walks into a store) — the app has to survive backgrounding.

Secondary personas (read-only in this prototype, upgraded later): **LEO partner** (approved-report
viewer), **Internal admin** (none of this; admin remains web-only).

## 5. User journeys — the prototype slice

The scope is a **minimum coherent slice**: every screen exists because removing it would leave a
dangling reference or an incomplete story.

| #   | Journey                                                           | Endpoints touched                               | Screens                        |
| --- | ----------------------------------------------------------------- | ----------------------------------------------- | ------------------------------ |
| J1  | Open the app, authenticate (mock locally, Google+IAP in dev)      | `/auth/*`, identity provider                    | Splash, Sign-in                |
| J2  | Land on a dashboard that answers "what's waiting for me?"         | `/reviews/search` (counts), `/tasks/*` (recent) | Dashboard                      |
| J3  | Browse the triage queue, filter by status, search by id/title     | `/reviews/search`, `/reviews/search/history`    | Reviews Queue                  |
| J4  | Open a case: summary, classification, timeline, audit log         | `/reviews/{id}`, case detail endpoints          | Case Detail                    |
| J5  | Preview evidence (thumbnails, image zoom, PDF viewer for reports) | evidence URL endpoints, `/reports/{id}`         | Evidence Detail, Report Viewer |
| J6  | **Act**: approve or reject a review with a comment                | `POST /reviews/{id}/decision` (or equivalent)   | Decision Sheet                 |
| J7  | Switch backend environment, sign out, see app version             | local-only                                      | Settings                       |

**Total: 8 screens.** Enough to exercise navigation, list/detail, media, mutation, and config —
without exercising every edge case.

> **Why the "approve/reject" write?** It proves the full round-trip that every future mobile write
> action will need: fetch → mutate → optimistic UI → server confirmation → cache invalidation →
> audit-log reflection. Without one write path, the prototype doesn't prove the stack.

## 6. Scope decisions and the "what about X?" answers

| Candidate feature                | In / Out                     | Why                                                                    |
| -------------------------------- | ---------------------------- | ---------------------------------------------------------------------- |
| Case list (read)                 | **In** (J3)                  | Core on-the-go task.                                                   |
| Case detail (read)               | **In** (J4)                  | Core on-the-go task.                                                   |
| Evidence preview                 | **In** (J5)                  | Required to make case detail useful.                                   |
| Approve/reject review            | **In** (J6)                  | The one write. Proves the stack.                                       |
| Report viewer (PDF)              | **In** (J5)                  | Tests file-handling path and is low-risk read.                         |
| Dashboard counts                 | **In** (J2)                  | 60-second "what's urgent" need. Tiny surface.                          |
| Env switcher + sign-out          | **In** (J7)                  | Required for the local → dev → prod story.                             |
| Victim intake                    | Out                          | Write-heavy, new PII surface, not on-the-go.                           |
| Case creation                    | Out                          | Analyst creates cases at a desk, not on a phone.                       |
| Bulk actions                     | Out                          | Not a phone gesture.                                                   |
| Comments / collaboration         | Out                          | Needs a notification story we're deferring.                            |
| Saved searches CRUD              | Out (view-only if trivial)   | Analysts configure these at a desk.                                    |
| SSI operator console             | Out                          | Web-only for now. Mobile may view SSI outputs embedded in case detail. |
| Admin (feature flags, ingestion) | Out                          | Never on mobile.                                                       |
| Push notifications               | Out (designed-for)           | APNs/FCM provisioning out of prototype budget.                         |
| Offline beyond last-view cache   | Out                          | Defer until we have telemetry saying we need it.                       |
| Dark mode                        | **In** (if tokens supply it) | One-flag cost; looks bad at night otherwise.                           |

## 7. Framework choice (locked decision, with rationale)

**Chosen: React Native + Expo (Managed workflow, Dev Client).**

Evaluated in order of "fit for a novice solo dev shipping a prototype":

| Option                     | Verdict                  | Why                                                                                                                                                                                                                                         |
| -------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **React Native + Expo**    | ✅ **Chosen**            | TS + React (skills already used in `ui/`). Expo eliminates Xcode/Gradle build-file editing for 90% of tasks. Dev Client + OTA updates mean iterating on a physical device takes seconds, not minutes. Escape hatches to native when needed. |
| Native (SwiftUI + Compose) | ✗ Rejected for prototype | Two codebases, two toolchains (Xcode, Android Studio), two languages to learn. Unjustified for one developer building a prototype whose durability is deliberately short.                                                                   |
| Flutter                    | ✗ Rejected               | Excellent, but Dart is a third language for the team and Flutter's web/backend story doesn't help us reuse `ui/` code or tokens.                                                                                                            |
| PWA / responsive web       | ✗ Rejected               | Doesn't prove a mobile methodology; IAP + service workers fight on iOS; no path to push or camera later.                                                                                                                                    |

**Migration path to native:** If a future need justifies native (e.g., an AR evidence-capture tool),
we can (a) keep RN for the analyst app and ship native only for the specialized app, or (b) eject RN
to the bare workflow and gradually replace screens. This is documented in the architecture doc.

## 8. Success criteria

### 8.1 Product metrics (validated on the prototype, not in production)

- **Cold start to dashboard < 3 s** on a 2020-era iPhone against `localhost:8000`.
- **Queue list interactive < 1 s** after dashboard load (100 items, paginated).
- **Zero PII in device logs** (verified by a grep-the-logs test in the E2E suite).
- **Approve action round-trip < 2 s** end-to-end (tap → server-confirmed state).
- **Crash-free session rate > 99%** across the dogfooding week.

### 8.2 Process metrics (the real point of the prototype)

- A cold laptop → running app **on a physical device** in **< 4 hours** following only the developer
  guide. Measured by having a second person try it.
- A new screen (copy an existing one) takes **< 2 hours** from "git pull" to "PR open".
- CI is **< 10 minutes** on every PR (lint + typecheck + unit + one E2E).
- Docs stay fresh: every gotcha hit during implementation lands in the developer guide within the
  same PR that hit it.

## 9. Risks and mitigations

| Risk                                                                                     | Likelihood        | Impact | Mitigation                                                                                                                                                             |
| ---------------------------------------------------------------------------------------- | ----------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IAP + OAuth PKCE from a native client is fiddlier than from a browser                    | High              | Medium | Gate on `remote` profile only; use `expo-auth-session` with the well-trodden PKCE + `WebBrowser.openAuthSessionAsync` path; dedicate a full sprint day to the handoff. |
| Local-aio container on developer's laptop conflicts with a running `pnpm dev` on `:3000` | Medium            | Low    | Document both options clearly; default to `direct` mode (`:8000`) so BFF port conflict is opt-in.                                                                      |
| Novice dev gets stuck on simulator/emulator install                                      | High (first week) | Low    | Developer guide has a "zero-to-simulator" section with copy-pasteable commands and known-error table.                                                                  |
| Expo SDK breaking change mid-prototype                                                   | Low               | Medium | Pin SDK version in `package.json`; upgrade only after prototype acceptance.                                                                                            |
| Design tokens drift between `ui/` and `mobile/`                                          | Medium            | Low    | `mobile/shared/design-tokens/` already has Style Dictionary; add a CI check that `ui/` token hash matches generated mobile tokens.                                     |
| Backend endpoint assumed to exist actually doesn't                                       | Medium            | High   | TDD lists every endpoint the prototype needs; TDD acceptance step: hit each endpoint against local-aio before sprint 2 starts.                                         |
| We build something that only works on the developer's laptop                             | Medium            | High   | CI runs the full build on GitHub-hosted runners; acceptance requires a second person running the full flow on their laptop.                                            |

## 10. Open questions (track in implementation-plan, resolve before sprint starts)

1. Does the existing review-decision endpoint accept a free-text comment, or only a status enum? (**TDD blocker for J6.**)
2. Do reports come back as a signed URL or as a proxied stream? Affects whether the PDF viewer opens a URL directly or downloads first. (**TDD blocker for J5.**)
3. Is there an endpoint that returns dashboard counts cheaply, or do we derive from `/reviews/search?limit=0`? (**PRD scope question for J2.**)
4. For IAP + PKCE, do we need the LEO Google Workspace domain whitelist in dev, or is a personal Google account enough? (**Developer-guide question.**)

## 11. Acceptance (prototype)

The prototype is accepted when:

- All items in [README — Prototype definition of done](./README.md#prototype-definition-of-done) are
  checked.
- The change log entry is merged.
- The author has personally watched a second developer go through the developer guide end-to-end.

---

See [architecture.md](./architecture.md) for **how** this gets built into the platform,
[tdd.md](./tdd.md) for code-level design, [implementation-plan.md](./implementation-plan.md) for
sprint work, and [developer-guide.md](./developer-guide.md) for ramp-up.
