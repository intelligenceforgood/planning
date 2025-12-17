# TDD: i4g Mobile Clients (iOS & Android)

Aligned to `core/docs/design/architecture.md` and `core/docs/development/tdd.md`. Mobile clients are thin: no business logic divergence from FastAPI/Next.js; only UI and device concerns are localized.

## Architecture Overview
- **Clients**: Native iOS (SwiftUI) and Android (Kotlin/Jetpack Compose).
- **Auth**: Google OAuth2 with PKCE via AppAuth (in-app browser tab) → IAP session cookie set by LB. Token exchange goes to Google; API calls include IAP auth headers automatically via HTTPS session.
- **API Surface**: Reuse existing FastAPI REST endpoints; prefer the same base URL as web (`https://api.intelligenceforgood.org` behind LB/IAP). No direct Cloud Run hostnames.
- **Data Access**: Read-only for v1. No local mutations except view state. Optional local cache for offline read of last-viewed cases using encrypted storage.
- **Networking Stack**: iOS: URLSession + async/await; Android: OkHttp + Retrofit + Kotlin coroutines. Common concerns: retries with backoff, auth interceptor, gzip, timeout defaults.
- **State Management**: iOS: ObservableObject + Swift Concurrency; Android: Jetpack ViewModel + Flow/StateFlow.
- **DI/Config**: Environment-based config (dev/prod) sourced from a small config file per platform; no secrets in source.

## Security & Privacy
- Enforce HTTPS only; pin to the LB domain.
- Store tokens in OS-provided secure storage (Keychain / EncryptedSharedPrefs).
- Avoid persisting PII; cache only tokenized fields already provided by API. Do not log payloads.
- Respect least-privilege scopes: request only `openid`, `email`, `profile`.
- Leverage audit logging on backend; include a stable `X-Client-Version` header for traceability.

## API Contract Usage (subset of web)
- **List Cases**: GET `/api/cases?status=&offset=&limit=`
- **Case Detail**: GET `/api/cases/{id}` (read-only fields, tokenized PII)
- **Evidence**: GET signed URLs or proxied thumbnails (as provided by FastAPI/Next.js). Stream; avoid full download by default.
- **Reports**: GET download link for approved reports; open in in-app viewer or external PDF handler.
- **Activity Log**: GET case audit trail (if available) — read-only.

## Client Modules (per platform)
- **Auth**: PKCE flow, token storage, session refresh, IAP cookie handoff.
- **Networking**: API client, interceptors for auth headers, telemetry headers.
- **Data**: DTOs matching FastAPI schemas; lightweight cache; optional offline read for last-viewed cases.
- **Features**: Case List, Case Detail, Evidence Preview, Report Viewer, Settings (env switch, sign-out).
- **Design System**: Map to existing `ui/` tokens; create mobile-specific typography/spacing while keeping brand alignment.

## Testing Strategy
- **Unit**: DTO parsing, auth flow guards, cache logic, view-model state reducers.
- **Integration**: API client against mock server (WireMock/MockWebServer), auth against Google test client.
- **UI/E2E**: iOS UI tests (XCTest), Android Espresso; golden snapshots for key screens.
- **Security Checks**: Static analysis (SwiftLint/Detekt), secret scanning, certificate validation tests.

## Build & Delivery
- **iOS**: Xcode Cloud or fastlane; minimum iOS 15; CI for lint/test/build; TestFlight for internal.
- **Android**: Gradle + AGP; minimum Android 8; CI for lint/test/build; Internal App Sharing for QA.
- **Versioning**: Semantic app versions; align API compatibility with backend release notes.

## Observability
- Crash reporting (e.g., Sentry/Firebase Crashlytics), network error tagging, and basic performance metrics (TTFB, list load). No PII in logs.

## Open Technical Questions
- Should mobile go through Next.js BFF endpoints for evidence/report URLs, or call FastAPI directly? (Recommendation: reuse the web BFF if it injects auth headers or hides internal paths.)
- Do we need offline mode beyond last-viewed cases? If yes, define data retention windows and eviction policy.
- Push notifications: which provider (FCM/APNs)? Are case assignment events required in v1?
