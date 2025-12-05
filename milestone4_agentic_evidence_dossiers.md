# Milestone 4 Agentic Evidence Dossier Spike

_Last updated: 3 Dec 2025_

Milestone 4 delivers an agent-assisted reporting pipeline that turns curated case bundles into
law-enforcement-ready dossiers (interactive PDF + data manifest). This spike mirrors the Milestone 3
approach by capturing architecture decisions, API and worker contracts, UI requirements, and the
week-by-week delivery plan before implementation begins.

## 1. Goals & Success Criteria

1. **Agentic Packaging**: Reports assemble automatically from structured data, vector insights, and
   analyst annotations using a deterministic orchestration graph (no manual copy/paste).
2. **Prosecutable Bundles**: Each dossier meets agreed loss/geo/recency thresholds and groups
directly related cases so investigators receive only actionable packets.
3. **Evidence Integrity**: Every attachment, chart, and narrative includes provenance metadata,
signature hashes, and Task_STATUS breadcrumbs so auditors can replay the generation event.
4. **Operational Observability**: Cloud Run jobs and FastAPI endpoints expose counters, timelines,
and alerts for failed renders, missing assets, or regulators requiring re-issuance.

## 2. Current State Recap

- **Reporting Stack**: `ReportGenerator` + templates under `templates/reports/` power account list
  exports (CSV/XLSX/PDF) but lack multi-case bundling, geo visualizations, or law-enforcement
  narratives.
- **Data Plane**: Milestone 2 dual extraction keeps SQL/Firestore/Vertex in sync; ingestion tracks
  loss buckets, geo hints, and offender entities needed for dossier thresholds.
- **Agent Surfaces**: LangChain pipelines already run inside worker jobs (LLM-driven classification,
  indicator extraction). They do not yet coordinate chart/table synthesis or fallback behaviors.
- **Docs & UX**: `docs/book/guides/{analyst,law-enforcement}.md` describe target personas but not the
  tooling path from analyst acceptance → dossier distribution.
- **Gaps**: No case bundler queue, no geo/enrichment service, no signature registry, and no
  automation for populating the Streamlit LEA portal with ready-to-download dossiers.

## 3. Proposed Dossier Architecture

### 3.1 Data Inputs & Signals

| Input | Source | Usage |
| --- | --- | --- |
| Structured cases/entities | Cloud SQL (prod) / SQLite (local) via `ReviewStore` | Loss totals, entity clusters, analyst notes |
| Vector context | Vertex AI Search or Chroma | Surfacing related cases, supporting evidence, similar offender tactics |
| Evidence artifacts | Cloud Storage (`i4g-evidence-*`) | Thumbnails, manifests, redacted attachments |
| Geo/financial enrichments | MaxMind-lite DB + FX feeds (local JSON fallback) | Map coordinates, jurisdiction-level stats |
| Analyst annotations | Streamlit review console | Narrative seeds, disposition, escalation tags |
| Audit / Task_STATUS | FastAPI in-memory map (future Redis) | Timeline of generation, failure alerts |

### 3.2 Agent Orchestration Flow

1. **Bundle Builder** selects eligible cases (see §4) and emits a `DossierPlan` (cases, entities,
   enrichment tasks, target jurisdiction).
2. **Context Loader** pulls structured + vector context, normalizes attachments, and caches outputs
   in a staging bucket to avoid re-fetching large blobs.
3. **Tool-enabled Agent** (LangChain Supervisor) executes ordered steps:
   - `GeoReasonerTool`: look up jurisdictions, flag cross-border hops, build map-friendly geoJSON.
   - `TimelineSynthesizerTool`: merge chat logs, transactions, and annotations into a constrained
     JSON timeline (.max 30 events) for templating.
   - `EntityGraphTool`: group entities across cases, highlight shared wallets/emails, output GraphML.
   - `ChartRendererTool`: call Matplotlib/Plotly headless renderers to generate PNG charts for loss
     over time + distribution by payment rail.
   - `NarrativeWriterTool`: produce executive summary with citations referencing timeline/event IDs.
4. **Templating & Render** uses Markdown → PDF (ReportLab/WeasyPrint) plus JSON manifest (machine
   readable) and signed hash file. Templates remain configuration-driven so swapping UI components
   does not require agent changes.
5. **Distribution** uploads artifacts to the Google Workspace Shared Drive (Drive API) using a
  dedicated parent folder, registers rows in ReportStore, updates Streamlit LEA portal caches, and
  optionally notifies destinations (email, Slack, webhook). Future iterations will organize
  dossiers into jurisdiction- or agency-specific subfolders with Drive-level access controls.

### 3.3 Template & Rendering Strategy

- Expand `templates/reports/` with modular sections: cover sheet, timeline, entity matrix, geo map,
  evidence manifest, appendix.
