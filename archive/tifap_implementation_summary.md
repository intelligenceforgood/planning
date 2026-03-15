# TIFAP Implementation Summary

**PRD:** [prd_threat_intelligence_analytics.md](../prd_threat_intelligence_analytics.md)
**Duration:** 6 sprints × 5 weeks (30 weeks) — Phases 0–4
**Completed:** 2026-03-14

---

## What Was Built

The Threat Intelligence & Fraud Analytics Platform (TIFAP) — a full analytics layer on top of the existing case/intake/indicator data, adding pre-computed aggregation, threat campaigns, network graph visualization, impact dashboards, report generation, and external integrations.

---

## Sprint Summary

### Sprint 1 — Data Foundation (Weeks 1–5)

Pre-computed aggregation layer, threat campaign model, schema prerequisites.

- **Schema:** `threat_campaigns`, `threat_campaign_cases`, `intake_indicator_links`, `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis` tables. Added `loss_currency`, `victim_country`, `ingestion_batch_id` columns.
- **Stores:** `ThreatCampaignStore`, `AnalyticsStore` registered in `factories.py`.
- **Aggregation job:** `analytics_aggregation.py` — computes stats from raw tables, campaign risk scoring (weighted formula), lifecycle auto-transitions, taxonomy rollup, PII soft-anonymization.
- **LLM extraction:** Intake narrative → indicator linkage with confidence scores. Backfill job for existing records.
- **CampaignCorrelator migration:** SSI correlator writes to `threat_campaigns` instead of `cases.campaign_id`. LLM-generated semantic campaign names.
- **Settings:** `[analytics]` section with `refresh_interval_minutes`, `loss_linkage_confidence_threshold`, `campaign_risk_weights`.

### Sprint 2 — Core Intelligence UI (Weeks 6–10)

Entity Explorer, Indicator Registry, Intelligence Dashboard, Global Search enhancement.

- **API:** `intelligence.py` router (entities, indicators, dashboard, sparklines, mini-graph), `exports.py` router (XLSX/CSV/STIX 2.1 with audit logging), indicator masking (last 4 digits, `?unmask=true`).
- **GraphService:** NetworkX-backed `get_neighbors()`, `get_subgraph()`, `detect_clusters()`.
- **Navigation restructure:** Added "Intelligence" and "Impact" top-level sections. Old URLs redirect.
- **Entity Explorer:** Filterable/sortable list, detail panel with sparkline + mini network graph + actions.
- **Indicator Registry:** Replaced `/accounts` — segmentation tabs, bulk actions (export, eCrimeX, tag).
- **Roles:** Researcher role with anonymized aggregate access.

### Sprint 3 — Impact Analytics + Campaigns + Reports (Weeks 11–15)

Impact Dashboard, Campaign Dashboard, report templates, LEA referral engine.

- **Impact API:** KPI cards with period comparison, loss-by-taxonomy treemap, detection velocity, pipeline funnel, cumulative indicators.
- **Campaign API:** List/detail, management (rename, merge, split, link/unlink), timeline, scoped network graph.
- **Reports:** Executive Impact Summary (TLP:AMBER), LEA Evidence Dossier (TLP:RED) with server-side chart rendering (matplotlib/plotly SVG embed). Two-tier chain-of-custody (per-record for LEA, aggregation-level for executive).
- **ExportAdapter framework:** Protocol-based `StixAdapter`, `CsvAdapter`, `XlsxAdapter`.
- **LEA referral engine:** Threshold-based suggestions (>$50K loss, >5 cases, eCX corroboration).

### Sprint 4 — Network Graph + Taxonomy + Geography (Weeks 16–20)

Network Graph, Taxonomy Explorer, Geographic Heatmap, Timeline.

- **Schema:** Added `taken_down_at` on `site_scans`; `lea_referred_at`/`lea_agency`/`lea_case_number` on `cases`; `victim_age_range`, split `contact_handle` → `contact_channel`+`contact_identifier` on `intake_records`.
- **Network Graph:** D3.js force-directed layout, 1/2/custom-hop expansion, edge types (co-occurrence, shared IP, campaign), export to PNG/SVG. Server-computed layout for >500 nodes.
- **Taxonomy Explorer:** Sankey (Intent→Channel→Action), Heatmap (any two axes), Trend (one value over time).
- **Geographic Heatmap:** World map with scam hosting / victim / eCX overlap layers, country drill-down.
- **Timeline:** Multi-track horizontal view (cases, indicators, victims, campaigns, actions), zoom.
- **Reports:** Campaign Intelligence Bulletin, SAR Supplement templates.

