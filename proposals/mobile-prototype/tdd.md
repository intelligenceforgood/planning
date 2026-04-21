# TDD — I4G Mobile Prototype

> **Status:** Draft v1.0
> **Audience:** the developer implementing the prototype.
> **Prereqs read:** [prd.md](./prd.md), [architecture.md](./architecture.md).
> **Out of scope:** anything not in the PRD's prototype slice.

## 1. Tech stack (locked)

| Concern            | Choice                                                   | Version floor          | Why this one                                                                                                                                                 |
| ------------------ | -------------------------------------------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Language           | TypeScript                                               | 5.4+                   | Type safety; reuse of skills from `ui/`.                                                                                                                     |
| Framework          | React Native                                             | 0.81 (via Expo SDK 54) | Meets all targets; stable new architecture support. (Sprint 0 scaffold produced SDK 54 via `create-expo-app@latest`; we stayed on it rather than downgrade.) |
| Toolchain          | Expo (Managed) + Dev Client                              | SDK 54+                | No Xcode/Gradle file editing in the 80% path.                                                                                                                |
| Navigation         | Expo Router                                              | 3.x                    | File-based; familiar to anyone who's used Next.js app router.                                                                                                |
| Server state       | TanStack Query                                           | 5.x                    | Caching, invalidation, retries — all for free.                                                                                                               |
| UI state           | Zustand                                                  | 4.x                    | Tiny; no Providers.                                                                                                                                          |
| Runtime validation | Zod                                                      | 3.x                    | One DTO shape, runtime + TS.                                                                                                                                 |
| HTTP               | Native `fetch`                                           | —                      | No library needed; interceptor via a wrapper.                                                                                                                |
| Auth               | `expo-auth-session` + `expo-web-browser`                 | latest for SDK 54      | PKCE done right on both platforms.                                                                                                                           |
| Secure storage     | `expo-secure-store`                                      | latest                 | Keychain + EncryptedSharedPrefs.                                                                                                                             |
| Image/media        | `expo-image`, `react-native-pdf`                         | latest                 | `expo-image` is faster and caches; `react-native-pdf` is the de facto PDF viewer.                                                                            |
| Design tokens      | `mobile/shared/design-tokens/`                           | existing               | Style Dictionary → TS theme.                                                                                                                                 |
| Testing (unit)     | Jest (`jest-expo` preset) + React Native Testing Library | latest                 | Picked during Sprint 0 scaffold (see Appendix B); Vitest + RN friction isn't worth the half-day.                                                             |
| Testing (E2E)      | Maestro                                                  | 1.36+                  | Simple YAML flows; RN-aware; no Detox build headaches.                                                                                                       |
| Lint / format      | ESLint + Prettier (mirror `ui/`)                         | —                      | Consistent with the web repo.                                                                                                                                |
| Telemetry          | `sentry-expo` (opt-in)                                   | latest                 | Cross-platform; disabled in `local`.                                                                                                                         |

> **Test runner decision (settled in Sprint 0):** Jest with `jest-expo` preset. Vitest was listed
> as the preferred option in earlier drafts but was never adopted — the Sprint 0 Executor went
> straight to Jest to stay under the half-day budget.

## 2. Directory layout (inside `mobile/app/`)

```
mobile/app/
  app.config.ts                 # reads .env.<profile>, sets extra.profile / extra.apiBaseUrl
  package.json
  tsconfig.json
  babel.config.js
  .env.local.example
  .env.dev.example
  .env.prod.example
  app/                          # Expo Router
    _layout.tsx                 # root layout + providers
    sign-in.tsx
    (tabs)/
      _layout.tsx               # bottom tabs
      dashboard.tsx
      queue.tsx
      settings.tsx
    case/
      [id].tsx                  # Case Detail
      [id]/evidence/[eid].tsx   # Evidence Detail
      [id]/report.tsx           # Report viewer
  src/
    api/
      client.ts                 # ApiClient: fetch + interceptors
      errors.ts                 # typed error hierarchy
      index.ts                  # singleton getter
    auth/
      provider.ts               # AuthProvider interface
      mock.ts                   # mock provider
      google-pkce-iap.ts        # PKCE + IAP provider
      index.ts                  # select by EXPO_PUBLIC_AUTH_PROVIDER
    config/
      index.ts                  # reads expo-constants.manifest.extra
      types.ts                  # Profile, AuthProviderKey, ApiMode
    design/
      theme.ts                  # maps tokens → RN style primitives
      Text.tsx · Button.tsx · Card.tsx · Screen.tsx · …
    features/
      reviews/
        queries.ts              # useReviewsQueue, useCase, useDecide
        types.ts                # Zod schemas + inferred TS types
        components/             # queue row, filters, decision sheet
      reports/
        queries.ts
        types.ts
        components/
      evidence/
        queries.ts
        types.ts
        components/
      dashboard/
        queries.ts
        types.ts
    lib/
      logger.ts                 # redacted logger
      query-client.ts           # TanStack Query config
      error-boundary.tsx
      env.ts                    # pure constants derived from config
      i18n/en.ts                # strings
    telemetry/
      sentry.ts                 # initSentry(profile)
    store/
      ui.ts                     # Zustand: toasts, nav intents
  __tests__/                    # unit tests co-located or here; pick one
  e2e/
    flows/
      happy-path.yaml           # the single E2E we run in CI
```

