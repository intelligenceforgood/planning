# API Key Authentication — Task Checklist

**Objective:** Implement DB-backed programmatic API key authentication for partner access, unifying the existing `partner_api_keys` table into a platform-wide `api_keys` system with self-service management UI and dedicated partner ingress.

**Decided Options:**
- IAP Bypass: **Option A** — Separate `partner-api` Cloud Run service without IAP
- Schema: **Unify** — Rename `partner_api_keys` → `api_keys` with `key_type` discriminator
- Key Format: `i4g_{type_code}_{random32}` (e.g., `i4g_pk_a3f8b2c1...`)
- Rate Limiting: Per-key (`rate_limit_per_minute` column, already exists)
- Scopes: Formalized (e.g., `cases:read`, `indicators:read`, `partner:feed`)

---

## Phase 1: DB Schema & Core API Key Engine (`core/`)

> Foundation — must be completed before any other phase.

- [x] 🔴 **1.1 — Alembic migration: rename `partner_api_keys` → `api_keys` and add columns**
  - **File:** `core/src/i4g/migrations/versions/<next_rev>_unify_api_keys.py` `[NEW]`
  - **Changes:**
    - `op.rename_table("partner_api_keys", "api_keys")`
    - Add column `key_type` (Text, server_default `'partner'`, NOT NULL)
    - Add column `description` (Text, nullable)
    - Add column `owner_email` (Text, nullable — backfill from `created_by`)
    - Rename indices `idx_partner_keys_*` → `idx_api_keys_*`
    - Add unique index on `key_hash` if not present
    - Backfill: `UPDATE api_keys SET owner_email = created_by WHERE key_type = 'partner'`
  - **Down revision:** Chain after latest migration in `core/src/i4g/migrations/versions/`
  - **Acceptance criteria:**
    - `conda run -n i4g alembic upgrade head` succeeds on fresh and existing DBs
    - `conda run -n i4g alembic downgrade -1` cleanly reverses
    - Existing partner key rows retain all data with `key_type='partner'`

