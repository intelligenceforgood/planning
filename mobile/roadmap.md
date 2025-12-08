# Mobile Roadmap (Draft)

## Phase 0 — Foundations (1-2 weeks)
- Create mobile repos/workspaces, CI skeletons (lint/test/build), shared design tokens import.
- Integrate Google OAuth2 PKCE via AppAuth; wire to IAP/LB domain (dev env).
- Build API client scaffolding with env switch (dev/prod) and telemetry headers.

## Phase 1 — Core Read-Only (3-4 weeks)
- Case list (filter by status), pagination, pull-to-refresh.
- Case detail view: summary, classification, timeline, evidence metadata, audit log.
- Evidence preview (thumbnails/streamed images), guarded downloads; report viewer (PDF link).
- Basic caching of last-viewed cases; sign-out and env toggle.

## Phase 2 — Quality & Security (2-3 weeks)
- Accessibility, dark mode parity with web tokens.
- Crash reporting, network telemetry, golden UI tests; security scanners (SwiftLint/Detekt, secret scan).
- Hardening: TLS domain pinning optional, stricter download gating on cellular.

## Phase 3 — Enhancements (post-v1)
- Push notifications for case assignment/updates (APNs/FCM); deep links to case detail.
- Limited write actions (status change, comments) if/when backend enables.
- Offline mode beyond last-viewed (define retention + eviction policy).

## Staffing & Dependencies
- 1 iOS + 1 Android senior engineer, 0.5 designer, 0.5 PM; 0.25 backend liaison.
- Backend/IAP/LB readiness (DNS, certs) must be stable; shared API schemas from FastAPI/Next.js.

## Milestones (T-shirt)
- M0: Auth + list skeleton (S)
- M1: Read-only feature parity subset (M)
- M2: Quality/security hardening (M)
- M3: Notifications/offline (L, optional)
