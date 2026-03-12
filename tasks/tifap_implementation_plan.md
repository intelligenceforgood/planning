# TIFAP Implementation Plan

**PRD:** [prd_threat_intelligence_analytics.md](../prd_threat_intelligence_analytics.md)
**Status:** Draft — Ready for Review
**Created:** 2026-03-12
**Sprints:** 6 × 5-week sprints (30 weeks total, Phases 0–3 + stretch Phase 4)

---

## Overview

This plan translates the Threat Intelligence & Fraud Analytics Platform (TIFAP) PRD into actionable sprint tasks. Each task is checkboxed for progress tracking. The plan covers:

- **Backend:** Schema migrations, API endpoints, aggregation jobs, graph service
- **Frontend:** New pages, components, navigation restructure
- **Docs & TDD:** Architecture docs, TDDs, developer guide, user guides, runbooks, cookbooks, config manifests
- **Testing:** Unit tests, integration tests, smoke tests

Feature IDs (F-00a through F-52) reference the PRD Feature Catalogue (Section 10).

---

## Sprint 1 — Data Foundation (Weeks 1–5)

_Goal: Build the pre-computed aggregation layer, threat campaign model, and schema prerequisites. No UI changes — purely backend + docs._

### Schema & Migrations

- [x] **S1-01** Create Alembic migration: `threat_campaigns` table (UUID PK, name, description, origin, status, risk_score, taxonomy_rollup JSON, metadata JSON, created_by, timestamps) — F-00c
- [x] **S1-02** Create Alembic migration: `threat_campaign_cases` M:N join table (campaign_id FK, case_id FK, linked_at, linked_by, link_reason, UNIQUE constraint) — F-00c
- [x] **S1-03** Create Alembic migration: `intake_indicator_links` table (intake_id FK, indicator_id FK, confidence NUMERIC, linked_by TEXT, created_at) — F-00a
- [x] **S1-04** Create Alembic migration: add `loss_currency` TEXT column to `intake_records` (default "USD") — Data Gap P0
- [x] **S1-05** Create Alembic migration: add `ingestion_batch_id` column to `cases` — D8
- [x] **S1-06** Create Alembic migration: add `victim_country` TEXT column to `intake_records` — Data Gap P1
- [x] **S1-07** Create Alembic migration: `entity_stats` denormalized table (per PRD Section 8.2 schema) — F-00b
- [x] **S1-08** Create Alembic migration: `indicator_stats` denormalized table (per PRD Section 8.2 schema) — F-00b
- [x] **S1-09** Create Alembic migration: `campaign_stats` denormalized table (per PRD Section 8.2 schema) — F-00b
- [x] **S1-10** Create Alembic migration: `platform_kpis` per-period summary table (per PRD Section 8.2 schema) — F-00b
- [x] **S1-11** Write one-time data migration script: identify and move ingestion-batch `campaign_id` values to `ingestion_batch_id`; leave correlator-detected values on `campaign_id` — D8

### Store Layer

- [x] **S1-12** Create `ThreatCampaignStore` in `src/i4g/store/` — CRUD for `threat_campaigns` and `threat_campaign_cases` (create, get, list, update status, link/unlink cases, merge, split)
- [x] **S1-13** Create `AnalyticsStore` in `src/i4g/store/` — read accessors for `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis` (list with filters, get by ID, time-series queries)
- [x] **S1-14** Add `intake_indicator_links` write/read methods to existing intake/indicator stores
- [x] **S1-15** Register new stores in `src/i4g/services/factories.py` — `build_threat_campaign_store()`, `build_analytics_store()`

### Aggregation Job

- [x] **S1-16** Create `src/i4g/worker/jobs/analytics_aggregation.py` — scheduled job that computes and writes `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis` from raw tables (SQL aggregation queries)
- [x] **S1-17** Add campaign risk score computation to aggregation job (per PRD Section 7.5 weighted formula)
- [x] **S1-18** Add campaign lifecycle auto-transition logic (Emerging→Active→Declining→Dormant based on case-linking activity and time thresholds)
- [x] **S1-19** Add `taxonomy_rollup` computation for campaigns (aggregate `classification_result` from member cases)
- [x] **S1-20** Register aggregation job in CLI: `i4g jobs analytics refresh` — manual trigger
- [x] **S1-21** Add ingestion-completion hook: trigger aggregation job after each ingestion batch completes
- [x] **S1-22** Add `I4G_ANALYTICS__REFRESH_INTERVAL_MINUTES` setting (default: 15) to settings model — D12

### Loss-to-Indicator Linkage

- [x] **S1-23** Create LLM extraction job: parse intake narratives to identify mentioned financial indicators and write `intake_indicator_links` with confidence scores — F-00a
- [x] **S1-24** Run LLM extraction spike: test on 50 intake narratives, measure precision/recall, document results
- [x] **S1-25** Backfill job: run extraction over all existing intake records to populate `intake_indicator_links`

### CampaignCorrelator Migration

- [x] **S1-26** Modify SSI `CampaignCorrelator` (`ssi/src/ssi/ecx/correlation.py`) to write to `threat_campaigns` + `threat_campaign_cases` instead of updating `cases.campaign_id` — F-00c, F-14
- [x] **S1-27** Add LLM-generated semantic campaign name on auto-creation (≤60 chars, from classification + GeoIP + indicator types; preserve original label in `metadata.original_label`) — D6

### PII & Compliance

- [x] **S1-28** Implement soft-anonymization in aggregation job: when all cases for an entity have `purged_at`, replace `canonical_value` with deterministic SHA-256 hash, set `purge_status = "anonymized"` — D9

### Settings & Config

- [x] **S1-29** Add `analytics` section to `Settings` model (`src/i4g/settings.py`): `refresh_interval_minutes`, `loss_linkage_confidence_threshold`, `campaign_risk_weights`
- [x] **S1-30** Add unit tests for new settings under `tests/unit/settings/` — validate defaults, env-var overrides (`I4G_ANALYTICS__*`)
- [x] **S1-31** Update `config/settings.default.toml` and `config/settings.local.toml` with `[analytics]` section defaults

### Testing — Sprint 1

- [x] **S1-32** Unit tests for `ThreatCampaignStore` — CRUD, link/unlink, merge, split
- [x] **S1-33** Unit tests for `AnalyticsStore` — query entity_stats, indicator_stats with filters
- [x] **S1-34** Unit tests for aggregation job — verify computed stats match expected values from test data
- [x] **S1-35** Unit tests for campaign risk score computation — boundary conditions, normalization
- [x] **S1-36** Unit tests for campaign lifecycle transitions — time-based state changes
- [x] **S1-37** Unit tests for intake-indicator linkage extraction (mocked LLM)
- [x] **S1-38** Unit tests for PII soft-anonymization logic
- [x] **S1-39** Integration test: end-to-end aggregation pipeline — ingest test data → run aggregation → verify stats tables
- [x] **S1-40** Local smoke test: `conda run -n i4g I4G_PROJECT_ROOT=$PWD I4G_ENV=dev I4G_LLM__PROVIDER=mock i4g jobs analytics refresh`