## 3. Configuration

### 3.1 Env files

Only **public** values live in `.env.<profile>`. Tokens are never committed. Expo requires the
`EXPO_PUBLIC_` prefix for values readable at runtime.

`.env.local.example`

```
EXPO_PUBLIC_PROFILE=local
EXPO_PUBLIC_API_MODE=direct          # direct | bff | remote
EXPO_PUBLIC_API_BASE_URL=http://192.168.1.42:8000
EXPO_PUBLIC_AUTH_PROVIDER=mock       # mock | google-pkce-iap
EXPO_PUBLIC_GOOGLE_OAUTH_CLIENT_ID=   # empty for mock
EXPO_PUBLIC_OAUTH_REDIRECT_SCHEME=com.intelligenceforgood.i4g
EXPO_PUBLIC_SENTRY_DSN=              # empty = disabled
```

`.env.dev.example`

```
EXPO_PUBLIC_PROFILE=dev
EXPO_PUBLIC_API_MODE=remote
EXPO_PUBLIC_API_BASE_URL=https://dev.intelligenceforgood.org
EXPO_PUBLIC_AUTH_PROVIDER=google-pkce-iap
EXPO_PUBLIC_GOOGLE_OAUTH_CLIENT_ID=<web-oauth-client-id>.apps.googleusercontent.com
EXPO_PUBLIC_OAUTH_REDIRECT_SCHEME=com.intelligenceforgood.i4g
EXPO_PUBLIC_SENTRY_DSN=<dsn>
```

### 3.2 `app.config.ts`

```ts
import "dotenv/config";

export default ({ config }) => ({
  ...config,
  name: "I4G",
  slug: "i4g-mobile",
  scheme: process.env.EXPO_PUBLIC_OAUTH_REDIRECT_SCHEME,
  ios: { bundleIdentifier: "com.intelligenceforgood.i4g" },
  android: { package: "com.intelligenceforgood.i4g" },
  extra: {
    profile: process.env.EXPO_PUBLIC_PROFILE,
    apiMode: process.env.EXPO_PUBLIC_API_MODE,
    apiBaseUrl: process.env.EXPO_PUBLIC_API_BASE_URL,
    authProvider: process.env.EXPO_PUBLIC_AUTH_PROVIDER,
    googleClientId: process.env.EXPO_PUBLIC_GOOGLE_OAUTH_CLIENT_ID,
    sentryDsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  },
});
```

### 3.3 `config/index.ts`

```ts
import Constants from "expo-constants";
import { z } from "zod";

const Schema = z.object({
  profile: z.enum(["local", "dev", "prod"]),
  apiMode: z.enum(["direct", "bff", "remote"]),
  apiBaseUrl: z.string().url(),
  authProvider: z.enum(["mock", "google-pkce-iap"]),
  googleClientId: z.string().optional(),
  sentryDsn: z.string().optional(),
});

export const config = Schema.parse(Constants.expoConfig?.extra ?? {});
```

## 4. API client

### 4.1 Interface

```ts
// src/api/client.ts
export interface ApiClient {
  get<T>(path: string, schema: z.ZodType<T>, opts?: ReqOpts): Promise<T>;
  post<T>(
    path: string,
    body: unknown,
    schema: z.ZodType<T>,
    opts?: ReqOpts,
  ): Promise<T>;
  // patch / delete added as needed
}
```

### 4.2 Error hierarchy

```ts
// src/api/errors.ts
export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}
export class NetworkError extends ApiError {}
export class AuthError extends ApiError {}
export class ValidationError extends ApiError {} // Zod failed → backend drift
export class NotFoundError extends ApiError {}
export class ServerError extends ApiError {}
```

Screens render errors from a single `mapErrorToBanner(err)` helper. The error boundary catches the
rest.

### 4.3 Implementation sketch

