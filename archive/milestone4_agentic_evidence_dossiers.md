# Milestone 4 Agentic Evidence Dossier Spike

_Last updated: 6 Dec 2025_

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

## 2. Current State (Dec 6)

- **Bundling + manifests**: `DossierGenerator` builds JSON manifests with hash signatures and now
  emits Markdown via the modular template registry (`TemplateRegistry`) alongside signature files.
- **Tools + templates**: LangChain tool suite (`GeoReasoner`, `TimelineSynthesizer`, `EntityGraph`,
  `ChartRenderer`, `NarrativeWriter`) feeds the generator; modular Jinja parts live under
  `templates/reports/dossiers/`.
- **Visual assets**: `dossier_visuals.py` renders timeline charts and geo assets; signature
  manifests include all emitted artifacts.
- **Queue + plan**: `DossierPlan`/`BundleBuilder` models exist; queue processor generates manifests
  to `data/reports/dossiers/` for pilot bundles.
- **APIs/UX (portal parity)**: `/reports/dossiers` FastAPI surface powers Streamlit and the
  Next.js console. Portal now surfaces local + Drive downloads and inline signature verification
  (API proxy + UI wiring), matching the Streamlit panel.
- **Drive ACL preview**: `/reports/dossiers/{plan_id}/drive_acl` exposes folder metadata +
  permissions so the portal can render Shared Drive ACL previews alongside downloads.
- **Distribution**: PDF/HTML exports and Drive uploads flow through `DossierExporter` and
  `DossierUploader`; signature manifests include uploaded hashes.
- **Remaining gaps**: LEA-facing distribution UX polish (foldering/ACL previews). Diagrams and runbooks are refreshed and available in `docs/diagrams` + `docs/runbooks`.

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

### 3.2 Agent Orchestration Flow (target state)

1. **Bundle Builder** selects eligible cases and emits a `DossierPlan` (cases, entities, enrichment
  tasks, target jurisdiction).
2. **Context Loader** pulls structured + vector context, normalizes attachments, and caches outputs
  in staging to avoid re-fetching large blobs.
3. **Tool-enabled Agent** executes ordered steps with fallbacks/timeouts:
  - `GeoReasonerTool`: jurisdiction mix + cross-border flags.
  - `TimelineSynthesizerTool`: constrained JSON timeline (<=30 events) for templating.
  - `EntityGraphTool`: overlapping indicators across cases.
  - `ChartRendererTool`: summarize rendered assets from `dossier_visuals` (no inline rendering yet).
  - `NarrativeWriterTool`: deterministic summary + recommendation seed.
  4. **Templating & Render**: Markdown + PDF/HTML exports flow through `TemplateRegistry` and
     `DossierExporter`.
  5. **Distribution**: Shared Drive upload now available via `DossierUploader`; portal download/
    verification flows remain to be wired while signatures capture local + uploaded hashes.

### 3.3 Template & Rendering Strategy

- Modular Jinja parts (cover, analysis, timeline, entities, appendix) already live under
  `templates/reports/dossiers/` and render via `TemplateRegistry`.
- `dossier_schema.json` published to formalize required vs optional sections for UI + docs.
- Render targets: Markdown + JSON + PDF + HTML bundles emitted per dossier.

### 3.4 Delivery & Chain of Custody

- Cloud Run `i4g-report-job` remains the execution target; Drive upload plumbing and folder/ACL
  strategy are next.
- SHA-256 signature manifest is emitted locally; extend to optionally sign uploaded assets after
  Drive copy completes.
- `/reports/dossiers` serves manifests; Streamlit/Next.js verification UI is deferred until Drive
  distribution is ready.

### 3.5 Bundling Metrics Surfaces

- `dossier_candidate_metrics` SQL view + Firestore `bundle_metrics` payloads back the builder.
- `BundleCandidateProvider` prefers SQL view, falling back to structured metadata for offline runs.

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

## 5. Dependencies & Open Questions

1. **LLM provider**: Stay on Ollama for offline runs vs introduce Vertex Gemini for narratives?
2. **Geo data licensing**: Confirm MaxMind/GADM terms; select fallback data set if redistribution is
  restricted.
3. **Digital signatures**: Do we add KMS-backed signing after SHA-256, and how will portals verify
  client-side?
4. **PII handling**: Which fields remain tokenized/redacted in exported PDFs vs manifest-only?
5. **Portal auth**: Streamlit + IAP vs future Next.js portal with agency-level ACLs.
6. **Retention**: Align dossier retention/lifecycle with Drive policies and per-agency subfolders.

## 6. Immediate Checklist (keep short)

- [x] LEA pilot verification — run portal handoff banner + Drive ACL preview + Web Crypto hash on a fresh pilot bundle; capture sign-off and defects.
- [x] Nightly smoke cadence — schedule `scripts/smoke_dossiers.py --api-url <fastapi> --token <key>` via cron/CI with alerts on hash mismatches or missing artifacts.
- [x] Dashboard/alerts — pipe `reports.dossiers.*` StatsD counters into the existing dashboards and alert on verify failures or missing artifacts.
- [x] Roll-forward notes captured below.
- [x] UI: LEA folder/ACL preview — Next.js portal can call `/reports/dossiers/{plan_id}/drive_acl`
  to render the Shared Drive folder metadata + ACL badges and link copy UI.

## 7. Roll-forward notes (to Milestone 5)

- PII vault/IAP enforcement: carry LEA portal lessons into hardening; ensure dossier downloads continue to respect IAP/ACLs.
- Hash verification UX: keep Web Crypto as default with API fallback for headless/air-gapped reviewers; document both in runbooks.
- Smoke cadence: require nightly smoke before merges; alert on `missing_count>0` or `mismatch_count>0`.
