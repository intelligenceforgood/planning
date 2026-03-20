# I4G Platform — Integration Contracts

**Last Verified:** March 2026  
**Audience:** Engineers, technical leads  
**Tier:** 1 — System architecture  
**Depends on:** [`system_narrative.md`](system_narrative.md)

This document is the authoritative record of how each component communicates with every other component. If a service call is not listed here, it is internal to a single repo and does not cross service boundaries.

---

## 1. UI → Core API (Primary Proxy)

The analyst console proxies all core API calls server-side. **The browser never calls `core-svc` directly.**

### Mechanism

| Property                  | Value                                                                                        |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| Proxy implementation      | Next.js catch-all route: `ui/apps/web/src/app/api/[...path]/route.ts`                        |
| Target URL construction   | `${I4G_API_URL \|\| NEXT_PUBLIC_API_BASE_URL \|\| "http://127.0.0.1:8000"}/${path}?{query}`  |
| Auth header (cloud)       | `Authorization: Bearer <OIDC identity token>` (audience = `I4G_IAP_CLIENT_ID` or `apiUrl`)   |
| Auth header (local)       | None (core has `disable_auth=true` in local)                                                 |
| User attribution header   | `X-I4G-Forwarded-User: <analyst email>` (extracted from incoming `X-Goog-IAP-JWT-Assertion`) |
| Optional API key          | `X-API-KEY: <I4G_API_KEY env var>` — only set when `I4G_API_KEY` is non-empty                |
| Body streaming            | `duplex: "half"` — request body streams through unchanged                                    |
| Stripped response headers | `content-encoding`, `content-length` (proxy re-streams with own encoding)                    |
| Caching                   | `cache: "no-store"` on all calls                                                             |

### What passes through

All API routes that are not explicitly handled by a named route handler hit this catch-all. Named routes (listed below) override with specialized behavior but use the same `apiFetch` helper and therefore the same auth pattern.

### Named route overrides

| Next.js route              | Core endpoint                 | Notes                     |
| -------------------------- | ----------------------------- | ------------------------- |
| `/api/reviews/*`           | `/reviews/*`                  | Review management         |
| `/api/search/*`            | `/reviews/search/*`           | Case search               |
| `/api/intakes/*`           | `/intakes/*`                  | Intake management         |
| `/api/dossiers/*`          | `/cases/*/dossier` or similar | Dossier retrieval         |
| `/api/feedback/*`          | `/feedback/*`                 | Feedback submission       |
| `/api/events/*`            | `/events` or SSE endpoint     | Server-Sent Events        |
| `/api/discovery/*`         | `/discovery/*`                | Discovery/entity explorer |
| Catch-all `/api/[...path]` | `/{path}`                     | All other routes          |

### Artifact proxy

`/artifacts/:path*` rewrites to `/api/artifacts/:path*` so that auth headers are threaded through the Next.js layer before serving static artifacts.

---

## 2. UI → SSI (eCX Routes Only)

**Only eCX-related routes** proxy directly to `ssi-svc`. All other SSI interactions go through `core-svc` (see contract 3).

### Mechanism

| Property                | Value                                                                         |
| ----------------------- | ----------------------------------------------------------------------------- |
| Proxy implementation    | `ui/apps/web/src/app/api/ssi/ecx/` via `ssi-proxy.ts` helper                  |
| Target URL construction | `${SSI_API_URL}/<ecx-path>` (`SSI_API_URL` env var required; throws if unset) |
| Auth (cloud)            | `Authorization: Bearer <OIDC identity token>` (audience = `SSI_API_URL`)      |
| Auth (local/localhost)  | None                                                                          |
| Cloud Run detection     | `K_SERVICE` env var present → cloud mode, fetch OIDC token                    |

### Routes proxied to ssi-svc directly

| Next.js route    | SSI endpoint           | Purpose                                               |
| ---------------- | ---------------------- | ----------------------------------------------------- |
| `/api/ssi/ecx/*` | `${SSI_API_URL}/ecx/*` | eCX submission status, polling, submission management |

---

## 3. UI → SSI (Investigation Routes via Core)

Investigation lifecycle routes are routed through `core-svc`. Core is the orchestrator — it owns the task record, deduplication, and job tracking.