```ts
// src/api/client.ts (abridged)
import { config } from "@/config";
import { AuthProvider } from "@/auth/provider";
import { logger } from "@/lib/logger";

export function createApiClient(auth: AuthProvider): ApiClient {
  async function request<T>(
    method: string,
    path: string,
    schema: z.ZodType<T>,
    body?: unknown,
  ) {
    const token = await auth.getAccessToken(); // null for mock
    const url = `${config.apiBaseUrl}${path}`;
    const headers: Record<string, string> = {
      Accept: "application/json",
      "X-Client": `i4g-mobile/${Constants.expoConfig?.version ?? "dev"}`,
    };
    if (token) headers.Authorization = `Bearer ${token}`;
    if (body != null) headers["Content-Type"] = "application/json";

    const res = await fetch(url, {
      method,
      headers,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (res.status === 401) {
      await auth.signOut();
      throw new AuthError(401, "unauth", "Session expired");
    }
    if (!res.ok) throw await buildErrorFromResponse(res);

    const json = await res.json();
    const parsed = schema.safeParse(json);
    if (!parsed.success)
      throw new ValidationError(res.status, "schema", parsed.error.message);
    return parsed.data;
  }
  return {
    get: (p, s, o) => request("GET", p, s),
    post: (p, b, s, o) => request("POST", p, s, b),
  };
}
```

Retries, timeouts, and backoff live in TanStack Query config, not in the client — the client is a
thin one-shot.

## 5. Auth providers

### 5.1 Interface

```ts
// src/auth/provider.ts
export interface AuthProvider {
  readonly kind: "mock" | "google-pkce-iap";
  initialize(): Promise<void>;
  signIn(): Promise<void>;
  signOut(): Promise<void>;
  getAccessToken(): Promise<string | null>; // null means "no auth header needed"
  getUser(): Promise<{ email: string; name: string; roles: string[] } | null>;
  onChange(cb: (state: AuthState) => void): () => void;
}
```

### 5.2 `mock`

```ts
// src/auth/mock.ts (abridged)
export const mockProvider: AuthProvider = {
  kind: "mock",
  async initialize() {},
  async signIn() {
    store.setUser({
      email: "analyst@local",
      name: "Local Analyst",
      roles: ["analyst"],
    });
  },
  async signOut() {
    store.clearUser();
  },
  async getAccessToken() {
    return null;
  }, // backend has identity disabled
  async getUser() {
    return store.user;
  },
  onChange: store.subscribe,
};
```

### 5.3 `google-pkce-iap`

Uses `expo-auth-session` with `AuthRequest({ responseType: 'code', scopes: ['openid','email','profile'], usePKCE: true })`.

Flow:

1. `signIn()` calls `promptAsync()` which opens `WebBrowser.openAuthSessionAsync`.
2. On success, exchange the `code` for tokens via `exchangeCodeAsync`.
3. Store `id_token` + `refresh_token` in `expo-secure-store` under namespaced keys.
4. `getAccessToken()` returns `id_token`, refreshing with the refresh token when `exp - 60s < now`.
5. `signOut()` clears secure storage and calls Google's revoke endpoint best-effort.

IAP accepts `Authorization: Bearer <id_token>` on the LB. If it returns `302` to a Google sign-in
page, we treat it as `AuthError` and re-sign-in.

### 5.4 Selection

```ts
// src/auth/index.ts
import { config } from "@/config";
import { mockProvider } from "./mock";
import { googlePkceIapProvider } from "./google-pkce-iap";

export const auth: AuthProvider =
  config.authProvider === "mock" ? mockProvider : googlePkceIapProvider;
```

## 6. Data contracts (Zod schemas)

We define a DTO per endpoint. Schemas live next to the feature hook that uses them.

Representative schemas (adjust names to match actual backend; see **§12 Endpoint catalog**):

```ts
// src/features/reviews/types.ts
import { z } from "zod";

export const ReviewStatus = z.enum([
  "pending",
  "approved",
  "rejected",
  "in_review",
]);
export type ReviewStatus = z.infer<typeof ReviewStatus>;

export const ReviewSummary = z.object({
  id: z.string(),
  title: z.string(),
  status: ReviewStatus,
  priority: z.enum(["low", "normal", "high"]).default("normal"),
  updatedAt: z.string(), // ISO
  evidenceCount: z.number().int().nonnegative(),
});

export const ReviewsQueue = z.object({
  items: z.array(ReviewSummary),
  total: z.number().int().nonnegative(),
  nextOffset: z.number().int().nullable(),
});

export const CaseDetail = ReviewSummary.extend({
  summary: z.string(),
  classification: z.object({
    taxonomy: z.array(z.string()),
    confidence: z.number().min(0).max(1),
  }),
  timeline: z.array(
    z.object({
      ts: z.string(),
      kind: z.string(),
      message: z.string(),
    }),
  ),
  audit: z.array(
    z.object({
      ts: z.string(),
      actor: z.string(),
      action: z.string(),
      target: z.string(),
    }),
  ),
});

export const DecisionRequest = z.object({
  decision: z.enum(["approve", "reject"]),
  comment: z.string().min(0).max(1000),
});

export const DecisionResponse = z.object({
  id: z.string(),
  status: ReviewStatus,
  updatedAt: z.string(),
});
```

