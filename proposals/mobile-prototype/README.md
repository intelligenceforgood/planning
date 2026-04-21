# I4G Mobile Prototype — Proposal Package

> **Status:** Draft v1.0 — ready for review
> **Author roles:** Chief Architect + Chief Product Lead (consolidated)
> **Supersedes:** everything previously under `planning/mobile/` (deleted in the same change)
> **Lifetime:** These docs are intentionally disposable — they exist to get the prototype built and the
> development methodology established. Once the prototype is accepted, the durable content moves to
> `mobile/docs/` and the relevant product PRDs.

## What this package contains

| Doc                                                | Audience                  | Purpose                                                                                      |
| -------------------------------------------------- | ------------------------- | -------------------------------------------------------------------------------------------- |
| [prd.md](./prd.md)                                 | Product + eng             | **WHAT** we're building and why. Persona, scope, success criteria, non-goals.                |
| [architecture.md](./architecture.md)               | Eng leadership            | **HOW** the mobile client fits into the I4G platform. Topology, auth, data flow, trade-offs. |
| [tdd.md](./tdd.md)                                 | Implementing eng          | **HOW** at code level. Stack, modules, API contract, state, error handling, testing.         |
| [implementation-plan.md](./implementation-plan.md) | Implementing eng + PM     | **WHEN/WHO**. Sprint-sized tasks, acceptance criteria, handoff boundaries.                   |
| [developer-guide.md](./developer-guide.md)         | A novice mobile dev (you) | **RAMP-UP**. Tools, env setup, day-in-the-life workflow, debugging, shipping.                |

Read in order: **PRD → Architecture → TDD → Implementation Plan → Developer Guide.**

## Top-level decisions (locked for the prototype)

1. **Framework:** React Native + Expo (Managed workflow, with Dev Client).
2. **Scope slice:** "Analyst Triage & Review on the go" — auth, dashboard, reviews queue, case detail, evidence/report viewer, one approve/reject write, settings.
3. **Backend binding:** runtime-switchable (`direct` FastAPI, `bff` Next.js, `remote` IAP-gated).
4. **Auth:** pluggable `AuthProvider` — `mock` (local-aio) and `google-pkce-iap` (GCP dev/prod).
5. **Distribution:** iOS Simulator + Android Emulator + physical-device sideload via Expo Dev Client. No paid developer accounts required.
6. **Design tokens:** reuse `mobile/shared/design-tokens/` (Style Dictionary) — already scaffolded.

Rationale is in the PRD (§ Framework choice) and the Architecture doc (§ Alternatives considered).

## Prototype definition of done

The prototype is complete when **all** of the following are true:

- [ ] A developer with no prior mobile experience can, following only `developer-guide.md`, go from
      zero to a running app on iOS Simulator **and** an Android Emulator **and** a physical iPhone **and**
      a physical Android device in under **one working day**.
- [ ] The app talks to the `i4g-local` Docker image (`core/docs/runbooks/local-aio.md`) out of the box
      with zero code changes — only env-file changes.
- [ ] The app can perform every screen in the scope slice against the local backend with realistic
      sample data, including the approve/reject write action.
- [ ] A one-command switch (changing `EXPO_PUBLIC_API_MODE` and `EXPO_PUBLIC_AUTH_PROVIDER`) points
      the same build at the GCP **dev** backend via IAP without recompiling.
- [ ] CI runs lint + typecheck + unit tests + a single E2E happy-path on every PR in under 10 minutes.
- [ ] The implementation plan's checkboxes are all ticked, the change log in `planning/change_log.md`
      has an entry, and `mobile/docs/` has the "keep forever" subset (README, contributing, token flow).

## Out of scope for the prototype (explicit)

- Victim intake from mobile (write-heavy, new auth surface, not an "on-the-go" task).
- Push notifications (APNs/FCM) — designed for but not wired.
- Offline beyond last-viewed cache (TanStack Query's default 5-minute stale window is plenty).
- App Store / Play Store submission (paid accounts required; procedure documented, not executed).
- SSI operator flows and admin console (web-first; mobile reads SSI artifacts via case detail only).
- iPad / tablet layouts (phone-first; layouts won't break on tablet but aren't optimized).

## How to use these docs during execution

- The implementation plan is the source of truth for **work**. Tick boxes as you go.
- The developer guide is the source of truth for **how to do the work**. Update it when you hit a
  gotcha that's not in it yet — future-you will thank you.
- Architecture + TDD + PRD are **reference**. They change only if a locked decision changes; amend
  them in place and note the amendment date.

## Cross-references

- Local stack: [`core/docs/runbooks/local-aio.md`](../../../core/docs/runbooks/local-aio.md)
- System architecture: [`core/docs/design/architecture.md`](../../../core/docs/design/architecture.md)
- Web UI (the functional reference): [`ui/apps/web/`](../../../ui/apps/web/)
- Design tokens (already scaffolded): [`mobile/shared/design-tokens/`](../../../mobile/shared/design-tokens/)