### Documentation — Sprint 1

- [x] **S1-41** Create TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — Data architecture (aggregation pipeline, pre-computed tables, graph service interface, BigQuery migration path), campaign model (threat_campaigns vs ingestion batches), loss-indicator linkage, PII anonymization model
- [x] **S1-42** Update `core/docs/design/data_model.md` — add `threat_campaigns`, `threat_campaign_cases`, `intake_indicator_links`, `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis` table definitions; add `loss_currency`, `victim_country`, `ingestion_batch_id` columns
- [x] **S1-43** Update `core/docs/design/jobs.md` — add analytics aggregation job entry (purpose, source, Docker image, entrypoint, schedule, env vars)
- [x] **S1-44** Update `core/docs/design/storage.md` — add analytics aggregation tables to storage matrix; document aggregation refresh strategy
- [x] **S1-45** Update `docs/config/settings_manifest.yaml` and `settings_manifest.json` — add `I4G_ANALYTICS__*` env vars
- [x] **S1-46** Update `docs/config/README.md` — add analytics configuration section
- [x] **S1-47** Update `core/docs/development/dev_guide.md` — add analytics section: local aggregation job, new stores, new CLI command
- [x] **S1-48** Update `planning/change_log.md` — record Sprint 1 deliverables

### Sprint 1 Exit Criteria

- [x] **S1-EC** Dashboard API can serve pre-computed entity stats, indicator stats, and platform KPIs from new tables. Loss-per-entity numbers populated for linked intake records. All unit tests pass. Aggregation job runs successfully on dev data.

---

## Sprint 2 — Core Intelligence UI (Weeks 6–10)

_Goal: Ship Entity Explorer, Indicator Registry, Global Search enhancement, Intelligence Dashboard widgetboard. Backend APIs + frontend pages._

### API Endpoints — Intelligence

- [ ] **S2-01** Create `src/i4g/api/intelligence.py` router — `/api/intelligence/entities` (list with filters, pagination, sort), `/api/intelligence/entities/{entity_id}` (detail with real-time drill-down per D12)
- [ ] **S2-02** Add `/api/intelligence/indicators` endpoints (list/detail, segmentation tabs: all/bank/crypto/payments/ip/domain)
- [ ] **S2-03** Add `/api/intelligence/dashboard` endpoint — widgetboard data (active threats, new indicators, emerging campaigns, loss trend, source breakdown)
- [ ] **S2-04** Add entity sparkline endpoint: `/api/intelligence/entities/{entity_id}/activity` — weekly case counts over entity lifetime
- [ ] **S2-05** Add entity mini-graph endpoint: `/api/intelligence/entities/{entity_id}/neighbors` — 1-hop co-occurrence graph
- [ ] **S2-06** Enhance Global Search endpoint to include entity/indicator type facets — F-05
- [ ] **S2-07** Wire new router in `src/i4g/api/app.py`

### API Endpoints — Exports

- [ ] **S2-08** Create `src/i4g/api/exports.py` router — `/api/exports/entities` (XLSX/CSV), `/api/exports/indicators` (XLSX/CSV/STIX 2.1)
- [ ] **S2-09** Add export audit logging: every export action logged with user, timestamp, scope, format — F-22
- [ ] **S2-10** Implement indicator masking in API responses: bank accounts show last 4; reveal via explicit `?unmask=true` with role check — F-21

### GraphService — Backend

- [ ] **S2-11** Create `src/i4g/services/graph_service.py` — implement `GraphService` protocol (D3): `get_neighbors()`, `get_subgraph()`, `detect_clusters()` using NetworkX
- [ ] **S2-12** Extend existing `EntityGraphTool` to delegate to `GraphService` (share implementation, avoid duplication)
- [ ] **S2-13** Add graph payload serialization: nodes (with entity_stats), edges (with weight/type), optional layout coordinates for >500 nodes — D13

### Frontend — SDK

- [ ] **S2-14** Add TypeScript interfaces in `ui/packages/sdk/` for: `EntityStats`, `IndicatorStats`, `CampaignStats`, `PlatformKpis`, `GraphPayload` (nodes + edges)
- [ ] **S2-15** Add SDK client methods: `getEntities()`, `getEntity()`, `getIndicators()`, `getIndicator()`, `getDashboardWidgets()`, `getEntityActivity()`, `getEntityNeighbors()`
- [ ] **S2-16** Add SDK export methods: `exportEntities()`, `exportIndicators()`

### Frontend — Navigation Restructure

- [ ] **S2-17** Restructure console navigation per PRD Section 6.1: add "Intelligence" and "Impact" top-level sections; move `/accounts` → `/intelligence/indicators`, `/analytics` → `/impact`, `/taxonomy` → `/impact/taxonomy`, `/campaigns` → `/intelligence/campaigns`
- [ ] **S2-18** Add redirect routes for old URLs (backward compatibility)

### Frontend — Entity Explorer

- [ ] **S2-19** Create Entity Explorer list page at `/intelligence/entities` — sortable/filterable table with columns per PRD Section 6.2 (type, value, case count, first seen, last active, cumulative loss, risk, campaign, status) — F-01
- [ ] **S2-20** Create Entity Explorer filter sidebar: entity type checkboxes, activity date range, min case count slider, min loss input, risk range slider, campaign dropdown, status toggle — F-01
- [ ] **S2-21** Create Entity Detail panel (slide-over or dedicated page `/intelligence/entities/{id}`) — header, impact section with sparkline, related cases table, mini network graph, actions toolbar — F-02
- [ ] **S2-22** Implement entity actions: Export Summary PDF, Submit to eCrimeX, Flag for Review, Add Annotation — F-02

### Frontend — Indicator Registry

- [ ] **S2-23** Create Indicator Registry page at `/intelligence/indicators` — replaces `/accounts` — segmentation tabs (All/Bank/Crypto/Payments/IP/Domain), filterable list per PRD Section 6.3 — F-03
- [ ] **S2-24** Create Indicator Detail page `/intelligence/indicators/{id}` — stats, case linkage, source documents — F-04
- [ ] **S2-25** Implement bulk actions toolbar: export selection (XLSX, CSV, STIX 2.1), submit to eCrimeX, tag — F-03

### Frontend — Intelligence Dashboard

- [ ] **S2-26** Create Intelligence Dashboard widgetboard at `/intelligence` — configurable widgets: active threats count, new indicators this period, emerging campaigns, loss trend sparkline, source pipeline breakdown — F-06

### Frontend — Global Search Enhancement

- [ ] **S2-27** Enhance Cmd+K search overlay with entity/indicator type facets — F-05

### Role-Based Access

- [ ] **S2-28** Implement role-based view restrictions: Researcher role = anonymized aggregates only; LEO = full detail; Analyst = full — F-20
- [ ] **S2-29** Add "Researcher" role to identity/auth model with restricted permissions per D16

### Testing — Sprint 2

