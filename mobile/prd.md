# PRD: i4g Mobile (iOS & Android)

## Purpose
Deliver iOS and Android apps that let analysts and LEOs perform the core workflows already available in the Next.js console (`ui/`). Mobile is a **subset**: no new backend capabilities; respect the privacy-by-design architecture in `core/docs/design/architecture.md` and the contracts in `core/docs/development/tdd.md`.

## Goals
- Provide secure, responsive access to assigned cases, evidence, and reports.
- Support on-call and field work (LEO) with minimal friction.
- Preserve zero-trust guarantees: no raw PII leakage, consistent audit logging.

## Non-Goals (v1)
- Victim intake or public submissions from mobile.
- Admin-only controls (feature flags, ingestion tuning) — remain on web/Streamlit.
- Large-file uploads from mobile (defer until network + UX hardened).

## Personas
- **Analyst**: triage, review evidence, approve reports.
- **LEO**: read-only access to approved cases/reports.
- **Internal Admin** (future): light ops dashboards (post-v1).

## Key User Journeys (v1)
1. **Sign-in with Google (OAuth/PKCE)** behind IAP/LB; session reuse across app launches.
2. **Case list**: filter by status; search by case id/title.
3. **Case detail**: view summary, timeline, evidence metadata/preview (no raw PII), classification tags.
4. **Evidence preview**: view images/PDF thumbnails, stream small files; defer large downloads unless Wi‑Fi.
5. **Report access**: view/generate-download link for approved reports; open in secure viewer.
6. **Activity log**: show audit actions on the case (read-only).

## Out of Scope (v1)
- Editing case metadata; changing assignees.
- Case creation/intake flows.
- Bulk actions; export batches.
- Push notifications (consider v1.1).

## Success Metrics
- Time-to-first-case-load < 10s on 4G; 95th percentile case-detail load < 5s after list load.
- Crash-free sessions > 99%.
- Sign-in success rate > 98% for enrolled users.
- No PII exposure regressions (validated via security review/audit logs).

## Dependencies & Constraints
- Backend/API: FastAPI + Cloud SQL as defined in `core/docs/development/tdd.md`.
- Auth: Google OAuth2 with PKCE; enforced via IAP at the LB; group-based access (analyst/LEO).
- Data: read-only API paths exposed via existing APIs; no new public endpoints.
- Device support: iOS 15+ (SwiftUI), Android 8+ (Kotlin/Jetpack Compose).
- Network: handle intermittent connectivity; allow cached read-only views for already-fetched cases.

## Risks
- Cert/IAP flows on mobile OAuth (PKCE + IAP session) may require AppAuth/browser tabs; ensure UX clarity.
- Evidence size/format may be heavy for mobile; need guarded downloads and previews.
- Group-based access must mirror IAP/Cloud Run policies; drift between envs can block sign-in.

## Acceptance (v1)
- Analysts/LEOs can sign in, list cases, open case details, preview evidence thumbnails, and open/download approved reports using only existing backend contracts.
- All traffic flows through the LB/IAP path; no bypass to raw Cloud Run URLs.
- App passes security review (no PII in logs, secure storage, TLS pinning optional but recommended).
