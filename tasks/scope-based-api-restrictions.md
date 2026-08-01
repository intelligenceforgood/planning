# Task: Role & Scope-Based API Endpoint & OpenAPI Restrictions

**Objective:** Restrict API endpoint access and Swagger UI visibility so programmatic partner integrations are limited to fraud-related endpoints, while Web UI and Mobile sessions maintain full access. Deprecate `partner_mode`.

**Plan:** [implementation_plan.md](file:///Users/jerry/.gemini/antigravity/brain/1069f046-c200-4699-a360-7b6f0c8ab892/implementation_plan.md)

---

## Phase 1: Scope Registry & Auth-Source Tagging

- [x] 🟢 **Task 1.1:** Create scope registry module
  - **[NEW]** `core/src/i4g/api/scopes.py`
  - Define `AuthSource` string enum with values: `local`, `static_key`, `db_api_key`, `iap`, `bearer`
  - Define `PARTNER_ALLOWED_TAGS: set[str]` = `{"partner-feeds", "cases", "evidence", "reviews", "analytics", "discovery", "intelligence", "investigations", "ssi", "exports", "taxonomy"}`
  - Define `INTERNAL_ONLY_TAGS: set[str]` = `{"accounts", "api-keys", "tasks", "dashboard", "engagements", "campaigns", "impact", "feedback", "intakes", "playbooks", "actors", "discoveries", "ssi-events", "wallets", "reports", "health"}`
  - Follows existing enum patterns in `core/src/i4g/api/roles.py`

- [x] 🟡 **Task 1.2:** Add `auth_source` field to `require_token` return values
  - **[MODIFY]** `core/src/i4g/api/auth.py`
  - At each auth path in `require_token()`, add `"auth_source"` key to the returned dict:
    - Line ~206 (auth disabled): add `"auth_source": "local"` to `_LOCAL_USER`
    - Line ~217 (env-var API key, no forwarded user): add `"auth_source": "static_key"`
    - Line ~216 (env-var API key, forwarded user): add `"auth_source": "static_key"`
    - Line ~226-232 (DB-backed API key): add `"auth_source": "db_api_key"`
    - Line ~243 (IAP JWT): add `"auth_source": "iap"` — must also pass through `_maybe_resolve_forwarded_user`
    - Line ~254 (Bearer token): add `"auth_source": "bearer"` — must also pass through `_maybe_resolve_forwarded_user`
  - Also update `_maybe_resolve_forwarded_user()` to preserve `auth_source` from the input `service_user` dict
  - Purely additive — no behavioral change to existing callers
  - **Test:** Run `conda run -n i4g pytest tests/unit/api/test_auth_rbac.py -v` to confirm no regressions

- [x] 🟡 **Task 1.3:** Create `require_internal_session` dependency
  - **[MODIFY]** `core/src/i4g/api/scopes.py` (file created in Task 1.1)
  - Add `require_internal_session()` function — a FastAPI dependency that:
    1. Calls `require_token` (via `Depends`)
    2. Checks `user.get("auth_source")` — if `"db_api_key"`, check for `"admin:internal"` in scopes
    3. If `auth_source` is `"db_api_key"` and `"admin:internal"` not in scopes → raise `HTTPException(403, "API key access not permitted for this endpoint")`
    4. All other `auth_source` values (`local`, `static_key`, `iap`, `bearer`) → pass through
  - Import `require_token` from `i4g.api.auth`
  - **Test:** Unit test in Task 5.2

---

## Phase 2: Endpoint Access Enforcement

- [x] 🟢 **Task 2.1:** Add `require_internal_session` to accounts router
  - **[MODIFY]** `core/src/i4g/api/accounts.py`
  - Add `require_internal_session` import from `i4g.api.scopes`
  - Add `dependencies=[Depends(require_internal_session)]` to the `APIRouter()` constructor (alongside existing tags/prefix)
  - Existing per-endpoint `require_role("admin")` stays — this adds defense-in-depth
  - **Test:** `conda run -n i4g pytest tests/unit/api/test_accounts_api.py -v`

- [x] 🟢 **Task 2.2:** Add `require_internal_session` to admin API key endpoints
  - **[MODIFY]** `core/src/i4g/api/api_keys.py`
  - Add `require_internal_session` import from `i4g.api.scopes`
  - Add `Depends(require_internal_session)` to the `dependencies` list of the 3 admin endpoints:
    - `GET /admin/api-keys` (line ~182)
    - `DELETE /admin/api-keys/{key_id}` (line ~195)
    - `POST /admin/api-keys/partner` (line ~210)
  - Self-service endpoints (`POST /api-keys`, `GET /api-keys`, `DELETE /api-keys/{key_id}`) remain unchanged
  - **Test:** `conda run -n i4g pytest tests/unit/api/test_api_keys.py -v`

- [x] 🟢 **Task 2.3:** Add `require_internal_session` to task router
  - **[MODIFY]** `core/src/i4g/api/app.py`
  - Import `require_internal_session` from `i4g.api.scopes`
  - Change `task_router` line ~51: replace `Depends(require_token)` with `Depends(require_internal_session)` (it's a superset — calls `require_token` internally)
  - **Test:** `conda run -n i4g pytest tests/unit/api/test_route_auth.py -v`

---

## Phase 3: OpenAPI Schema Filtering

- [ ] 🟡 **Task 3.1:** Implement OpenAPI schema filtering in `create_app`
  - **[MODIFY]** `core/src/i4g/api/app.py`
  - Import `INTERNAL_ONLY_TAGS` from `i4g.api.scopes`
  - After all routers are registered in `create_app()`, override `app.openapi()`:
    1. Call FastAPI's default `get_openapi()` to build the full spec
    2. Filter: remove any path whose operation tags are a subset of `INTERNAL_ONLY_TAGS`
    3. Clean up orphaned tag definitions and component schemas
    4. Cache the filtered result in `app._partner_openapi_schema`
  - Store the full unfiltered schema separately for the internal docs endpoint
  - **Test:** Manual — start dev server, visit `/docs`, confirm admin endpoints are hidden

- [ ] 🟡 **Task 3.2:** Add `/docs/internal` and `/openapi-internal.json` routes
  - **[MODIFY]** `core/src/i4g/api/app.py`
  - Add `GET /openapi-internal.json` endpoint protected by `require_internal_session()` that returns the full unfiltered OpenAPI spec
  - Add `GET /docs/internal` endpoint that returns an HTML page rendering Swagger UI pointed at `/openapi-internal.json`
  - Both endpoints should be excluded from the filtered schema (`include_in_schema=False`)
  - **Test:** Manual — visit `/docs/internal` with admin auth, confirm full schema visible

---

## Phase 4: `partner_mode` Complete Removal

- [x] 🟢 **Task 4.1:** Remove `partner_mode` setting from `APISettings`
  - **[MODIFY]** `core/src/i4g/settings/sections/basic.py`
  - Removed `partner_mode` field definition from `APISettings` class.

- [x] 🟢 **Task 4.2:** Remove conditional `partner_mode` routing and legacy test file
  - **[MODIFY]** `core/src/i4g/api/app.py`
  - Removed `if settings.api.partner_mode:` conditional router inclusion in `create_app()`; all routers registered unconditionally.
  - **[DELETE]** `core/tests/unit/api/test_partner_mode.py`
  - Removed legacy test file `test_partner_mode.py`.

---

## Phase 5: Unit Tests & Documentation

- [x] 🟢 **Task 5.1:** Add `auth_source` unit tests
  - **[NEW]** `core/tests/unit/api/test_auth_source.py`
  - Test that `require_token` returns correct `auth_source` for each auth path:
    - `"local"` when `disable_auth=True`
    - `"static_key"` when `X-API-KEY` matches env-var key
    - `"db_api_key"` when `X-API-KEY` matches DB-backed key
    - `"iap"` when `X-Goog-IAP-JWT-Assertion` present and valid
    - `"bearer"` when `Authorization: Bearer ...` present and valid
  - Use existing test patterns from `test_auth_rbac.py` (monkeypatch + dependency overrides)
  - **Verify:** `conda run -n i4g pytest tests/unit/api/test_auth_source.py -v`

- [x] 🟢 **Task 5.2:** Add `require_internal_session` unit tests
  - **[NEW]** `core/tests/unit/api/test_internal_session.py`
  - Tests:
    - DB API key without `admin:internal` scope → 403
    - DB API key WITH `admin:internal` scope → allowed
    - IAP auth (`auth_source: "iap"`) → allowed (bypass)
    - Bearer auth (`auth_source: "bearer"`) → allowed (bypass)
    - Static key (`auth_source: "static_key"`) → allowed (bypass)
    - Local dev (`auth_source: "local"`) → allowed (bypass)
  - Create a small test FastAPI app with a `require_internal_session` endpoint (same pattern as `test_scope_middleware.py`)
  - **Verify:** `conda run -n i4g pytest tests/unit/api/test_internal_session.py -v`

- [x] 🟢 **Task 5.3:** Add endpoint enforcement regression tests
  - **[MODIFY]** `core/tests/unit/api/test_accounts_api.py`
    - Add test: DB API key user (admin role, `auth_source: "db_api_key"`) → 403 on `GET /accounts`
    - Add test: IAP user (admin role, `auth_source: "iap"`) → 200 on `GET /accounts`
  - **[MODIFY]** `core/tests/unit/api/test_api_keys.py`
    - Add test: DB API key → 403 on `GET /admin/api-keys`
    - Add test: DB API key → 200 on `GET /api-keys` (self-service still works)
  - **Verify:** `conda run -n i4g pytest tests/unit/api/test_accounts_api.py tests/unit/api/test_api_keys.py -v`

- [ ] 🟡 **Task 5.4:** Add OpenAPI filtering unit tests
  - **[NEW]** `core/tests/unit/api/test_openapi_filtering.py`
  - Tests:
    - `GET /openapi.json` — response does NOT contain paths tagged with any `INTERNAL_ONLY_TAGS`
    - `GET /openapi.json` — response DOES contain paths tagged with `PARTNER_ALLOWED_TAGS`
    - `GET /openapi-internal.json` (with admin/IAP auth override) → returns full schema including internal tags
    - `GET /openapi-internal.json` (with DB API key override, no `admin:internal` scope) → 403
    - Tag definitions in filtered schema don't include internal-only tags
  - **Verify:** `conda run -n i4g pytest tests/unit/api/test_openapi_filtering.py -v`

- [ ] 🟡 **Task 5.5:** Update architecture documentation
  - **[MODIFY]** `antigravity/knowledge/architecture/architecture.md`
  - Add "Scope Enforcement" subsection under Authentication:
    - Document `auth_source` field and its values
    - Document `require_internal_session()` pattern
    - Document `require_scope()` (existing) and when to use each
    - Document `PARTNER_ALLOWED_TAGS` / `INTERNAL_ONLY_TAGS` sets
    - Document OpenAPI filtering strategy (default filtered, `/docs/internal` for admins)
    - Note `partner_mode` deprecation and migration path

---

## Execution Summary

| Phase | Tasks | Tier | Notes |
|-------|-------|------|-------|
| 1 — Scope Registry & Auth-Source | 1.1, 1.2, 1.3 | 🟢🟡🟡 | Foundation — must be done first |
| 2 — Endpoint Enforcement | 2.1, 2.2, 2.3 | 🟢🟢🟢 | Mechanical — add dependency to routers |
| 3 — OpenAPI Filtering | 3.1, 3.2 | 🟡🟡 | Custom OpenAPI override logic |
| 4 — Deprecation | 4.1, 4.2 | 🟢🟢 | Trivial — add warnings |
| 5 — Tests & Docs | 5.1–5.5 | 🟢🟢🟢🟡🟡 | Follow existing test patterns |

**Recommended execution order:** Phase 1 → Phase 2 → Phase 4 → Phase 5 (tasks 5.1–5.3) → Phase 3 → Phase 5 (tasks 5.4–5.5)

**Next step:** Invoke `/work-on-task` for Task 1.1 to begin implementation.