- [ ] **S2-30** Unit tests for intelligence API endpoints — entity list/detail, indicator list/detail, dashboard widgets
- [ ] **S2-31** Unit tests for GraphService — get_neighbors, get_subgraph, layout computation
- [ ] **S2-32** Unit tests for export endpoints — XLSX/CSV generation, audit logging, indicator masking
- [ ] **S2-33** Unit tests for role-based access — researcher restrictions, LEO full access
- [ ] **S2-34** Frontend component tests: Entity Explorer list, filters, detail panel
- [ ] **S2-35** Frontend component tests: Indicator Registry tabs, bulk actions
- [ ] **S2-36** E2E smoke: search entity → view detail → export PDF

### Documentation — Sprint 2

- [ ] **S2-37** Update TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — add API endpoint specifications (request/response schemas), GraphService implementation details, role-based access model
- [ ] **S2-38** Update `core/docs/design/iam.md` — add Researcher role definition and permission matrix per D16
- [ ] **S2-39** Update `docs/book/api/sample-requests.md` — add intelligence endpoint examples (entity search, indicator lookup, dashboard widgets)
- [ ] **S2-40** Update `docs/book/api/sdk_endpoint_coverage.md` — add new SDK methods for intelligence endpoints
- [ ] **S2-41** Update `docs/book/api/field_name_translation.md` — add field mappings for new entity/indicator/campaign models
- [ ] **S2-42** Update `ui/docs/ui_architecture.md` — document navigation restructure, new Intelligence/Impact sections, component hierarchy
- [ ] **S2-43** Create `docs/book/guides/analyst/entity_explorer.md` — user guide: how to search entities, read entity detail, interpret sparklines, use network mini-graph, export summaries
- [ ] **S2-44** Create `docs/book/guides/analyst/indicator_registry.md` — user guide: browsing indicators, segmentation tabs, bulk export, eCrimeX submission
- [ ] **S2-45** Update `docs/book/guides/analyst/index.md` — add links to new entity explorer and indicator registry guides
- [ ] **S2-46** Update `docs/book/SUMMARY.md` — add Intelligence section entries (Entity Explorer, Indicator Registry guides)
- [ ] **S2-47** Update `core/docs/api_reference.md` — add `/api/intelligence/*` and `/api/exports/*` endpoint documentation
- [ ] **S2-48** Update `planning/change_log.md`

### Sprint 2 Exit Criteria

- [ ] **S2-EC** Analyst can search for an entity in the Entity Explorer, see case count and cumulative loss, drill into related cases, view 1-hop network, and export a PDF summary. Indicator Registry replaces `/accounts` with persistent, always-on indicator browsing. All tests pass.

---

## Sprint 3 — Impact Analytics + Campaigns + Reports (Weeks 11–15)

_Goal: Ship Impact Dashboard, Campaign Dashboard with management, report templates (Executive Summary, LEA Dossier), LEA referral suggestion engine. Replace `/analytics` page._

### API Endpoints — Impact

- [ ] **S3-01** Create `src/i4g/api/impact.py` router — `/api/impact/dashboard` (KPI cards with vs-prior-period trend), `/api/impact/loss-by-taxonomy` (treemap data), `/api/impact/detection-velocity` (proactive vs reactive line chart), `/api/impact/pipeline-funnel` (intake→action drop-off)
- [ ] **S3-02** Add `/api/impact/cumulative-indicators` endpoint — running total of unique indicators over time, stacked by category
- [ ] **S3-03** Wire impact router in `src/i4g/api/app.py`

### API Endpoints — Campaigns

- [ ] **S3-04** Create `src/i4g/api/campaigns.py` router — `/api/intelligence/campaigns` (list with filters/sort), `/api/intelligence/campaigns/{id}` (detail: metrics, timeline, entity list, taxonomy rollup, SSI links, eCX status)
- [ ] **S3-05** Add campaign management endpoints: rename, merge, split, link/unlink cases, change status, annotate — F-13
- [ ] **S3-06** Add campaign timeline endpoint: `/api/intelligence/campaigns/{id}/timeline` — cases per day over campaign lifetime
- [ ] **S3-07** Add campaign network graph endpoint: `/api/intelligence/campaigns/{id}/graph` — scoped entity co-occurrence graph

### API Endpoints — Reports

- [ ] **S3-08** Create `src/i4g/api/reports.py` router — `/api/reports/generate` (template selection + scope + options), `/api/reports/library` (list generated reports), `/api/reports/{id}/download`
- [ ] **S3-09** Add TLP labeling to all report generation (default per template per D10, admin override) — F-19

### LEA Referral Suggestion Engine

- [ ] **S3-10** Create `src/i4g/services/lea_referral.py` — surfaces prompts when entity/campaign meets threshold criteria (>$50K loss, >5 cases, eCrimeX corroboration) — F-17
- [ ] **S3-11** Add `/api/intelligence/lea-suggestions` endpoint — list entities/campaigns meeting LEA referral thresholds
- [ ] **S3-12** Add notification mechanism: surface LEA suggestions on Intelligence Dashboard widgetboard

### Report Templates

- [ ] **S3-13** Create Executive Impact Summary template in `templates/` — extends `template_engine.py` + `dossier_visuals.py` for chart rendering (KPI snapshot, treemap, velocity chart, geographic thumbnail, narrative; 1-2 pages, TLP:AMBER default) — F-15
- [ ] **S3-14** Create LEA Evidence Dossier template — extends `bundle_builder.py` + `dossier_signatures.py` for chain-of-custody (cover sheet, indicator declarations, evidence exhibits, case history, SHA-256 manifest, certification; TLP:RED default) — F-16
- [ ] **S3-15** Add server-side chart rendering to `dossier_visuals.py` using matplotlib/plotly — SVG/PNG embed in Jinja2 templates — D14
- [ ] **S3-16** Implement two-tier chain-of-custody model per D11: full per-record hashing for LEA, aggregation-level hashing for executive reports

### ExportAdapter Framework

- [ ] **S3-17** Create `ExportAdapter` protocol in `src/i4g/services/export_adapters.py` — `format_indicators()`, `content_type()`, `file_extension()` — D15
- [ ] **S3-18** Implement `StixAdapter` (STIX 2.1 JSON), `CsvAdapter`, `XlsxAdapter` — F-18, F-39

### Frontend — Impact Dashboard

- [ ] **S3-19** Create Impact Dashboard page at `/impact` — replaces `/analytics` — KPI cards with period comparison (total cases, loss, active threats, sites investigated, unique indicators, detection-to-action time) — F-07
- [ ] **S3-20** Add Loss by Taxonomy treemap chart (area = loss sum per classification label, interactive) — F-08
- [ ] **S3-21** Add Detection Velocity line chart (cases/week, proactive vs reactive split) — F-09
- [ ] **S3-22** Add Pipeline Funnel visualization (intake → ingestion → classification → review → action) — F-10
- [ ] **S3-23** Add Cumulative Indicators area chart (stacked by category)
- [ ] **S3-24** Add period selector: Last 7d / 30d / 90d / Quarter / Year / Custom

### Frontend — Campaign Dashboard