### Sprint 5 — Automation + Advanced Features (Weeks 21–25)

Temporal graph animation, clustering, watchlist/alerts, enrichment, scheduled reports, researcher portal.

- **Graph:** Temporal animation (date slider), Louvain community detection, cluster visualization.
- **Watchlist:** Pin entities, configure alert conditions, notification job.
- **Infrastructure clustering job:** Co-occurrence → infrastructure edges (shared IP/registrar/hosting).
- **External enrichment:** Passive DNS (SecurityTrails/Farsight), ASN (RIPE/ARIN RDAP), SSI takedown verification re-scan.
- **Scheduled reports:** Auto-generation with cadence/template/scope/recipients, email delivery (SMTP/SendGrid).
- **Embeddable charts:** Shareable URLs with time-limited tokens.
- **Researcher portal:** Anonymized aggregate exports, dedicated download page.
- **Victim analytics:** Age range, country, contact channel breakdowns on Impact Dashboard.

### Sprint 6 — External Ecosystem + Polish (Weeks 26–30)

Sprint 5 hardening, blockchain analytics, LEA referral tracking, partner feed, mobile views, final documentation.

- **Hardening:** STIX pattern escaping (injection fix), watchlist job resilience (per-item try/except), scheduled report failure handling (`last_run_at` on failure + deactivation), SDK–API alignment for Report Library, researcher access strategy (anonymize-and-serve), unified anonymization (SHA-256 hash + loss rounding).
- **Blockchain analytics:** Vendor integration stub, wallet cluster edges, entity detail enrichment.
- **LEA referral tracking:** Log date/agency/case number, referral status on campaigns.
- **Partner indicator feed:** `/api/feeds/indicators` (STIX 2.1 + CSV), API key auth, rate limiting, audit logging.
- **Performance/security/accessibility audits:** Dashboard <2s, graph <3s for 500 nodes.

---

## Key Architectural Decisions

| Decision                                                                                  | Rationale                                                                                          |
| ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Pre-computed stats tables (`entity_stats`, `indicator_stats`, etc.) over live aggregation | Dashboard latency <2s target; live queries on raw tables would be too slow at scale                |
| `threat_campaigns` as separate model from `cases.campaign_id`                             | Campaigns are M:N with cases; old `campaign_id` was ingestion-batch-level only                     |
| NetworkX for graph computation, D3.js for rendering                                       | Server handles layout/clustering computation; client handles interactive rendering                 |
| ExportAdapter protocol pattern                                                            | Pluggable export formats without modifying endpoint logic                                          |
| Two-tier chain-of-custody                                                                 | LEA needs per-record SHA-256 hashes; executive reports only need aggregation-level                 |
| 500-node threshold for server-computed layout                                             | D3.js force simulation becomes unusable above ~500 nodes on typical analyst hardware               |
| Researcher role = anonymize-and-serve (not block)                                         | Researchers get useful aggregated data while PII stays protected via deterministic SHA-256 hashing |
| `last_run_at` always advances on scheduled report failure                                 | Prevents infinite retry loops; failures logged + auto-deactivation after N failures                |
| STIX pattern values escaped before interpolation                                          | Prevents malformed STIX bundles and pattern injection from indicator values                        |

---

## Key Files & Modules

- **Aggregation job:** `src/i4g/worker/jobs/analytics_aggregation.py`
- **Stores:** `src/i4g/store/threat_campaign_store.py`, `src/i4g/store/analytics_store.py`, `src/i4g/store/watchlist_store.py`, `src/i4g/store/annotation_store.py`
- **API routers:** `src/i4g/api/intelligence.py`, `src/i4g/api/impact.py`, `src/i4g/api/campaigns.py`, `src/i4g/api/reports.py`, `src/i4g/api/exports.py`
- **Services:** `src/i4g/services/graph_service.py`, `src/i4g/services/lea_referral.py`, `src/i4g/services/export_adapters.py`, `src/i4g/services/blockchain_enrichment.py`
- **Report templates:** `templates/` (Executive Summary, LEA Dossier, Campaign Bulletin, SAR Supplement)
- **Settings:** `[analytics]` section in `src/i4g/settings.py`
- **TDD:** `core/docs/design/threat_intelligence_analytics_tdd.md`

---

## PRD Feature Coverage

All features F-00a through F-52 implemented. 287 tasks completed across 6 sprints (S1-01→S1-48, S2-01→S2-48, S3-01→S3-53, S4-01→S4-60, S5-01→S5-46, S6-H1→S6-H12, S6-01→S6-44).