- [x] 🟡 **1.2 — Update `sql.py` table definition: `partner_api_keys` → `api_keys`**
  - **File:** [sql.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/store/sql.py#L973-L989) `[MODIFY]`
  - **Changes:**
    - Rename Python variable `partner_api_keys` → `api_keys`
    - Add columns: `key_type`, `description`, `owner_email`
    - Update index names
    - Keep backward-compat alias: `partner_api_keys = api_keys` (temporary, for migration safety)
  - **Acceptance criteria:**
    - `from i4g.store.sql import api_keys` works
    - `from i4g.store.sql import partner_api_keys` still works (alias)
    - All existing table columns preserved

- [x] 🟡 **1.3 — Create `ApiKeyStore`**
  - **File:** `core/src/i4g/store/api_key_store.py` `[NEW]`
  - **Changes:**
    - Class `ApiKeyStore` using synchronous `session_factory()` pattern
    - Methods: `create_key()`, `validate_key()`, `list_keys_for_owner()`, `list_all_keys()`, `revoke_key()`, `delete_key()`
    - Private helpers: `_generate_key(key_type)` → `(prefix, raw_key)`, `_hash_key(raw_key)` → SHA-256 hex
    - Key format: `i4g_pk_<random32>` (partner), `i4g_uk_<random32>` (user), `i4g_sk_<random32>` (service)
    - `create_key()` returns `(raw_key, key_record)` — raw key NEVER stored
    - `validate_key()` updates `last_used_at` atomically
  - **Acceptance criteria:**
    - Unit tests pass for all CRUD operations
    - Raw key is never persisted to DB (verified by inspecting stored `key_hash`)
    - Expired and revoked keys return `None` from `validate_key()`

- [x] 🟢 **1.4 — Add `build_api_key_store()` factory**
  - **File:** [factories.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/services/factories.py) `[MODIFY]`
  - **Changes:**
    - Add `build_api_key_store() → ApiKeyStore` following existing `build_analytics_store()` pattern
  - **Acceptance criteria:**
    - `from i4g.services.factories import build_api_key_store` works
    - Returns valid `ApiKeyStore` instance

- [x] 🔴 **1.5 — Integrate DB-backed API key validation into `auth.py`**
  - **File:** [auth.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/api/auth.py) `[MODIFY]`
  - **Changes:**
    - Add new resolution step **after** static API key, **before** IAP JWT:
      ```
      2.   Static API key (existing)
      2.5  DB-backed API key → ApiKeyStore.validate_key(x_api_key)
      3.   IAP JWT (existing)
      4.   Bearer token (existing)
      ```
    - If `X-API-KEY` header present and static key doesn't match → fall through to DB lookup
    - On DB key match: use `owner_email` for identity, resolve role from `accounts` table via `_resolve_role()`
    - Attach `key_scopes` to result dict (e.g., `user["scopes"] = key_record["scopes"]`)
    - Respect `X-I4G-Forwarded-User` for DB keys (same as static key path)
  - **Acceptance criteria:**
    - Existing auth paths (local bypass, static key, IAP JWT, Bearer) unchanged
    - DB-backed key resolves identity + role correctly
    - Expired/revoked DB key → 401 (falls through to IAP/Bearer, then 401)
    - `conda run -n i4g pytest tests/unit/api/test_auth.py -v` passes

- [x] 🟡 **1.6 — Migrate `partner_feed.py` to use `ApiKeyStore`**
  - **File:** [partner_feed.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/api/partner_feed.py) `[MODIFY]`
  - **Changes:**
    - Replace `_authenticate_partner()` internal SQL with `ApiKeyStore.validate_key()`
    - Remove standalone `_hash_key()` function
    - Update table import: `from i4g.store.sql import api_keys` (use alias for now)
    - Add scope guard: validated key must have scope `partner:feed` or `key_type == 'partner'`
    - Keep `_check_rate_limit()` and `_log_feed_access()` unchanged
    - Update `_log_feed_access()` audit table reference if needed
  - **Acceptance criteria:**
    - Partner feed authentication works identically to before
    - `conda run -n i4g pytest tests/unit/api/test_partner_feed.py -v` passes (if exists)
    - Non-partner keys without `partner:feed` scope are rejected at partner endpoints

- [x] 🟢 **1.7 — Update ancillary references**
  - **Files:**
    - [cli/db/__init__.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/cli/db/__init__.py#L330) `[MODIFY]` — update `_WIPE_TABLE_ORDER`: `partner_api_keys` → `api_keys`
    - [test_security.py](file:///Users/jerry/Work/project/i4g/core/tests/unit/test_security.py#L62-L66) `[MODIFY]` — update table existence assertion
    - [storage.md](file:///Users/jerry/Work/project/i4g/core/docs/design/storage.md) `[MODIFY]` — update table name in infrastructure tables list
    - [partner_feed_monitoring.md](file:///Users/jerry/Work/project/i4g/core/docs/runbooks/console/partner_feed_monitoring.md) `[MODIFY]` — update SQL query examples
  - **Acceptance criteria:**
    - `grep -r "partner_api_keys" core/src/ core/tests/ core/docs/` returns zero results (except alias in sql.py)

- [x] 🟡 **1.8 — Unit tests for `ApiKeyStore`**
  - **File:** `core/tests/unit/store/test_api_key_store.py` `[NEW]`
  - **Changes:**
    - Test `create_key()` — verify hash stored, raw key returned, prefix matches type code
    - Test `validate_key()` — valid key returns record, expired key returns None, revoked key returns None, non-existent key returns None
    - Test `last_used_at` updated on successful validation
    - Test `list_keys_for_owner()` — filtered by email, filtered by key_type
    - Test `list_all_keys()` — admin listing, active_only filter
    - Test `revoke_key()` — sets `is_active=False`
    - Test `delete_key()` — removes row
  - **Acceptance criteria:**
    - `conda run -n i4g pytest tests/unit/store/test_api_key_store.py -v` passes
    - All edge cases covered (expired, revoked, non-existent, duplicate email)

---

## Phase 2: Management API Endpoints & Admin Controls (`core/`)

> Depends on Phase 1. Provides CRUD API for key lifecycle.

- [x] 🟡 **2.1 — Create API key route handler with Pydantic models**
  - **File:** `core/src/i4g/api/api_keys.py` `[NEW]`
  - **Changes:**
    - Router: `APIRouter(prefix="/api-keys", tags=["api-keys"])`
    - Pydantic request/response models (using `CamelModel`):
      - `CreateApiKeyRequest(description: str, scopes: list[str] | None, expires_in_days: int | None)`
      - `CreateApiKeyResponse(raw_key: str, key_id: str, key_prefix: str, expires_at: datetime | None)` — raw_key ONLY here
      - `ApiKeyInfo(key_id, key_prefix, description, owner_email, key_type, scopes, is_active, expires_at, last_used_at, created_at)` — no hash
      - `ApiKeyListResponse(keys: list[ApiKeyInfo])`
    - Endpoints:
      - `POST /api-keys` — create key for authenticated user (uses `require_token`)
      - `GET /api-keys` — list caller's own keys
      - `DELETE /api-keys/{key_id}` — revoke own key
  - **Acceptance criteria:**
    - Create returns raw key exactly once; subsequent GET never returns raw key
    - Only owner can list/revoke their own keys
    - Proper 401/403 for unauthenticated/unauthorized requests

- [x] 🟡 **2.2 — Admin API key management endpoints**
  - **File:** `core/src/i4g/api/api_keys.py` `[MODIFY]` (same file as 2.1)
  - **Changes:**
    - `GET /admin/api-keys` — list all keys across all users (uses `require_role("admin")`)
    - `DELETE /admin/api-keys/{key_id}` — admin revoke any key
    - `POST /admin/api-keys/partner` — create partner-type key with custom scopes, `partner_name`, `rate_limit_per_minute`
      - Request model: `CreatePartnerKeyRequest(partner_name, owner_email, scopes, expires_in_days, rate_limit_per_minute)`
  - **Acceptance criteria:**
    - Non-admin users get 403 on admin endpoints
    - Admin can list/revoke keys belonging to any user
    - Partner key creation populates `key_type='partner'` and `partner_name`

- [x] 🟢 **2.3 — Register `api_keys` router in app.py**
  - **File:** [app.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/api/app.py) `[MODIFY]`
  - **Changes:**
    - `from i4g.api.api_keys import router as api_keys_router`
    - `app.include_router(api_keys_router)`
  - **Acceptance criteria:**
    - `/api-keys` and `/admin/api-keys` endpoints appear in `/docs`

- [x] 🟡 **2.4 — Unit tests for API key routes**
  - **File:** `core/tests/unit/api/test_api_keys.py` `[NEW]`
  - **Changes:**
    - Test full CRUD lifecycle: create → list → revoke → verify revoked
    - Test authorization: non-admin can't access admin endpoints
    - Test creation response contains raw key
    - Test list response does NOT contain raw key or hash
    - Test expired key creation (negative expires_in_days rejected)
    - Test partner key creation (admin only)
  - **Acceptance criteria:**
    - `conda run -n i4g pytest tests/unit/api/test_api_keys.py -v` passes

- [x] 🟢 **2.5 — Validate existing auth tests still pass**
  - **Files:** Existing test files (no modifications)
  - **Changes:** None — pure verification
  - **Acceptance criteria:**
    - `conda run -n i4g pytest tests/unit/api/test_auth.py tests/unit/test_security.py -v` passes
    - No regressions in partner feed tests

---

## Phase 3: User Settings UI & Key Generation Modal (`ui/`)

> Depends on Phase 2 API endpoints. Targets the `ui/` repo (Next.js).

- [x] 🟡 **3.1 — API client functions for key management**
  - **File:** `ui/apps/web/src/lib/api/api-keys.ts` `[NEW]`
  - **Changes:**
    - `createApiKey(req: CreateApiKeyRequest): Promise<CreateApiKeyResponse>`
    - `listApiKeys(): Promise<ApiKeyListResponse>`
    - `revokeApiKey(keyId: string): Promise<void>`
    - `adminListApiKeys(): Promise<ApiKeyListResponse>`
    - `adminRevokeApiKey(keyId: string): Promise<void>`
    - `createPartnerKey(req: CreatePartnerKeyRequest): Promise<CreateApiKeyResponse>`
    - All use `apiFetch()` from existing API client
  - **Acceptance criteria:**
    - TypeScript types match backend Pydantic models (camelCase)
    - Error handling follows existing patterns

- [x] 🟡 **3.2 — API key settings page**
  - **File:** `ui/apps/web/src/app/(console)/settings/api-keys/page.tsx` `[NEW]`
  - **Changes:**
    - Page title "API Keys" with breadcrumb navigation
    - Table: key prefix (masked), description, created date, expiry, last used, status badge (active/expired/revoked)
    - "Create New Key" button → opens modal (Task 3.3)
    - "Revoke" action per row with confirmation dialog
    - Empty state when no keys exist
  - **Acceptance criteria:**
    - Page loads and displays keys from API
    - Revoke action updates table without full reload
    - Responsive layout

- [x] 🔴 **3.3 — Key creation modal with one-time display**
  - **File:** `ui/apps/web/src/app/(console)/settings/api-keys/create-key-modal.tsx` `[NEW]`
  - **Changes:**
    - Modal form fields: description (required), expiry dropdown (30 days / 90 days / 1 year / custom / never)
    - On submit: calls `createApiKey()`, transitions to "key display" state
    - Key display state: read-only monospace field with raw key, copy-to-clipboard button
    - ⚠️ Warning banner: "This key will only be shown once. Store it securely."
    - Modal cannot be dismissed without clicking "I've copied the key" acknowledgement
    - After acknowledgement: modal closes, table refreshes
  - **Acceptance criteria:**
    - Raw key displayed only in modal, never in table
    - Copy-to-clipboard works
    - Closing browser tab during display doesn't persist key anywhere

- [x] 🟡 **3.4 — Admin user panel: API key management column**
  - **File:** `ui/apps/web/src/app/(console)/admin/users/page.tsx` `[MODIFY]`
  - **Changes:**
    - Add "API Keys" expandable section or column per user row
    - Show key count, last used date
    - "View Keys" expands to show key list with revoke actions
    - "Create Partner Key" button for admin-provisioned keys
  - **Acceptance criteria:**
    - Admin can see and manage keys for any user
    - Non-admin users don't see this section

- [x] 🟢 **3.5 — Add settings page to navigation**
  - **File:** `ui/apps/web/src/app/(console)/navigation.tsx` `[MODIFY]`
  - **Changes:**
    - Add "API Keys" link to settings navigation sidebar
    - Icon + label consistent with design system
  - **Acceptance criteria:**
    - Navigation item visible to all authenticated users
    - Active state when on `/settings/api-keys`

---

## Phase 4: Infrastructure Ingress & OpenAPI / Swagger Setup (`infra/` + `core/`)

> Depends on Phase 1-2. Can run in parallel with Phase 3.

- [x] 🔴 **4.1 — Terraform: partner ingress Cloud Run service (no IAP)**
  - **Files:**
    - `infra/modules/partner_ingress/main.tf` `[NEW]`
    - `infra/modules/partner_ingress/variables.tf` `[NEW]`
    - `infra/modules/partner_ingress/outputs.tf` `[NEW]`
    - `infra/stacks/app/main.tf` `[MODIFY]` — instantiate partner ingress module
  - **Changes:**
    - Cloud Run service `partner-api` using same Core Docker image
    - Environment variable `I4G_PARTNER_MODE=true`
    - Serverless NEG → Backend service (NO IAP) → URL map on `api.i4g.app`
    - Cloud Armor WAF policy for DDoS/abuse protection
    - Managed SSL certificate for `api.i4g.app`
    - IAM: only Cloud Run invoker (no IAP bindings)
  - **Acceptance criteria:**
    - `terraform plan` shows clean additions (no destructive changes to existing services)
    - `terraform fmt -check -recursive` passes
    - Partner API accessible at `api.i4g.app` without IAP redirect

- [x] 🟡 **4.2 — Partner mode route filtering in `app.py`**
  - **File:** [app.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/api/app.py) `[MODIFY]`
  - **Changes:**
    - Read `I4G_PARTNER_MODE` env var (or `settings.api.partner_mode`)
    - When `partner_mode=True`, only include routers tagged as partner-accessible:
      - `partner_feed_router` (existing)
      - `api_keys_router` (new — for key validation endpoint)
      - `health.router` (always)
    - Exclude internal routers (reviews, reports, cases, admin, etc.)
  - **Acceptance criteria:**
    - In partner mode: only partner-safe endpoints accessible
    - In normal mode: all endpoints accessible (unchanged)
    - Add `partner_mode` field to settings if needed

- [x] 🟡 **4.3 — OpenAPI security scheme configuration**
  - **File:** [app.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/api/app.py) `[MODIFY]`
  - **Changes:**
    - Import `from fastapi.security import APIKeyHeader, HTTPBearer`
    - Define schemes:
      ```python
      api_key_header = APIKeyHeader(name="X-API-KEY", auto_error=False)
      bearer_scheme = HTTPBearer(auto_error=False)
      ```
    - Update `require_token` to accept these as FastAPI security dependencies (for OpenAPI spec generation)
    - Swagger UI will show "Authorize" button with both options
  - **Acceptance criteria:**
    - `/docs` shows "Authorize" button
    - API key and Bearer token can be set in Swagger UI
    - Authentication still works identically via dependencies

- [x] 🟡 **4.4 — Scope enforcement middleware**
  - **File:** `core/src/i4g/api/middleware/scope_middleware.py` `[NEW]`
  - **Changes:**
    - Dependency factory: `require_scope(*scopes: str)` — checks `user.get("scopes", [])` against required scopes
    - Admin role bypasses scope checks
    - Partner feed routes use `require_scope("partner:feed")`
    - User self-service routes don't require specific scopes
  - **Acceptance criteria:**
    - API key with `["partner:feed"]` scope can access partner feed
    - API key without required scope gets 403
    - Admin users bypass scope checks

- [x] 🟢 **4.5 — Add `partner_mode` to settings**
  - **File:** [basic.py](file:///Users/jerry/Work/project/i4g/core/src/i4g/settings/sections/basic.py) `[MODIFY]`
  - **Changes:**
    - Add `partner_mode: bool = Field(default=False, validation_alias=AliasChoices("PARTNER_MODE", "API__PARTNER_MODE"))` to `APISettings`
  - **Acceptance criteria:**
    - `I4G_API__PARTNER_MODE=true` activates partner mode
    - Default is `False` (no behavior change)


---

## Phase 5: Documentation, Endpoint Exposure Rules & Verification (`docs/` + tests)

> Final phase — depends on all prior phases.

- [x] 🟢 **5.1 — Update `iam.md` with API key auth documentation**
  - **File:** [iam.md](file:///Users/jerry/Work/project/i4g/core/docs/design/iam.md) `[MODIFY]`
  - **Changes:**
    - Update auth chain to include step 2.5 (DB-backed API keys)
    - Document unified `api_keys` table schema (columns, types, constraints)
    - Document partner ingress architecture (Option A)
    - Document scope model and key lifecycle (creation → usage → rotation → revocation)
    - Move "Programmatic partner API keys" from Open Items to implemented section
  - **Acceptance criteria:**
    - Auth chain documentation matches actual code
    - All open items related to API keys marked as resolved

- [x] 🟢 **5.2 — Create partner-facing authentication guide**
  - **File:** `docs/book/api/authentication.md` `[MODIFY]`
  - **Changes:**
    - How to request an API key (contact admin or self-service)
    - Authentication header format: `X-API-KEY: i4g_pk_...`
    - Code examples: cURL, Python `requests`, and Python SDK
    - Available scopes and what they grant access to
    - Rate limiting behavior and error codes
    - Key rotation: create new → migrate → revoke old
    - Expiry behavior and renewal
  - **Acceptance criteria:**
    - Copy-pasteable code examples work against local dev server

- [x] 🟢 **5.3 — Create admin runbook for API key management**
  - **File:** `core/docs/runbooks/api-key-management.md` `[NEW]`
  - **Changes:**
    - Creating partner keys via API and UI
    - Revoking compromised keys (steps + SQL verification)
    - Auditing key usage (SQL queries against `api_keys` + `partner_feed_audit`)
    - Key rotation procedures
    - Incident response: bulk revocation
  - **Acceptance criteria:**
    - Runbook is actionable by on-call engineers

- [x] 🔴 **5.4 — Integration tests: full auth chain with DB-backed keys**
  - **File:** `core/tests/integration/test_auth_api_key_integration.py` `[NEW]`
  - **Changes:**
    - End-to-end lifecycle: create key → authenticate → access endpoint → revoke → verify 403
    - Verify all existing auth paths still work:
      - Local bypass (`I4G_ENV=local`)
      - Static API key (`settings.api.key`)
      - DB-backed API key (new)
    - Verify expired key returns 401 (falls through all resolvers)
    - Verify scope enforcement on partner feed
    - Verify `X-I4G-Forwarded-User` works with DB-backed keys
    - Verify `last_used_at` updated after successful auth
  - **Acceptance criteria:**
    - `conda run -n i4g pytest tests/integration/test_auth_api_key_integration.py -v` passes
    - Zero regressions in existing auth tests

- [x] 🟡 **5.5 — Full regression test suite**
  - **Files:** No new files — run existing test suite
  - **Changes:** None — pure verification
  - **Acceptance criteria:**
    - `conda run -n i4g pytest tests/unit/ -v` — all pass
    - `conda run -n i4g pre-commit run --all-files` — clean (two-pass)
    - `conda run -n i4g alembic upgrade head` on clean DB — succeeds
    - Manual: `/docs` shows Authorize button, partner feed works with existing keys

---

## Execution Summary

| Phase | Tasks | 🟢 Simple | 🟡 Moderate | 🔴 Complex |
|-------|-------|-----------|-------------|------------|
| 1 — DB + Store + Auth | 8 | 2 | 4 | 2 |
| 2 — CRUD API | 5 | 2 | 3 | 0 |
| 3 — UI | 5 | 1 | 3 | 1 |
| 4 — Infra + OpenAPI | 5 | 1 | 3 | 1 |
| 5 — Docs + Verification | 5 | 3 | 1 | 1 |
| **Total** | **28** | **9** | **14** | **5** |

### Recommended Execution Order

1. **Batch 1 (Planning Tier):** Tasks 1.1, 1.5 — schema design + auth integration require cross-cutting reasoning
2. **Batch 2 (Execution Tier):** Tasks 1.2, 1.3, 1.4, 1.7, 1.8 — follow established patterns
3. **Batch 3 (Execution Tier):** Tasks 1.6, 2.1-2.5 — API routes follow existing patterns
4. **Batch 4 (Mixed):** Phase 3 (UI) and Phase 4 (Infra) — can run in parallel
5. **Batch 5 (Execution Tier):** Phase 5 — documentation + verification

### Next Step

Invoke `/work-on-task` targeting **Task 1.1** (Alembic migration) to begin implementation.