- [ ] **S3-25** Create Campaign Dashboard at `/intelligence/campaigns` — campaign cards with stats (case count, loss, indicators, duration, risk badge, primary entity types), filters (status, risk, date, origin, loss), sort — F-11
- [ ] **S3-26** Create Campaign Detail page `/intelligence/campaigns/{id}` — header, key metrics, timeline chart, taxonomy rollup, entity list, scoped network graph, SSI investigations, eCX status — F-12
- [ ] **S3-27** Implement campaign management UI: rename, merge, split, link/unlink cases, change status, annotate — F-13

### Frontend — Report Builder

- [ ] **S3-28** Create Report Builder page at `/reports/new` — template selection, scope configuration, options (TLP, sections, header note), preview, generate — per PRD Section 11.3
- [ ] **S3-29** Create Report Library page at `/reports` — list generated reports with download links, generation metadata — F-40

### Frontend — LEA Referral

- [ ] **S3-30** Add LEA referral suggestion UI on Intelligence Dashboard — notification cards for entities/campaigns meeting thresholds, click to synopsis, "Compile LEA Dossier" action — F-17

### Testing — Sprint 3

- [ ] **S3-31** Unit tests for impact API endpoints — KPI cards, treemap, velocity, funnel
- [ ] **S3-32** Unit tests for campaign API endpoints — list/detail, management (merge, split, link/unlink)
- [ ] **S3-33** Unit tests for report generation — Executive Summary, LEA Dossier templates
- [ ] **S3-34** Unit tests for ExportAdapter implementations — STIX, CSV, XLSX format correctness
- [ ] **S3-35** Unit tests for LEA referral suggestion engine — threshold logic, notification generation
- [ ] **S3-36** Unit tests for two-tier chain-of-custody — per-record vs aggregation-level hashing
- [ ] **S3-37** Unit tests for TLP labeling and override rules — role-based TLP changes per D10
- [ ] **S3-38** Frontend component tests: Impact Dashboard KPI cards, charts
- [ ] **S3-39** Frontend component tests: Campaign cards, detail page, management actions
- [ ] **S3-40** E2E smoke: view Impact Dashboard → select period → generate Executive Summary PDF

### Documentation — Sprint 3

- [ ] **S3-41** Update TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — add campaign intelligence design (lifecycle, risk scoring, management operations), report template architecture, LEA referral engine, export adapter pattern, chain-of-custody model
- [ ] **S3-42** Update `docs/book/architecture/data-pipeline.md` — add analytics aggregation stage to pipeline diagram and descriptions
- [ ] **S3-43** Create `docs/book/guides/analyst/campaigns.md` — user guide: browsing campaigns, understanding auto-detection, managing campaigns (rename, merge, split, link cases), interpreting risk scores
- [ ] **S3-44** Update `docs/book/guides/analyst/campaign_governance.md` — integrate threat campaign model alongside existing campaign governance content
- [ ] **S3-45** Create `docs/book/guides/analyst/impact_dashboard.md` — user guide: reading KPI cards, period comparisons, treemap, velocity chart, funnel
- [ ] **S3-46** Create `docs/book/guides/user-guide-reports.md` — user guide: Report Builder workflow (template selection, scope, TLP, generate, download), Report Library
- [ ] **S3-47** Update `docs/book/guides/law-enforcement.md` — add LEA dossier generation flow (analyst-prompted → synopsis → compile → download), chain-of-custody explanations, TLP guidance
- [ ] **S3-48** Create `core/docs/runbooks/console/intelligence_dashboard.md` — ops runbook: monitoring aggregation job, verifying stats freshness, troubleshooting stale data
- [ ] **S3-49** Create `core/docs/runbooks/console/campaign_management.md` — ops runbook: campaign lifecycle management, merge/split procedures, auto-detection troubleshooting
- [ ] **S3-50** Update `core/docs/runbooks/console/reports.md` — add Executive Summary and LEA Dossier generation, TLP override procedures
- [ ] **S3-51** Update `docs/book/SUMMARY.md` — add Campaign, Impact Dashboard, Reports guides; add Intelligence architecture entry
- [ ] **S3-52** Update `docs/book/api/sample-requests.md` — add impact, campaign, and report endpoint examples
- [ ] **S3-53** Update `planning/change_log.md`

### Sprint 3 Exit Criteria

- [ ] **S3-EC** Impact Dashboard replaces `/analytics` with KPI cards and charts. Campaign Dashboard surfaces auto-detected and manually managed campaigns. Analyst can generate an Executive Summary PDF and an LEA Evidence Dossier. All tests pass.

---

## Sprint 4 — Network Graph + Taxonomy + Geography (Weeks 16–20)

_Goal: Ship Network Graph visualization, Taxonomy Explorer (Sankey/Heatmap/Trend), Geographic Heatmap, Timeline view. Phase 2 schema additions._

### Schema & Migrations

- [ ] **S4-01** Create Alembic migration: add `taken_down_at` TIMESTAMP column to `site_scans` — Data Gap P1
- [ ] **S4-02** Create Alembic migration: add `lea_referred_at`, `lea_agency`, `lea_case_number` columns to `cases` — Data Gap P2, F-51
- [ ] **S4-03** Create Alembic migration: add `victim_age_range` TEXT column to `intake_records` — Data Gap P1
- [ ] **S4-04** Create Alembic migration: split `contact_handle` into `contact_channel` + `contact_identifier` on `intake_records` — Data Gap P1

### API Endpoints — Graph

- [ ] **S4-05** Add `/api/intelligence/graph` endpoint — accepts seed (entity_id/case_id/campaign_id), hops (1/2/custom), filters (entity types, edge types, risk threshold, date range); returns `GraphPayload` JSON — F-23
- [ ] **S4-06** Add graph performance optimization: pre-compute layout for >500 nodes via NetworkX `spring_layout` — D13
- [ ] **S4-07** Add `/api/intelligence/graph/export` endpoint — render subgraph to PNG/SVG — F-26

### API Endpoints — Taxonomy & Geography

- [ ] **S4-08** Add `/api/impact/taxonomy/sankey` endpoint — Intent→Channel→Action flow data with case counts and avg risk — F-27
- [ ] **S4-09** Add `/api/impact/taxonomy/heatmap` endpoint — any two axes as X/Y, cell = case count or loss sum — F-28
- [ ] **S4-10** Add `/api/impact/taxonomy/trend` endpoint — time-series of one taxonomy value's share — F-29
- [ ] **S4-11** Add `/api/impact/geography` endpoint — country-level aggregation: scam site hosting (GeoIP), victim location, eCrimeX overlap — F-30
- [ ] **S4-12** Add `/api/impact/geography/{country}` endpoint — per-country case count, indicator count, loss sum, entity breakdown — F-31

### API Endpoints — Timeline

- [ ] **S4-13** Add `/api/intelligence/timeline` endpoint — multi-track temporal data: case volume, new indicators, victim reports, campaign lifetimes, actions — F-36

### Workflow Features — Backend

