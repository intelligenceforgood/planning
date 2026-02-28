# SSI Development Summary

> **Created**: February 28, 2026
> **Status**: Archive
> **Context**: Condenses `tasks/ssi_roadmap.md` (Feb 22–25, 2026) and `tasks/ssi_api_consolidation.md` (Feb 25–28, 2026) into a single reference for developers.

---

## What SSI Is

The **Scam Site Investigator (SSI)** is a three-phase investigation system: passive OSINT reconnaissance → active browser-agent interaction → intelligence synthesis. It investigates scam websites, extracts cryptocurrency wallet addresses, packages evidence for law enforcement, and feeds results into the i4g platform as cases.

**Key capabilities:** DNS/WHOIS/SSL/GeoIP recon, zendriver browser automation with LLM-guided navigation, wallet extraction (BTC/ETH/TRX/SOL/+), fraud classification, PDF + LEA evidence packages, STIX 2.1 IOC bundles, playbook engine, real-time WebSocket monitoring (local dev), and batch investigation mode.

---

## Architecture (current)

```
┌──────────────┐
│  Next.js UI  │
└──────┬───────┘
       │  All requests
       ▼
┌──────────────────┐         ┌──────────────────┐
│ fastapi-gateway  │────────▶│ ssi-investigate  │
│ (Cloud Run       │ trigger │ (Cloud Run Job)  │
│  Service)        │         │                  │
│                  │◀────────│ Browser + LLM +  │
│ ~20 routers      │  writes │ OSINT + evidence │
│ (core + SSI)     │  to DB  │                  │
│ IAP-protected    │         │ Writes directly  │
│                  │         │ to core DB + GCS │
└──────────────────┘         └──────────────────┘
       │                              │
       ▼                              ▼
   Cloud SQL                      GCS evidence
   (all tables)                   bucket
```

- **Single gateway** — all SSI endpoints live in `fastapi-gateway` (no standalone `ssi-api` service)
- **Shared database** — SSI tables (`site_scans`, `harvested_wallets`, `agent_sessions`, `pii_exposures`) are Alembic-managed in core's Cloud SQL
- **Cloud Run Job** — `ssi-investigate` runs browser + LLM + OSINT; writes results directly to shared DB
- **SSI repo** — retains its own `pyproject.toml`, CLI (`ssi investigate ...`), orchestrator, and standalone FastAPI app for local dev

---

## Development Timeline

### Phase 0–2: Foundation (Feb 18–22, 2026)

Built the SSI product from the AWH merge (see `archive/ssi_awh_merge_summary.md`):

- LLM provider abstraction (Ollama, Gemini, mock), PDF reports, built-in web UI
- GCP deployment (Terraform, Docker images, Secret Manager, Cloud Run)
- Evidence bundle + LEA package endpoints with GCS signed URLs
- Core case creation end-to-end (`CoreBridge.push_investigation()`)
- Console UI pages (investigate, history, detail, wallets, live monitoring)
- Hardening (budget gates, concurrent limits, retry policies, OSINT error handling)
- 717 tests (unit + integration)

### Phase 3A–3B: Platform Integration (Feb 24–25, 2026)

Wired SSI into the i4g platform:

- `POST /investigations/ssi` in core triggers Cloud Run Jobs
- `TaskStatusReporter` posts progress back to core's task system
- Console "Investigate URL" action with progress tracking and case linking
- IAP JWT audience fix (`iap_backend_audience` setting)
- VPC egress + Cloud NAT for WHOIS/RDAP reliability

### SSI API Consolidation (Feb 25–28, 2026)

Eliminated the standalone `ssi-api` Cloud Run Service — the biggest architectural change:

| Phase              | What Changed                                                                                             |
| ------------------ | -------------------------------------------------------------------------------------------------------- |
| **A — Docs**       | Updated topology diagrams, API reference, SSI docs, settings manifest                                    |
| **B — Database**   | `SsiStore` in core with factory; Alembic migration for 4 tables; 41 tests                                |
| **C — Endpoints**  | 4 routers migrated to core: investigations, wallets, evidence, playbooks (62 tests)                      |
| **D — UI**         | Removed dual-backend proxy; 4 data routes core-only; 2 trigger routes retain `SSI_API_URL` for local dev |
| **E — WebSocket**  | Deferred to CLI/local-dev; task polling sufficient for production                                        |
| **F — Infra**      | Staged decommission of `ssi-api` Cloud Run Service, IAP binding, Dockerfile, Terraform                   |
| **G — Shared DB**  | SSI writes directly to core's DB via `SSI_STORAGE__DB_URL`; CoreBridge eliminated for persistence        |
| **H — Validation** | Full deploy + smoke test on `i4g-dev` (all endpoints verified)                                           |