| Next.js route                   | Core endpoint                     | Notes                                                                    |
| ------------------------------- | --------------------------------- | ------------------------------------------------------------------------ |
| `GET /api/ssi/investigations`   | `GET /investigations/ssi/history` | Investigation history                                                    |
| `POST /api/ssi/investigate`     | `POST /investigations/ssi`        | Trigger new site investigation (core deduplicates, then calls SSI)       |
| `GET /api/ssi/investigate/[id]` | `GET /investigations/{id}`        | Investigation status (polls `TASK_STATUS` in-memory store + DB fallback) |
| `GET /api/ssi/wallets`          | `GET /investigations/ssi/wallets` | Wallet-linked investigation results                                      |
| `GET /api/ssi/report/[id]`      | `GET /investigations/{id}/report` | SSI investigation report                                                 |

Auth for these follows contract 1 (same catch-all proxy + OIDC token).

---

## 4. Core → SSI (Trigger Investigation)

When the analyst console requests a new site investigation, `core-svc` pre-registers the task and forwards the request to `ssi-svc`.

### Request

```
POST {settings.ssi.service_url}/trigger/investigate
Authorization: Bearer <Google OIDC ID token>   (audience = service_url)
Content-Type: application/json

{
  "url": "https://scam-site.example.com",
  "scan_type": "<type>",
  "scan_id": "<uuid>",
  "push_to_core": true,
  "dataset": "<dataset-identifier>"
}
```

| Property               | Value                                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| Client                 | `httpx.Client(timeout=30.0)`                                                                           |
| Auth token method      | `google.oauth2.id_token.fetch_id_token(request, audience=service_url)`                                 |
| Auth fallback (local)  | Logs warning, makes unauthenticated call                                                               |
| Task pre-registration  | `TASK_STATUS[scan_id] = {"status": "queued", ...}` registered **before** the HTTP call                 |
| SSI service URL config | `settings.ssi.service_url` (`I4G_SSI__SERVICE_URL` env var) — warning at startup if unset in non-local |

### On SSI failure

If `ssi-svc` is unreachable or returns an error, `core-svc` logs the failure and surfaces it through the task status polling mechanism. The pre-registered task transitions to `failed`.

---

## 5. SSI → Core (Results and Live Events)

SSI sends data back to core through three mechanisms, depending on the invocation mode:

### 5a. Push Results (investigation complete)

After a full investigation completes (CLI or API invocation with `push_to_core=true`), SSI creates a case record in core:

```
POST {integration.core_api_url}/cases    (or equivalent endpoint)
X-API-KEY: <integration.core_api_key>
Content-Type: application/json

{ <case payload with investigation results, evidence references> }
```

Config (SSI `settings.default.toml`):

- `integration.core_api_url` — base URL of core-svc
- `integration.push_to_core` — boolean safety gate (defaults `true` in settings; also controllable per-invocation)

### 5b. Live Event Stream (`HttpEventSink`)

During a live investigation, SSI streams real-time events to core for display in the analyst console:

```
POST {integration.core_events_url}
X-API-KEY: <integration.core_api_key>
Content-Type: application/json

{ <investigation event payload — screenshot taken, URL visited, finding discovered, etc.> }
```

Config:

- `integration.push_events_to_core` — must be `true` to activate
- `integration.core_events_url` — specific events endpoint (not the same as `core_api_url`)

### 5c. Analyst Guidance Poll (`GuidancePollRelay`)

During a live investigation, SSI polls core for analyst commands (e.g., "visit this URL next", "flag this wallet"):

```
GET {integration.core_api_url}/investigations/{scan_id}/guidance
X-API-KEY: <integration.core_api_key>
```

Config:

- `integration.guidance_poll_enabled` — must be `true`
- `integration.guidance_poll_interval` — poll frequency (seconds)

### Core auth for SSI callbacks

Core's `require_token` dependency resolves service-to-service calls as follows (priority order):

1. Checks `X-API-KEY` header against `settings.api.key` — matches → `{username: "service", role: "admin"}`
2. If `X-I4G-Forwarded-User` is also present, resolves that email's role from the `accounts` table

> ⚠️ **Verification needed** — Confirm the exact case-creation endpoint that SSI calls in `push_to_core` mode. Check `ssi/src/ssi/integrations/core_client.py` or equivalent for the full payload schema.

---

## 6. TIFAP → Core Data Access