- [ ] **S4-14** Add entity status management: Active/Dormant/Flagged/Taken Down — automatic derivation from `last_seen_at` plus manual override — F-32
- [ ] **S4-15** Create `src/i4g/store/annotation_store.py` — freeform analyst notes on entities, indicators, campaigns — F-33
- [ ] **S4-16** Add eCrimeX submission from list views: submit selected indicators via existing eCX integration — F-34
- [ ] **S4-17** Add bulk entity actions: multi-select → export / eCX submit / tag — F-35

### Frontend — Network Graph

- [ ] **S4-18** Create Network Graph page at `/intelligence/graph` — D3.js force-directed layout with visual encoding per PRD Section 6.4 (node colors by entity type, size by case count, border by risk) — F-23
- [ ] **S4-19** Implement graph controls: seed search, expand 1-hop/2-hop, filter by entity type and edge type, risk threshold slider, date range — F-24
- [ ] **S4-20** Implement edge type visualization: co-occurrence (gray), shared IP (orange), same campaign (blue dashed) — F-25
- [ ] **S4-21** Add node interaction: click for detail panel, drag to pin, right-click context menu (expand, flag, submit to eCX)
- [ ] **S4-22** Implement graph export: render visible subgraph to PNG/PDF — F-26
- [ ] **S4-23** Add static layout rendering for >500 nodes (server-computed positions) — D13

### Frontend — Taxonomy Explorer

- [ ] **S4-24** Create Taxonomy Explorer at `/impact/taxonomy` — replaces/enhances current taxonomy page
- [ ] **S4-25** Implement Sankey diagram: Intent→Channel→Action flow, band width = case count, color intensity = avg risk, click to filter — F-27
- [ ] **S4-26** Implement Heatmap grid: select two axes as X/Y, cell color = case count or loss sum (toggle), hover for count, click to drill — F-28
- [ ] **S4-27** Implement Trend view: select one axis value, line chart of share over time (weekly) — F-29

### Frontend — Geographic Heatmap

- [ ] **S4-28** Create Geographic Heatmap at `/impact/geography` — world map with toggleable layers: scam site hosting (red), victim location (orange), eCrimeX overlap (blue) — F-30
- [ ] **S4-29** Implement country click → slide-over: case count, indicator count, loss sum, entity type breakdown, drill button — F-31

### Frontend — Timeline

- [ ] **S4-30** Create Timeline view at `/intelligence/timeline` — horizontal scrollable, multi-track: case volume bars, indicator marks, victim reports, campaign lifetime bands, action marks — F-36
- [ ] **S4-31** Implement granularity toggle (day/week/month) and zoom controls
- [ ] **S4-32** Implement event click → navigate to relevant detail page

### Frontend — Workflow

- [ ] **S4-33** Add entity status badges (Active/Dormant/Flagged/Taken Down) throughout entity views — F-32
- [ ] **S4-34** Add annotation panel on entity/indicator/campaign detail pages — F-33
- [ ] **S4-35** Add eCrimeX submission action buttons on Indicator Registry and Entity Explorer — F-34
- [ ] **S4-36** Add bulk selection + action toolbar on list views — F-35

### Report Templates — Sprint 4

- [ ] **S4-37** Create Campaign Intelligence Bulletin template — campaign summary, indicator list, taxonomy rollup, timeline, network graph render, source attribution (3-8 pages, TLP:AMBER) — F-37
- [ ] **S4-38** Create SAR Supplement template — FinCEN-structured indicator list with activity dates and narrative (PDF + XLSX, TLP:AMBER) — F-38

### Testing — Sprint 4

- [ ] **S4-39** Unit tests for graph API — seed/expand/filter, layout computation, >500 node threshold
- [ ] **S4-40** Unit tests for taxonomy API — Sankey, heatmap, trend data
- [ ] **S4-41** Unit tests for geography API — country aggregation, GeoIP mapping
- [ ] **S4-42** Unit tests for timeline API — multi-track data, granularity options
- [ ] **S4-43** Unit tests for entity status management and annotation store
- [ ] **S4-44** Unit tests for Campaign Intelligence Bulletin and SAR Supplement templates
- [ ] **S4-45** Frontend component tests: Network Graph rendering (with mock D3.js), node interactions
- [ ] **S4-46** Frontend component tests: Taxonomy Sankey, Heatmap, Trend
- [ ] **S4-47** Frontend component tests: Geographic Heatmap with country drill-down
- [ ] **S4-48** E2E smoke: seed graph from entity → expand 2-hop → export PNG → generate Campaign Bulletin PDF

### Documentation — Sprint 4

- [ ] **S4-49** Update TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — add Network Graph implementation (D3.js + NetworkX integration, layout algorithm, performance thresholds), Taxonomy Explorer data model, Geographic aggregation pipeline, Timeline architecture
- [ ] **S4-50** Update `docs/book/architecture/system-topology.md` — add GraphService component, analytics aggregation job to topology diagram
- [ ] **S4-51** Create `docs/book/guides/analyst/network_graph.md` — user guide: seeding a graph, expanding neighbors, filtering edges, interpreting visual encoding, exporting graph as evidence
- [ ] **S4-52** Create `docs/book/guides/analyst/taxonomy_explorer.md` — user guide: Sankey diagram, heatmap exploration, trend analysis
- [ ] **S4-53** Create `docs/book/guides/analyst/geographic_heatmap.md` — user guide: map layers, country drill-down, interpreting hotspots
- [ ] **S4-54** Create `docs/book/guides/analyst/timeline.md` — user guide: timeline tracks, zoom, event navigation
- [ ] **S4-55** Update `docs/book/guides/analyst/index.md` — add links to network graph, taxonomy, geography, timeline guides
- [ ] **S4-56** Create `core/docs/runbooks/console/network_graph.md` — ops runbook: graph performance monitoring, layout fallback triggers, D3.js rendering issues
- [ ] **S4-57** Create `core/docs/cookbooks/analytics_aggregation.md` — cookbook: running aggregation manually, verifying stats, troubleshooting stale data, configuring refresh interval
- [ ] **S4-58** Update `docs/book/SUMMARY.md` — add Network Graph, Taxonomy Explorer, Geographic Heatmap, Timeline guide entries
- [ ] **S4-59** Update `docs/book/api/sample-requests.md` — add graph, taxonomy, geography, timeline endpoint examples
- [ ] **S4-60** Update `planning/change_log.md`

### Sprint 4 Exit Criteria

- [ ] **S4-EC** Intelligence analyst can construct a network graph from a campaign, explore shared infrastructure via multi-hop expansion, and generate a Campaign Intelligence Bulletin PDF. Taxonomy Explorer shows Sankey/Heatmap/Trend views. Geographic Heatmap shows scam hosting and victim locations. All tests pass.

---

## Sprint 5 — Automation + Advanced Features (Weeks 21–25)

_Goal: Temporal graph animation, graph clustering, watchlist/alerts, shared infrastructure clustering job, passive DNS enrichment, scheduled reports, researcher data portal. Phase 3 features._

### Graph — Advanced

