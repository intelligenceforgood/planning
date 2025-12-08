# Open Questions

## Product
- Should mobile support victim intake in a later release, or stay analyst/LEO only?
- Do we need push notifications for case assignment/updates in v1, or defer to v1.1?
- What is the minimum offline capability expected (read-only cache vs. full offline flows)?

## Security & Auth
- Should mobile call FastAPI directly or reuse the Next.js BFF routes to hide internal endpoints and inject service tokens?
- Are we required to enforce TLS pinning for the LB domain?
- Any additional scopes beyond `openid email profile` for mobile auth?

## Evidence/Reports
- Max evidence size to stream on mobile; should we force Wi‑Fi for large files?
- Can we downscale/thumbnail evidence server-side specifically for mobile to save bandwidth?
- Should report downloads be time-limited signed URLs or proxied through the BFF?

## Design/Parity
- Which web features are mandatory for v1 vs. can slip? (e.g., audit log view, search facets, filters)
- Do we need dark mode at launch to match web tokens?

## Operations
- Preferred crash/analytics stack (Sentry vs. Firebase Crashlytics/Analytics)?
- Release cadence expectations (weekly betas vs. monthly)?