> Confirm exact field names during Sprint 1 (see PRD §10). Schemas are cheap to change early.

## 7. Feature hooks

```ts
// src/features/reviews/queries.ts (abridged)
export function useReviewsQueue(params: {
  status?: ReviewStatus;
  q?: string;
  offset?: number;
}) {
  return useQuery({
    queryKey: ["reviews-queue", params],
    queryFn: () => api.get(`/reviews/search?${toQs(params)}`, ReviewsQueue),
    staleTime: 60_000,
  });
}

export function useCase(id: string) {
  return useQuery({
    queryKey: ["case", id],
    queryFn: () => api.get(`/reviews/${id}`, CaseDetail),
    staleTime: 60_000,
  });
}

export function useDecide(id: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: z.infer<typeof DecisionRequest>) =>
      api.post(`/reviews/${id}/decision`, body, DecisionResponse),
    onMutate: async (body) => {
      await qc.cancelQueries({ queryKey: ["case", id] });
      const prev = qc.getQueryData<z.infer<typeof CaseDetail>>(["case", id]);
      if (prev)
        qc.setQueryData(["case", id], {
          ...prev,
          status: body.decision === "approve" ? "approved" : "rejected",
        });
      return { prev };
    },
    onError: (_e, _b, ctx) => {
      if (ctx?.prev) qc.setQueryData(["case", id], ctx.prev);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["reviews-queue"] });
    },
  });
}
```

## 8. Screens — behavior contracts

| Screen          | Loading                    | Empty               | Error                                                    | Success                                       |
| --------------- | -------------------------- | ------------------- | -------------------------------------------------------- | --------------------------------------------- |
| Sign-in         | Spinner during IdP handoff | —                   | Banner + retry button                                    | Navigate to Dashboard                         |
| Dashboard       | Skeleton cards             | "No items" card     | Inline error, retry                                      | 3 counts + recent list                        |
| Queue           | Skeleton rows              | "Nothing to triage" | Top banner, list reveals cached data if any              | Paginated list, pull-to-refresh               |
| Case Detail     | Skeleton sections          | —                   | Inline error per section (timeline independent of audit) | All sections rendered                         |
| Evidence Detail | Placeholder image          | —                   | Broken-image icon + retry                                | Image or metadata                             |
| Report Viewer   | PDF viewer loading         | —                   | Banner                                                   | Scrollable PDF                                |
| Decision Sheet  | Button spinner             | —                   | Inline under button                                      | Close sheet, toast "approved"                 |
| Settings        | —                          | —                   | —                                                        | Env info, sign-out, version, telemetry toggle |

## 9. Error, offline, and loading patterns

- **Network down:** TanStack Query retries 3× with exp backoff; after that, the top banner shows
  "You're offline — showing cached data." The cached data comes from the last successful fetch in
  this session (we do not persist across launches in the prototype).
- **Auth expired mid-session:** `AuthError` triggers a full sign-out and navigation to Sign-in.
- **Schema drift:** `ValidationError` shows a developer-friendly banner in `local`/`dev` profiles
  and a generic "Something went wrong" in `prod`. Sentry receives the Zod issue.
- **Foreground refresh:** TanStack Query's `refetchOnAppFocus` is enabled for the queue; disabled for
  heavy screens (case detail) to save bandwidth.

## 10. Logging and telemetry

- `logger.info|warn|error(tag, data)` — in dev, pretty-prints; in prod, routes to Sentry breadcrumb.
- **Never** log: request bodies, response bodies, tokens, email, any field in the PII allowlist. A
  single `src/lib/redact.ts` holds the list; a unit test asserts the logger uses it.
- Sentry init:
  ```ts
  if (config.sentryDsn)
    Sentry.init({
      dsn: config.sentryDsn,
      environment: config.profile,
      tracesSampleRate: 0.1,
      beforeSend: (event) => redactEvent(event),
    });
  ```

## 11. Testing plan