- [ ] **S5-01** Add temporal graph animation: date slider that animates graph growth over time — F-41
- [ ] **S5-02** Implement Louvain community detection in `GraphService.detect_clusters()` — auto-detect dense subgraphs and highlight clusters — F-42
- [ ] **S5-03** Add cluster visualization on Network Graph page: color-code communities, show cluster summary on hover

### Watchlist & Alerts

- [ ] **S5-04** Create `src/i4g/store/watchlist_store.py` — pin entities to watchlist, configure alert conditions — F-43
- [ ] **S5-05** Add `/api/intelligence/watchlist` endpoints — CRUD for watched entities, alert configuration
- [ ] **S5-06** Create watchlist notification job: check watched entities for new case activity, generate alerts
- [ ] **S5-07** Add watchlist UI: pin entities from Entity Explorer/Detail, watchlist management page, alert notifications on Intelligence Dashboard

### Infrastructure Clustering

- [ ] **S5-08** Create `src/i4g/worker/jobs/infrastructure_clustering.py` — scheduled job that queries entity co-occurrence and writes infrastructure edges (shared IP, shared registrar, shared hosting) — F-44
- [ ] **S5-09** Add infrastructure edge type to GraphService and graph API responses
- [ ] **S5-10** Add infrastructure cluster visualization on Network Graph

### External Enrichment

- [ ] **S5-11** Create passive DNS enrichment integration — SecurityTrails or Farsight DNSDB API for historical DNS resolution — F-45
- [ ] **S5-12** Add ASN enrichment — RIPE/ARIN RDAP API queries for IP addresses — Data Gap P2
- [ ] **S5-13** Create SSI re-scan job for takedown verification — periodic check of known scam URLs, set `taken_down_at` on confirmation

### Scheduled Reports

- [ ] **S5-14** Create `src/i4g/worker/jobs/scheduled_reports.py` — configurable auto-generation of recurring reports (weekly/monthly) — F-47
- [ ] **S5-15** Add schedule configuration UI in Report Builder — cadence, template, scope, recipients
- [ ] **S5-16** Add email delivery for scheduled reports (SMTP or SendGrid integration)

### Embeddable Charts

- [ ] **S5-17** Add shareable chart URLs with read-only, time-limited tokens — F-48
- [ ] **S5-18** Create embeddable chart render endpoint: `/api/charts/{chart_id}/embed?token=...`

### Researcher Access

- [ ] **S5-19** Implement Researcher role data anonymization layer: PII entity hashing, loss rounding to nearest $1K — D16, F-50
- [ ] **S5-20** Add anonymized aggregate CSV/JSON export from Impact Analytics views — F-50
- [ ] **S5-21** Create researcher data download page (accessible only with Researcher role)

### Victim Analytics

- [ ] **S5-22** Create victim analytics views: aggregate demographics (age range, country, contact channel) — F-49
- [ ] **S5-23** Add victim analytics tab on Impact Dashboard — age range distribution, country breakdown, contact channel breakdown

### Settings & Config

- [ ] **S5-24** Add settings for new features: `I4G_ANALYTICS__WATCHLIST_CHECK_INTERVAL_MINUTES`, `I4G_ANALYTICS__INFRASTRUCTURE_CLUSTERING_INTERVAL_HOURS`, `I4G_ANALYTICS__SCHEDULED_REPORT_*`
- [ ] **S5-25** Add unit tests for new settings under `tests/unit/settings/`

### Testing — Sprint 5

- [ ] **S5-26** Unit tests for temporal graph animation data generation
- [ ] **S5-27** Unit tests for Louvain clustering — community detection, cluster scoring
- [ ] **S5-28** Unit tests for watchlist — CRUD, alert threshold logic, notification generation
- [ ] **S5-29** Unit tests for infrastructure clustering job — edge detection, co-occurrence thresholds
- [ ] **S5-30** Unit tests for passive DNS and ASN enrichment (mocked APIs)
- [ ] **S5-31** Unit tests for scheduled report generation and delivery
- [ ] **S5-32** Unit tests for researcher anonymization layer
- [ ] **S5-33** Frontend component tests: graph animation, cluster visualization, watchlist UI
- [ ] **S5-34** E2E smoke: pin entity to watchlist → ingest new case → verify alert fires

### Documentation — Sprint 5

- [ ] **S5-35** Update TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — add Louvain clustering design, infrastructure edge construction, watchlist/alert architecture, scheduled report pipeline, external enrichment integration patterns, researcher anonymization pipeline
- [ ] **S5-36** Create `docs/book/guides/analyst/watchlist.md` — user guide: pinning entities, configuring alerts, managing watchlist
- [ ] **S5-37** Update `docs/book/guides/analyst/network_graph.md` — add temporal animation, cluster visualization, infrastructure edges
- [ ] **S5-38** Create `docs/book/guides/admin/scheduled_reports.md` — admin guide: configuring recurring reports, delivery settings, troubleshooting
- [ ] **S5-39** Update `core/docs/design/jobs.md` — add infrastructure clustering job, watchlist check job, scheduled report job, SSI re-scan job entries
- [ ] **S5-40** Update `docs/config/settings_manifest.yaml` and `settings_manifest.json` — add all new `I4G_ANALYTICS__*` env vars from Sprint 5
- [ ] **S5-41** Create `core/docs/cookbooks/external_enrichment.md` — cookbook: configuring passive DNS, ASN enrichment, troubleshooting API connectivity
- [ ] **S5-42** Create `core/docs/runbooks/console/watchlist_alerts.md` — ops runbook: monitoring watchlist jobs, alert delivery health
- [ ] **S5-43** Update `docs/book/guides/user-guide.md` — add researcher access section: available views, anonymization, export limitations
- [ ] **S5-44** Update `docs/book/SUMMARY.md` — add watchlist, scheduled reports, researcher access guide entries
- [ ] **S5-45** Update `docs/book/architecture/data-pipeline.md` — add enrichment sources (passive DNS, ASN, takedown verification) to pipeline diagram
- [ ] **S5-46** Update `planning/change_log.md`

### Sprint 5 Exit Criteria

- [ ] **S5-EC** Network Graph supports temporal animation, community clustering, and infrastructure edges. Watchlist alerts fire on new entity activity. Scheduled reports auto-generate and deliver via email. Researcher role sees anonymized aggregates. All tests pass.

---

## Sprint 6 — External Ecosystem + Polish (Weeks 26–30)

_Goal: Blockchain analytics integration, LEA referral tracking, partner indicator feed API, mobile summary views, final documentation sweep. Phase 4 features + hardening._

### Blockchain Analytics Integration

- [ ] **S6-01** Evaluate and select blockchain analytics vendor (Chainalysis Reactor, TRM Labs, or Elliptic) — vendor contract prerequisite — F-46
- [ ] **S6-02** Create `src/i4g/services/blockchain_enrichment.py` — API integration for wallet labels, risk scores, transaction amounts, exchange attribution
- [ ] **S6-03** Add wallet cluster edge type to GraphService — blockchain-derived wallet groupings
- [ ] **S6-04** Add blockchain enrichment data to Entity Detail (wallet entities): vendor risk label, transaction volume, exchange attribution
- [ ] **S6-05** Add "Wallet Cluster" (gold thick) edge type to Network Graph visualization