The Threat Intelligence and Fraud Analytics Pipeline (TIFAP) is **not a separate service**. It runs as an internal subsystem of `core-svc`, accessing Cloud SQL directly without crossing a service boundary.

| Property      | Value                                                                                    |
| ------------- | ---------------------------------------------------------------------------------------- |
| Access method | SQLAlchemy ORM within `core-svc` process — no HTTP call                                  |
| Key stores    | `ThreatCampaignStore`, `WatchlistStore`, `AnnotationStore`, `AnalyticsStore`             |
| Data consumed | Cases, entities, review actions, campaign records from Cloud SQL                         |
| Data produced | Threat annotations, entity links, campaign detection results — written to Cloud SQL      |
| API surface   | `GET /intelligence/*` and `GET /analytics/*` routers expose TIFAP results to the console |
| Trigger       | On-demand via API endpoint; no independent scheduler                                     |

There is no inter-service HTTP call. TIFAP reads and writes through the same database session as the rest of `core-svc`.

---

## 7. Cloud Scheduler → Cloud Run Jobs

Cloud Scheduler triggers Cloud Run jobs via the Cloud Run Jobs API (HTTP POST with OIDC auth). The invoker service account must have `roles/run.invoker` on each job.

### Request pattern (all jobs)

```
POST https://{region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/{project}/jobs/{job-name}:run
Authorization: Bearer <OIDC token>   (scheduler SA)
Content-Type: application/json

{ "overrides": { "containerOverrides": [{ "env": [...] }] } }
```

### Scheduled jobs inventory (dev environment)

| Scheduler name           | Target job           | Image             | Schedule                      | Purpose                                                                |
| ------------------------ | -------------------- | ----------------- | ----------------------------- | ---------------------------------------------------------------------- |
| `classification-sweeper` | `ingest-bootstrap`   | `ingest-job:dev`  | `*/5 * * * *` (every 5 min)   | Processes new intake records — OCR, entity extraction, vector indexing |
| `dossier-queue`          | `dossier-queue`      | `dossier-job:dev` | `0 3 * * *` (daily 03:00 UTC) | Generates investigation dossiers for flagged cases                     |
| `retention-purge`        | (ingest image)       | `ingest-job:dev`  | `0 */4 * * *` (every 4 hours) | Purges records beyond 90-day retention window                          |
| `ssi-ecx-poller`         | `ssi-svc` or SSI job | (SSI image)       | `*/15 * * * *` (every 15 min) | Polls eCX for threat intelligence submission responses                 |

> ⚠️ **Verification needed** — Confirm the exact target job for `retention-purge` and `ssi-ecx-poller`. Read `infra/environments/app/dev/terraform.tfvars` under `scheduled_run_jobs` for the complete and verified mapping.

---

## 8. Ingestion Pipeline (Intake → Ingest → Review Record)

This is an internal sequential workflow within the core system, handled by the job pipeline. No cross-service HTTP calls.

```
Step 1: Victim submits intake form
  → REST POST /intakes/ (core-svc)
  → Validates, stores intake record in Cloud SQL (PII fields encrypted with Fernet key)
  → Evidence files uploaded to GCS

Step 2: process-intakes job (triggered by classification-sweeper scheduler)
  → Reads new intake records from Cloud SQL
  → Downloads evidence files from GCS
  → Runs OCR (PaddleOCR / Pytesseract)
  → Extracts entities
  → Redacts victim contact info from case text (replaces with [VICTIM_EMAIL] / [VICTIM_PHONE] markers)
  → Writes case record + entities to Cloud SQL

Step 3: ingest-bootstrap job (same classification-sweeper trigger)
  → Reads unindexed case records from Cloud SQL
  → Generates vector embeddings via LLM
  → Writes embeddings to Vertex AI Search (cloud) or Chroma (local)
  → Marks records as indexed

Step 4: Review record available
  → Analyst console queries GET /reviews/search (HybridRetriever: vector + keyword)
  → Analyst reviews, annotates, approves in the console
  → review_actions logged to Cloud SQL
```

**Key invariant**: PII fields are encrypted at Step 1 and never appear in plaintext in case text (Step 2 redaction). The only path to plaintext contact data is `GET /intakes/{id}/contact` (dual-approval, audit-logged per the [Detokenization SOP](../../core/docs/policies/detokenization_sop.md)).