- Introduce `TemplatePart` registry so new widgets (heatmaps, sankey diagrams) drop in via config
  rather than editing the base template.
- Provide `dossier_schema.json` describing mandatory/optional blocks to keep UI + GitBook docs
  synchronized.
- Render targets:
  - **PDF** (primary LEA artifact)
  - **HTML bundle** for Streamlit preview (static CSS + JS + signed asset links)
  - **JSON manifest** (entities, assets, signature hash, automation status)

### 3.4 Delivery & Chain of Custody

- Use Cloud Run job `i4g-report-job` to execute agent pipelines with settings-driven knobs:
  `I4G_REPORT__TEMPLATE_PATH`, `I4G_REPORT__DRIVE_PARENT_ID`, `I4G_REPORT__HASH_ALGO`.
- Emit SHA-256 + optional detached PGP signatures. Store metadata in Firestore `dossiers` collection
  with `generated_by`, `jurisdiction`, `loss_band`, `hash`, `drive_file_ids`, and future
  subfolder/ACL metadata.
- Each dossier execution now emits a companion `.signatures.json` file that records the
  SHA-256 hash + size for the manifest, timeline chart, geo JSON, and geo map renderings.
  `signature_manifest.path` inside the primary manifest points to this file so hashing tools or LEA
  operators can verify integrity without opening the agent payload. The hash algorithm defaults to
  `report.hash_algorithm` (`I4G_REPORT__HASH_ALGORITHM`).
- Streamlit LEA portal fetches from `/reports/dossiers` API, verifying signatures before download
  and surfacing the Shared Drive links. Subsequent milestone work will group dossiers into
  structured Drive subfolders so access controls align with agency-level permissions.
- Add optional `LEA Share Code` to throttle downloads and capture access logs.

### 3.5 Bundling Metrics Surfaces

- SQLite now materializes a deterministic `dossier_candidate_metrics` view (loss amount, loss band,
  geo bucket, victim/offender countries, cross-border bit). The view joins `review_queue` with
  `scam_records` metadata so analysts can sanity-check candidate pools with a single query and the
  CLI can hydrate bundle plans without iterating over JSON blobs.
- Firestore ingestion fan-out stores the same data as a `bundle_metrics` field on each case
  document. The payload mirrors the SQLite columns (`loss_amount_usd`, `loss_band`, `geo_bucket`,
  `cross_border`, `victim_country`, `offender_country`) so Cloud Run jobs running against
  Firestore-only backends can reuse the exact thresholds.
- `BundleCandidateProvider` prefers the SQL view when available and falls back to structured-store
  metadata for totally-offline runs, ensuring both local SQLite and Firestore backends feed the
  same BundleBuilder inputs.

## 4. Case Selection & Bundling Requirements

| Rule | Description | Implementation Notes |
| --- | --- | --- |
| Loss Threshold | Default >= $50k; configurable bands per jurisdiction | Settings section `reporting.loss_bands`; env override `I4G_REPORT__MIN_LOSS` |
| Recency | Cases accepted within rolling 30 days unless manually pinned | Query via `accepted_at` timestamps; allow override flag |
| Cross-border Alerts | Cases with victim/jurisdiction mismatch flagged for priority dossier | Use GeoReasoner results; attach cross-border appendix |
| Entity Clusters | Shared indicators (wallet/email/ASN) trigger bundling into single dossier | Rely on `EntityGraphTool`; limit to <=5 cases per dossier |
| Geography | Single jurisdiction preference unless loss magnitude demands multi-region view | Provide `jurisdiction_mode` switch: `single`, `multi`, `global` |

Pipeline flow:
1. Scheduler triggers `BundleBuilder` nightly in dev/prod, or on-demand via CLI (`i4g-admin
   build-dossiers`).
2. Builder queries candidate cases, groups by rules above, and emits `dossier_queue` entries with
   deterministic IDs (`dossier-{jurisdiction}-{yyyymmdd}-{seq}`).
3. Queue consumer (agent job) processes entries, marks success/failure, and pushes metrics to
   Task_STATUS + StatsD (e.g., `dossier.generated`, `dossier.skipped.loss_below_threshold`).

## 5. Delivery Plan

| Week | Workstream | Key Tasks |
| --- | --- | --- |
| Week 7 (Sprint 7) | Data & Bundling | Build `BundleBuilder`, SQL views for loss/geo bands, enqueue test queue entries, CLI/worker plumbing. |
| Week 7 | Agent & Tools | Implement LangChain tool suite (geo, timeline, entity graph, charts) with mocks + pytest coverage. |
| Week 7 | Templates & Schemas | Draft modular template parts, define `dossier_schema.json`, wire JSON manifest + PDF renderers. |
| Week 8 (Sprint 8) | Distribution & Portal | Extend `report-job`, add `/reports/dossiers` API, hook Streamlit LEA portal + GitBook doc updates. |
| Week 8 | Observability & QA | Add telemetry, golden-sample regression tests, LEA pilot feedback loop, finalize deployment checklist. |