### LEA Referral Tracking

- [ ] **S6-06** Create LEA referral workflow UI: log referral date, agency, case number on case detail — F-51
- [ ] **S6-07** Add LEA referral tracking API: `/api/cases/{id}/lea-referral` (create/update referral record)
- [ ] **S6-08** Add referral status to Campaign Detail page — which member cases have been referred

### Partner Indicator Feed API

- [ ] **S6-09** Create partner-facing API: `/api/feeds/indicators` — machine-readable, TLP-tagged, paginated indicator feed with STIX 2.1 + CSV options — F-52
- [ ] **S6-10** Implement API key authentication for partner access (separate from console auth)
- [ ] **S6-11** Add rate limiting and audit logging for partner feed API

### Mobile Summary Views

- [ ] **S6-12** Create read-only mobile dashboard views (responsive Impact Dashboard, campaign alerts) — Phase 4
- [ ] **S6-13** Design mobile-appropriate chart rendering (simplified KPI cards, sparklines)

### Hardening & Performance

- [ ] **S6-14** Performance audit: dashboard load time targets (<2s for all aggregate views), graph rendering (<3s for 500 nodes)
- [ ] **S6-15** Add database indexes for analytics query patterns (entity_stats, campaign_stats, platform_kpis time-range queries)
- [ ] **S6-16** BigQuery migration readiness review: verify aggregation table schemas are portable per D2/Section 8.4
- [ ] **S6-17** Security audit: role-based access, PII masking, TLP enforcement, export audit completeness
- [ ] **S6-18** Accessibility audit: keyboard navigation, screen reader, color contrast on all new pages

### Testing — Sprint 6

- [ ] **S6-19** Unit tests for blockchain enrichment (mocked vendor API)
- [ ] **S6-20** Unit tests for LEA referral workflow
- [ ] **S6-21** Unit tests for partner indicator feed API — pagination, TLP filtering, rate limiting
- [ ] **S6-22** Performance tests: dashboard load, graph rendering, aggregation job duration
- [ ] **S6-23** Security tests: role escalation, PII leakage, export audit log completeness
- [ ] **S6-24** Full E2E regression: all user journeys A-D from PRD Section 9

### Documentation — Sprint 6 (Final Sweep)

- [ ] **S6-25** Update TDD: `core/docs/design/threat_intelligence_analytics_tdd.md` — add blockchain integration architecture, partner feed API design, BigQuery migration readiness assessment
- [ ] **S6-26** Create `docs/book/architecture/threat-intelligence.md` — architecture overview for the full TIFAP system: aggregation pipeline, graph service, campaign intelligence, report pipeline, external enrichments, partner feeds. Add to SUMMARY.md.
- [ ] **S6-27** Update `docs/book/architecture/security-model.md` — add: researcher role restrictions, TLP enforcement model, export audit logging, partner API authentication, PII anonymization in analytics
- [ ] **S6-28** Update `core/docs/design/campaign_governance_bridge.md` — reconcile threat campaign model with existing campaign governance design
- [ ] **S6-29** Create `docs/book/guides/admin/partner_feed.md` — admin guide: configuring partner API access, API key management, rate limits, monitoring feed consumption
- [ ] **S6-30** Update `docs/book/guides/law-enforcement.md` — add LEA referral tracking, referral status in campaign detail, updated dossier workflow with blockchain enrichment
- [ ] **S6-31** Create `core/docs/runbooks/analytics_operations.md` — comprehensive ops runbook: aggregation job health, stats freshness monitoring, BigQuery migration procedure, performance troubleshooting, external enrichment API health
- [ ] **S6-32** Update `core/docs/cookbooks/smoke_test.md` — add analytics smoke test procedures (aggregation job, dashboard API, report generation, partner feed)
- [ ] **S6-33** Update `core/docs/design/architecture.md` — add TIFAP components to system architecture overview
- [ ] **S6-34** Update `docs/book/api/taxonomy_reference.md` — add analytics-specific taxonomy usage (Sankey, heatmap, trend view data expectations)
- [ ] **S6-35** Update `ui/docs/developer-guide.md` — add TIFAP frontend development guide: new page structure (Intelligence, Impact, Reports), charting library (D3.js), graph rendering patterns, chart data contracts
- [ ] **S6-36** Update `ui/docs/ui_architecture.md` — final navigation map with all TIFAP sections, component hierarchy for Intelligence/Impact/Reports
- [ ] **S6-37** Update `ui/docs/user-guide.md` — consolidated user guide updates: Intelligence Hub (Entity Explorer, Indicator Registry, Network Graph, Campaigns, Timeline), Impact (Dashboard, Geography, Taxonomy), Reports (Builder, Library)
- [ ] **S6-38** Create `core/docs/runbooks/console/partner_feed_monitoring.md` — ops runbook: monitoring partner API usage, troubleshooting feed issues, rate limit alerts
- [ ] **S6-39** Update `docs/book/SUMMARY.md` — final pass: ensure all new guide entries, architecture entries, and API entries are linked
- [ ] **S6-40** Update `docs/book/api/sdk_endpoint_coverage.md` — final SDK coverage matrix including all TIFAP endpoints
- [ ] **S6-41** Update `docs/config/settings_manifest.yaml` and `settings_manifest.json` — final pass: all `I4G_ANALYTICS__*` env vars from all sprints
- [ ] **S6-42** Update `ssi/docs/tdd.md` — document CampaignCorrelator migration to threat_campaigns model
- [ ] **S6-43** Update `docs/book/ssi/ecrimex-integration.md` — add analytics view of eCrimeX submission/hit status, contribution metrics
- [ ] **S6-44** Update `planning/change_log.md` — record Sprint 6 deliverables and TIFAP completion summary

### Sprint 6 Exit Criteria

- [ ] **S6-EC** All PRD features F-00a through F-52 are implemented or explicitly deferred with rationale. All user journeys (A–D) work end-to-end. Documentation is comprehensive: TDD, architecture docs, user guides, admin guides, runbooks, cookbooks, API reference, config manifests all updated. Performance targets met. Security audit clean. Pre-commit double-pass clean.

---

## Cross-Sprint Documentation Inventory

Summary of all documentation deliverables, organized by document.

### New Documents