**Why consolidate:** The dual-service architecture created auth complexity (broken OIDC), UI routing complexity (conditional `SSI_API_URL`), data duplication (CoreBridge HTTP copies), and infra overhead (two Cloud Run Services + IAP bindings). The single-gateway approach eliminated all four problems.

---

## Key Files

### Core (gateway)

| File                                     | Purpose                                               |
| ---------------------------------------- | ----------------------------------------------------- |
| `core/src/i4g/api/ssi_investigations.py` | History, active, detail endpoints                     |
| `core/src/i4g/api/ssi_wallets.py`        | Wallet search, CSV/XLSX export                        |
| `core/src/i4g/api/ssi_evidence.py`       | Evidence bundle, LEA package, report PDF              |
| `core/src/i4g/api/ssi_playbooks.py`      | Playbook CRUD + test-match                            |
| `core/src/i4g/api/investigations.py`     | Trigger (`POST /investigations/ssi`) + task status    |
| `core/src/i4g/store/ssi_store.py`        | `SsiStore` — CRUD for all 4 SSI tables                |
| `core/src/i4g/services/factories.py`     | `build_ssi_store()` factory                           |
| `core/src/i4g/settings/sections/jobs.py` | `SsiJobSettings` (job name, SA, region, playbook dir) |

### SSI (investigation engine)

| File                                       | Purpose                                                       |
| ------------------------------------------ | ------------------------------------------------------------- |
| `ssi/src/ssi/investigator/orchestrator.py` | Main investigation entry point (passive → active → synthesis) |
| `ssi/src/ssi/store/scan_store.py`          | `ScanStore` — writes to shared DB via `SSI_STORAGE__DB_URL`   |
| `ssi/src/ssi/browser/`                     | zendriver browser automation + LLM client                     |
| `ssi/src/ssi/osint/`                       | DNS, WHOIS, SSL, GeoIP, VirusTotal, urlscan.io                |
| `ssi/src/ssi/evidence/`                    | STIX bundles, evidence storage (local + GCS)                  |
| `ssi/src/ssi/reports/pdf.py`               | PDF report generation (markdown → HTML → WeasyPrint)          |
| `ssi/src/ssi/api/app.py`                   | Standalone FastAPI app (local dev only)                       |
| `ssi/docker/ssi-job.Dockerfile`            | Cloud Run Job image (browser + Chromium deps)                 |

### UI (analyst console)

| File                                 | Purpose                                                            |
| ------------------------------------ | ------------------------------------------------------------------ |
| `ui/apps/web/src/app/api/ssi/`       | 6 API proxy routes (investigate, history, detail, wallets, report) |
| `ui/apps/web/src/app/(console)/ssi/` | Console pages (investigate, investigations list/detail, wallets)   |
| `ui/apps/web/src/types/ssi.ts`       | TypeScript type definitions                                        |

---

## Key Settings & Environment Variables

| Variable                                         | Purpose                                                                     |
| ------------------------------------------------ | --------------------------------------------------------------------------- |
| `SSI_STORAGE__DB_URL`                            | SSI → shared core database (default: `sqlite:///../core/data/i4g_store.db`) |
| `SSI_STORAGE__CLOUDSQL_*`                        | Cloud SQL connection for production                                         |
| `SSI_LLM__PROVIDER`                              | LLM backend: `ollama`, `gemini`, `mock`                                     |
| `SSI_PLAYBOOK_DIR` / `I4G_SSI_JOB__PLAYBOOK_DIR` | Playbook YAML directory                                                     |
| `SSI_API_URL`                                    | **Local dev only** — standalone SSI service URL for trigger/poll routes     |

---

## Items Not Yet Done

These were deferred from the roadmap and are **not blocking**:

| Item                  | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| Prod deployment       | Terraform apply to `i4g-prod` (dev validated, prod plan is clean) |
| Taxonomy mapping      | SSI classification → core's five-axis fraud taxonomy              |
| Victim intake flow    | Victim-submitted URLs trigger SSI investigations                  |
| CAPTCHA solver        | 2Captcha / CapSolver integration                                  |
| Proxy infrastructure  | Residential proxy rotation                                        |
| LEA pilot             | Partner with law enforcement for real-world testing               |
| WebSocket/SSE in prod | Real-time agent monitoring (currently CLI/local-dev only)         |
| Blockchain analysis   | Chainalysis / Crystal integration for wallet tracing              |

---

## Test Suites

- **Core:** 850 passed, 1 skipped (includes 41 SsiStore + 62 SSI endpoint tests)
- **SSI:** 720 passed (575 unit + 24 integration + carry-forward)
- **UI:** `tsc --noEmit` zero errors

---

## Related Archives

- `archive/ssi_awh_merge_summary.md` — AWH → SSI merge (Feb 2026)
- `docs/book/ssi/` — SSI GitBook documentation (10 pages)
- `docs/book/api/README.md` — SSI endpoint reference table