| Layer     | Tool                      | What we test                                                                       | Where it runs                                                 |
| --------- | ------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| Unit      | Vitest/Jest + RNTL        | DTO parsing, hooks with a mocked client, reducers, redact utility                  | CI                                                            |
| Component | RNTL                      | Render snapshot + interaction for Queue row, Decision Sheet                        | CI                                                            |
| Contract  | MSW (Mock Service Worker) | ApiClient happy + 4xx + 5xx + schema-drift                                         | CI                                                            |
| E2E       | Maestro                   | One happy path: sign-in (mock) → queue → case detail → approve → see status change | CI (Android emulator on GitHub Actions; iOS E2E runs locally) |

**Budget:** unit/component coverage target is **60% lines** for the prototype. Hunting percentages
past that is not a good ROI for a throwaway.

## 12. Endpoint catalog (must verify Sprint 1)

| Purpose                        | HTTP | Path (assumed)                                          | Source in `ui/`                         | Needs verification                  |
| ------------------------------ | ---- | ------------------------------------------------------- | --------------------------------------- | ----------------------------------- |
| Who am I                       | GET  | `/auth/whoami`                                          | web bootstraps user via `/api/me` proxy | ✓ name + payload                    |
| Dashboard counts               | GET  | `/reviews/search?status=pending&limit=0` (or dedicated) | `dashboard/` page                       | ✓ existence of cheap count endpoint |
| Queue search                   | GET  | `/reviews/search?status=&q=&offset=&limit=`             | `(console)/cases` or similar            | ✓ params                            |
| Queue history                  | GET  | `/reviews/search/history`                               | —                                       | ✓ optional for MVP                  |
| Case detail                    | GET  | `/reviews/{id}`                                         | `cases/[id]` page                       | ✓ shape                             |
| Evidence metadata              | GET  | `/reviews/{id}/evidence`                                | case detail API                         | ✓ shape                             |
| Evidence preview (image/thumb) | GET  | signed URL from metadata                                | —                                       | ✓ bearer vs signed URL              |
| Report view                    | GET  | `/reports/{id}` → PDF URL                               | `reports/` page                         | ✓ URL vs proxied stream             |
| Decision                       | POST | `/reviews/{id}/decision`                                | web approve button                      | ✓ body shape                        |
| Audit log                      | GET  | `/reviews/{id}/audit` (or embedded in detail)           | —                                       | ✓ existence                         |

Confirming these endpoints is the **first Sprint 1 task**. Any assumed endpoint that doesn't exist
becomes a PRD amendment, not a silent scope cut.

## 13. CI

`mobile/app/` CI on every PR:

1. `pnpm install`
2. `pnpm lint` (ESLint + Prettier)
3. `pnpm typecheck` (`tsc --noEmit`)
4. `pnpm test` (unit + component + contract)
5. `pnpm e2e:android` (Maestro against Android emulator image; iOS E2E runs on dev's laptop, not CI)
6. `pnpm build:preview` (`eas build --profile preview` — optional; runs weekly, not per-PR)

Budget: 10 minutes per PR on a GitHub-hosted runner.

## 14. Security checklist (must pass before merge)

- [ ] No token, email, or PII field appears in any `console.log` in the repo (CI grep).
- [ ] All API calls go through `ApiClient` (CI grep for raw `fetch(` outside `src/api/`).
- [ ] `SecureStore` is the only persistence for tokens (CI grep for `AsyncStorage`).
- [ ] `http://` is allowed **only** in `local` profile (runtime guard; throws in `remote`).
- [ ] Sentry has a `beforeSend` redactor installed (unit test).
- [ ] `Info.plist` / `AndroidManifest.xml` list only the permissions we actually use (none beyond
      network for the prototype).

## 15. Performance budget

| Metric                     | Budget                            |
| -------------------------- | --------------------------------- |
| Cold start to first paint  | 3 s (local), 4 s (dev)            |
| Queue list TTI (100 items) | 1 s after dashboard               |
| Case detail TTI            | 1.5 s                             |
| Image thumb load           | 500 ms on Wi-Fi                   |
| JS bundle size             | <6 MB uncompressed (report in CI) |

`expo-image` + code-splitting by route keeps this easy to hit; if it regresses, the culprit is
almost always a heavy lib added without review.

## 16. Things we will not build even though a library exists for them

- **Redux / Redux Toolkit.** TanStack Query + Zustand cover the prototype.
- **NativeWind / styled-components.** Use the generated theme + RN `StyleSheet`. One less tool.
- **React Navigation (non-router).** Expo Router wraps it; don't use both APIs.
- **A custom form lib.** One mutation form in the whole prototype — controlled inputs are fine.

---

Next: [implementation-plan.md](./implementation-plan.md).