| Sprint | Document                                                | Type         |
| ------ | ------------------------------------------------------- | ------------ |
| S1     | `core/docs/design/threat_intelligence_analytics_tdd.md` | TDD          |
| S2     | `docs/book/guides/analyst/entity_explorer.md`           | User Guide   |
| S2     | `docs/book/guides/analyst/indicator_registry.md`        | User Guide   |
| S3     | `docs/book/guides/analyst/campaigns.md`                 | User Guide   |
| S3     | `docs/book/guides/analyst/impact_dashboard.md`          | User Guide   |
| S3     | `docs/book/guides/user-guide-reports.md`                | User Guide   |
| S3     | `core/docs/runbooks/console/intelligence_dashboard.md`  | Runbook      |
| S3     | `core/docs/runbooks/console/campaign_management.md`     | Runbook      |
| S4     | `docs/book/guides/analyst/network_graph.md`             | User Guide   |
| S4     | `docs/book/guides/analyst/taxonomy_explorer.md`         | User Guide   |
| S4     | `docs/book/guides/analyst/geographic_heatmap.md`        | User Guide   |
| S4     | `docs/book/guides/analyst/timeline.md`                  | User Guide   |
| S4     | `core/docs/runbooks/console/network_graph.md`           | Runbook      |
| S4     | `core/docs/cookbooks/analytics_aggregation.md`          | Cookbook     |
| S5     | `docs/book/guides/analyst/watchlist.md`                 | User Guide   |
| S5     | `docs/book/guides/admin/scheduled_reports.md`           | Admin Guide  |
| S5     | `core/docs/cookbooks/external_enrichment.md`            | Cookbook     |
| S5     | `core/docs/runbooks/console/watchlist_alerts.md`        | Runbook      |
| S6     | `docs/book/architecture/threat-intelligence.md`         | Architecture |
| S6     | `docs/book/guides/admin/partner_feed.md`                | Admin Guide  |
| S6     | `core/docs/runbooks/analytics_operations.md`            | Runbook      |
| S6     | `core/docs/runbooks/console/partner_feed_monitoring.md` | Runbook      |

### Updated Documents

| Sprints                | Document                                                | Updates                              |
| ---------------------- | ------------------------------------------------------- | ------------------------------------ |
| S1, S2, S3, S4, S5, S6 | `core/docs/design/threat_intelligence_analytics_tdd.md` | Iteratively expanded each sprint     |
| S1                     | `core/docs/design/data_model.md`                        | New tables, columns                  |
| S1, S5                 | `core/docs/design/jobs.md`                              | New job entries                      |
| S1                     | `core/docs/design/storage.md`                           | Aggregation tables in storage matrix |
| S1, S2, S5, S6         | `docs/config/settings_manifest.yaml` + `.json`          | New `I4G_ANALYTICS__*` env vars      |
| S1, S5                 | `docs/config/README.md`                                 | New config sections                  |
| S1                     | `core/docs/development/dev_guide.md`                    | Analytics development section        |
| S2                     | `core/docs/design/iam.md`                               | Researcher role                      |
| S2, S3, S4             | `docs/book/api/sample-requests.md`                      | New endpoint examples                |
| S2, S6                 | `docs/book/api/sdk_endpoint_coverage.md`                | New SDK methods                      |
| S2                     | `docs/book/api/field_name_translation.md`               | New model fields                     |
| S2, S6                 | `ui/docs/ui_architecture.md`                            | Navigation, component hierarchy      |
| S2, S3, S4, S5, S6     | `docs/book/SUMMARY.md`                                  | New guide/architecture entries       |
| S2, S4, S5             | `docs/book/guides/analyst/index.md`                     | Links to new guides                  |
| S3                     | `docs/book/architecture/data-pipeline.md`               | Aggregation stage                    |
| S3                     | `docs/book/guides/analyst/campaign_governance.md`       | Threat campaign model                |
| S3, S6                 | `docs/book/guides/law-enforcement.md`                   | LEA dossier, referral tracking       |
| S3                     | `core/docs/runbooks/console/reports.md`                 | New report templates                 |
| S4                     | `docs/book/architecture/system-topology.md`             | GraphService, aggregation job        |
| S5                     | `docs/book/guides/user-guide.md`                        | Researcher access                    |
| S5                     | `docs/book/architecture/data-pipeline.md`               | Enrichment sources                   |
| S6                     | `docs/book/architecture/security-model.md`              | TIFAP security additions             |
| S6                     | `core/docs/design/campaign_governance_bridge.md`        | Threat campaign reconciliation       |
| S6                     | `core/docs/design/architecture.md`                      | TIFAP components                     |
| S6                     | `core/docs/cookbooks/smoke_test.md`                     | Analytics smoke tests                |
| S6                     | `core/docs/api_reference.md`                            | Full TIFAP endpoint reference        |
| S6                     | `docs/book/api/taxonomy_reference.md`                   | Analytics taxonomy usage             |
| S6                     | `ui/docs/developer-guide.md`                            | TIFAP frontend guide                 |
| S6                     | `ui/docs/user-guide.md`                                 | Full TIFAP user guide                |
| S6                     | `ssi/docs/tdd.md`                                       | CampaignCorrelator migration         |
| S6                     | `docs/book/ssi/ecrimex-integration.md`                  | Analytics eCX views                  |
| S1–S6                  | `planning/change_log.md`                                | Sprint deliverables                  |

---

## Risk Register

| Risk                                                            | Impact                                           | Mitigation                                                                                                                         |
| --------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| LLM extraction accuracy for intake→indicator linkage is too low | Cumulative loss per entity will be unreliable    | Run spike (S1-24) early; if precision <70%, fall back to structural linkage only and surface "estimated" qualifier on loss figures |
| D3.js graph rendering is slow on analyst devices                | Network Graph unusable for real investigations   | Conservative 500-node threshold (D13); benchmark on target hardware in Sprint 4 QA; lower threshold if needed                      |
| Blockchain analytics vendor contract delays                     | F-46 (wallet enrichment) blocked                 | Sprint 6 tasks are stretch goals; core analytics value (entity stats, campaigns, graph) ships without blockchain data              |
| Aggregation job takes too long on production data               | Stale dashboard data, analyst trust erosion      | Monitor job duration from Sprint 1; optimize SQL queries; if >5 min, partition by date range or switch to incremental updates      |
| Campaign auto-detection produces noisy clusters                 | Analysts overwhelmed by false-positive campaigns | Start with conservative min_cluster_size (3+); add analyst feedback mechanism (dismiss/validate) in Sprint 3                       |

---

## Dependencies

| Dependency                                         | Needed By                                                     | Status             |
| -------------------------------------------------- | ------------------------------------------------------------- | ------------------ |
| eCrimeX integration complete                       | Sprint 1 (eCX status in entity_stats)                         | Done (2026-03-07)  |
| Fraud taxonomy classification pipeline             | Sprint 1 (classification_result in aggregation)               | Done               |
| Dossier pipeline (BundleBuilder, tools, templates) | Sprint 3 (report templates)                                   | Done               |
| SSI CampaignCorrelator                             | Sprint 1 (migration to threat_campaigns)                      | Done               |
| D3.js charting library in UI                       | Sprint 2 (Entity detail sparklines), Sprint 4 (Network Graph) | Needs evaluation   |
| matplotlib/plotly in core Python env               | Sprint 3 (server-side chart rendering)                        | Needs installation |
| Blockchain analytics vendor contract               | Sprint 6 (F-46)                                               | Not started        |
| Passive DNS vendor (SecurityTrails/Farsight)       | Sprint 5 (F-45)                                               | Not started        |

---

_End of Plan — TIFAP Implementation_