## 6. Dependencies & Open Questions

1. **LLM Provider Mix**: Decide whether to rely on Vertex Gemini for narratives or keep Ollama-only
   support for offline rendering; affects latency + cost modeling.
2. **Geo Data Licensing**: Confirm MaxMind/GADM licensing for bundling. Need fallback if licensing
   forbids redistribution in reports.
3. **Digital Signature Strategy**: Evaluate Cloud KMS keys vs software-based SHA-256 + PGP, and how
   Streamlit portal verifies signatures client-side.
4. **PII Redaction Rules**: Define which fields stay tokenized vs redacted, ensuring LEAs can request
   rehydration with subpoenas.
5. **Portal Authentication**: Determine whether LEA portal stays behind Streamlit + IAP or migrates to
   GitBook secure sharing; requires timeline alignment with Milestone 5 auth work.
6. **Artifact Retention**: Align dossier retention/lifecycle rules with Shared Drive retention
  policies (possible dedicated root folder per environment plus nested agency folders later).

## 7. Next Actions

1. ~~Draft `DossierPlan`/`BundleBuilder` models and queue schema (SQL + Firestore) with unit
  tests.~~ **Done (Dec 3):** `dossier_candidate_metrics` view + Firestore `bundle_metrics` fields
  now back the queue, BundleCandidateProvider consumes them, and the queue store/tests cover the
  new schema.
2. ~~Prototype chart renderer + geo map generator locally using sandbox data; capture example
  assets.~~ **Done (Dec 3):** `dossier_visuals.py` now emits Pillow-based loss timeline charts,
  GeoJSON feature collections, and preview maps. The assets are written to
  `data/reports/dossiers/assets/` and automatically included in each generated dossier manifest.
3. ~~Define hash/signature metadata contract and update `docs/book/guides/law-enforcement.md` with
  the verification workflow (hash lookup, contact path).~~ **Done (Dec 3):** the dossier generator
  now produces `.signatures.json` manifests containing SHA-256 hashes for every emitted
  attachment while the primary manifest references the signed file path and algorithm.
4. ~~Schedule pilot run with three historical cases to validate bundling logic + report narrative tone.~~ **Done (Dec 3):** the new `i4g-admin pilot-dossiers` command seeds `data/manual_demo/dossier_pilot_cases.json`, enqueues pilot plans (or dry-runs them), and records hashes so we can hand a curated trio of cases to LEA stakeholders before wiring the API/portal changes.
5. ~~Add Milestone 4 env var table to `docs/dev_guide.md` once settings sections land, including the
  Shared Drive parent ID + service account scopes required for Drive uploads.~~ **Done (Dec 3):**
  `docs/dev_guide.md` now includes a Milestone 4-specific env var table covering the Drive parent
  folder, dossier loss/recency thresholds, hash algorithm, and Workspace credential scopes so dev
  + cloud runners share the same configuration contract.
6. ~~Expose the `/reports/dossiers` API backed by the dossier queue store and include optional
  manifest/signature payloads in responses.~~ **Done (Dec 3):** `src/i4g/api/reports.py` now
  publishes the dossier list endpoint, `DossierQueueStore.list_plans()` surfaces manifest paths +
  warnings, and pytest coverage (`tests/unit/api/test_reports.py`) verifies both the happy path and
  missing-manifest edge cases.
7. ~~Wire the Streamlit LEA portal (and eventual Next.js console) to `/reports/dossiers` so analysts
  and investigators can preview manifest metadata, download signed artifacts directly from the
  Shared Drive links, and see signature verification hints inline.~~ **Done (Dec 3):** the Streamlit
  analyst dashboard now exposes an **Evidence dossiers** panel backed by the reports API. Analysts
  can filter by queue status, toggle inline manifest payloads, download manifests, and inspect
  signature warnings before we wire the feature into the LEA portal.
8. ~~Document the LEA portal workflow and provide a regression checklist (docs + smoke script) that
  exercises `/reports/dossiers`, Drive uploads, and signature verification end-to-end before we
  open the pilot to external agencies.~~ **Done (Dec 3):** `docs/dev_guide.md` captures the Streamlit
  dossier viewer workflow plus a manual smoke checklist (generate pilot bundles, refresh the
  Streamlit panel, validate manifest/signature hashes) so we have a reproducible test until the LEA
  UI lands.
9. **NEW – Inline verification UI.** Add a Streamlit control that runs `verify_manifest_payload` on
  demand, surfaces artifact-level status, and update the dev guide with the inline workflow.
  **Done (Dec 3):** the analyst dashboard now exposes a **Verify signatures** button per dossier,
  caches verification reports in session state, and the dev guide documents the button + optional
  CLI hash cross-check.
10. **NEW – Next.js dossier console.** Mirror the Streamlit experience inside the Next.js console,
    route `/reports/dossiers` through the SDK client, and ship verification + manifest previews so
    analysts and LEA operators can move off Streamlit when ready. **Done (Dec 4):** the console now
    features the Evidence Dossiers page (filters, manifest toggle, inline verification button, and
    payload accordions) plus API route `/api/dossiers/verify` for server-side verification requests.

## 8. Execution Checklist & Status

### Data & Signals
- [x] **Loss/geo SQL views + Firestore aggregations** — Completed Dec 3 via `dossier_candidate_metrics`
  view and Firestore `bundle_metrics`; BundleBuilder now consumes both backends without manual
  stitching.
- [x] **BundleBuilder queue emission** — Deterministic IDs, retries, and dry-run support landed
  Dec 3 alongside `i4g-admin build-dossiers` and worker plumbing.

### Agent & Template
- [x] **LangChain tool suite** — GeoReasoner, TimelineSynthesizer, EntityGraph, ChartRenderer, and
  NarrativeWriter tools now live under `src/i4g/reports/dossier_tools.py`, feed the generator, and
  emit structured payloads for templates (guardrail + timeout tuning still queued for Sprint 7).
- [x] **Modular template registry** — Markdown partials plus the new `TemplateRegistry` landed
  Dec 4, wiring cover/analysis/timeline/entity/appendix sections into the generator so downstream
  PDF/HTML/JSON renders can reuse the shared manifest context.

### Delivery & Compliance
- [x] **/reports/dossiers surfaces** — FastAPI endpoint, Streamlit panel, and the new Next.js
  Evidence Dossiers page all expose signed artifacts with access logging (completed Dec 4).
- [x] **Signature verification + subpoena workflow** — Completed Dec 4 via
  `docs/runbooks/dossiers_subpoena_handoff.md`, which walks analysts through request validation, inline verification,
  required artifacts, and logging. The analyst index plus the console runbook now link to the playbook so subpoenas
  follow a single documented path.

### Testing & Quality
- [x] **Golden-sample regression harness** — Added deterministic dossier fixtures plus
  `tests/unit/reports/test_dossier_golden_regression.py`, which pins manifest/markdown/signature
  hashes so template/tool changes surface immediately in CI.
- [x] **Dossier smoke runs** — Documented local + dev flows in `docs/smoke_test.md` (pilot seeding plus
  `i4g-dossier-job` locally, `gcloud run jobs execute dossier-queue` in dev) so we have a repeatable command block prior
  to enabling automation.

### Documentation & Enablement
- [x] **Analyst/LEA guides** — `docs/analyst_runbook.md` now acts as an index into the console runbooks
  (`docs/runbooks/console/search.md` and `docs/runbooks/console/reports.md`) with sanitized screenshots in
  `docs/assets/console/`, so analysts see the Search + Evidence Dossiers workflows plus verification steps in one place.
  The LEA guide refresh will mirror the same content once the portal copy lands.
- [x] **Deployment checklist** — Completed Dec 4: `docs/runbooks/dossiers_deployment_checklist.md` centralizes pre-flight
  tests, env-var matrices, Cloud Run update commands, observability/rollback steps, and `docs/dev_guide.md` now points to
  it whenever the dossier job image is rebuilt.

## 9. Two-Week Execution Plan (Dec 8–19)

### Week of Dec 8 (Sprint 7 kickoff)
- **BundleBuilder foundations** (owner: Jerry, due Dec 10): create SQL views, queue schema, and CLI
  hooks; validate dry-run output vs existing cases.
- **Agent tool prototypes** (owner: Jerry, due Dec 11): land GeoReasoner/TimelineSynthesizer tools
  with fixture-based tests and stub data for offline dev.
- **Template scaffolding** (owner: Jerry, due Dec 12): define template registry, Markdown partials,
  and JSON manifest schema shared with UI + GitBook.

### Week of Dec 15 (Sprint 8 wrap-up)
- **Distribution plumbing** (owner: Jerry, due Dec 17): extend `report-job`, add `/reports/dossiers`
  endpoint, wire Streamlit portal download list, ensure Task_STATUS telemetry surfaces progress.
- **Observability + QA** (owner: Jerry, due Dec 18): add StatsD/OTel counters, golden regression
  harness, and negative-case tests (missing assets, LLM timeout).
- **Pilot + documentation** (owner: Jerry, due Dec 19): generate three pilot dossiers, collect LEA
  feedback, update dev guide + LEA handbook with signature verification + access expectations.
