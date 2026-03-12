# PRD: Threat Intelligence & Fraud Analytics Platform (TIFAP)

**Status:** v1.0 — Consolidated for Stakeholder Review
**Date:** 2026-03-12
**Author:** Product Strategy
**Consolidates:** v0.1 (initial draft) + v0.2 (architecture refinement). All open questions resolved.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Strategic Context](#2-strategic-context)
3. [What We Have Today — Honest Assessment](#3-what-we-have-today--honest-assessment)
4. [Who This Is For — Personas](#4-who-this-is-for--personas)
5. [Design Decisions Already Made](#5-design-decisions-already-made)
6. [Platform Design — Pages & Interactions](#6-platform-design--pages--interactions)
7. [Campaign Intelligence — The Big Redesign](#7-campaign-intelligence--the-big-redesign)
8. [Analytics Data Architecture](#8-analytics-data-architecture)
9. [User Journeys](#9-user-journeys)
10. [Feature Catalogue](#10-feature-catalogue)
11. [Hardcopy & Export System](#11-hardcopy--export-system)
12. [Data Gaps & Collection Plan](#12-data-gaps--collection-plan)
13. [Phased Delivery](#13-phased-delivery)
14. [Success Metrics](#14-success-metrics)
15. [Appendix A: Design Decision Log](#appendix-a-design-decision-log)
16. [Appendix B: Industry & Market Research](#appendix-b-industry--market-research)
17. [Appendix C: Data Asset Inventory](#appendix-c-data-asset-inventory)

---

## 1. Executive Summary

Intelligence for Good (i4g) operates a fraud detection platform that classifies consumer scam reports across a five-axis taxonomy, investigates live scam sites with an automated browser agent (SSI), extracts financial indicators (crypto wallets, bank accounts, payment handles), and feeds intelligence into the eCrimeX industry clearinghouse. The platform has accumulated a structurally rich corpus: cases with multi-dimensional classifications, entities with temporal metadata, harvested crypto wallets from live scam sites, victim loss figures, and bidirectional eCrimeX enrichment.

None of this accumulated intelligence is currently surfaced as analytics. The console shows individual cases for analyst review and a batch export tool for financial indicators. No one — analyst, executive, law enforcement partner, or investor — can answer the questions that matter:

- Which threat actors cause the most financial harm?
- Which campaigns are still active and growing?
- What emerging fraud patterns should we be worried about?
- How much total loss have we detected? How does that compare to last quarter?
- Which indicators are connected to each other — and what does that network look like?

This PRD specifies the **Threat Intelligence & Fraud Analytics Platform (TIFAP)** — a set of analytics surfaces embedded in the existing console, backed by a pre-computed aggregation layer, and designed to work at two speeds simultaneously: **breadth** (how many fraud types, geographies, time ranges can I see at once?) and **depth** (from any summary number, can I drill to the individual case, the screenshot, the wallet address, the victim's report?).

### Three Lenses

The platform is organized around three complementary perspectives on the same data:

| Lens                      | Core Question                                          | Surfaces                            |
| ------------------------- | ------------------------------------------------------ | ----------------------------------- |
| **Entity Intelligence**   | Who are the actors? What infrastructure do they share? | Entity Explorer, Network Graph      |
| **Campaign Intelligence** | What operations are active? How are they evolving?     | Campaign Dashboard, Timeline        |
| **Impact Intelligence**   | How much harm? Where? Who is affected?                 | Impact Dashboard, Heatmap, Taxonomy |

Each lens allows horizontal navigation (breadth — scanning across entity types, time ranges, geographies) and vertical drilling (depth — from a KPI card, to a campaign, to an entity, to a case, to a screenshot). PDF reports are a first-class export at every drill level.

### Why Now

Three developments make this the right time:

1. **Data maturity.** The SSI campaign correlator already auto-clusters cases by shared wallets, shared IPs, and brand impersonation — but these campaigns are invisible in the console. The dossier pipeline already computes entity adjacency graphs, timeline events, and geographic analysis — but only for report generation, never for interactive exploration. We have the analytical primitives; we just haven't surfaced them.

2. **Stakeholder expectations.** Law enforcement partners need evidence packages that show cumulative impact, not just individual cases. Investors need platform impact metrics. Regulatory partners (FinCEN, FTC, ACCC) need structured exports. These are not nice-to-haves — they are table stakes for the partnerships we are pursuing.

3. **Competitive context.** Platforms like Chainalysis Reactor, IBM i2, and Palantir Gotham set the expectation for what intelligence analysis software looks like. Our data model already maps well to these tools' paradigms (objects with temporal edges, entity graphs, classification axes). The gap is UI, not data.

---

## 2. Strategic Context

### 2.1 Where i4g Sits in the Ecosystem

The fraud intelligence market operates at two speeds:

- **Real-time transaction fraud** (Sift, Sardine, NICE Actimize): sub-second decision engines embedded in payment flows. Not our domain.
- **Post-hoc investigative intelligence** (Chainalysis, IBM i2, Palantir Gotham, FTC Consumer Sentinel, FBI IC3): analytical platforms used after fraud occurs to attribute actors, measure harm, and build cases. This is our space.

Our specific niche within post-hoc intelligence is the **convergence** of several data streams that are typically siloed:

- Victim-submitted fraud reports (like IC3 complaints, but with five-axis classification)
- Automated scam site investigation (like what Netcraft or PhishLabs do, but with full evidence bundles)
- Crypto wallet harvesting from live sites (like what Chainalysis does, but at the point of scam operation rather than on-chain analysis)
- Industry clearinghouse enrichment via eCrimeX (like FS-ISAC sharing, but programmatic)

No other platform combines all four. The analytics platform should make this convergence visible and explorable.

### 2.2 Reference Frameworks

The platform's metrics and exports should be compatible with — or at minimum, mappable to — these established standards:

| Standard / Agency                | What They Define                               | Our Mapping                                  |
| -------------------------------- | ---------------------------------------------- | -------------------------------------------- |
| **FBI IC3** Annual Report        | Loss by crime type, geography, demographic     | Our taxonomy + intake records                |
| **FTC Consumer Sentinel**        | Fraud category, payment method, contact method | Our DeliveryChannel + RequestedAction axes   |
| **FinCEN BSA/SAR**               | Structured indicator lists with activity dates | Our indicators table + date ranges           |
| **FATF Virtual Assets**          | Wallet risk scoring, exchange attribution      | Our risk_score + future blockchain API       |
| **STIX/TAXII 2.1**               | Machine-readable threat intelligence exchange  | Our entity/indicator model → STIX objects    |
| **TLP (Traffic Light Protocol)** | Data sensitivity classification for sharing    | Applied to all exports                       |
| **MITRE ATT&CK** (future)        | Adversary techniques framework                 | Could map social engineering techniques axis |

### 2.3 Academic Foundations

Two research findings directly shape our analytics design:

**Power-law distribution of harm** (University of Cambridge Cybercrime Centre): A small number of threat actors cause disproportionate losses. This means the "Top Entities by Impact" ranking is the single most important analytical view — not because it's conceptually complex, but because it directly identifies where intervention has the highest ROI.

**Infrastructure reuse across campaigns** (CMU CyLab, Stanford, Georgia Tech): Fraudsters reuse hosting IPs, domain registrars, wallet clusters, and even page templates across campaigns. This means entity co-occurrence (two entities appearing in the same case) and shared infrastructure (two domains resolving to the same IP) are the primary signals for campaign attribution. Our SSI correlator already implements three strategies for this; the platform surfaces the results.

---

## 3. What We Have Today — Honest Assessment

This section matters because the prior draft overstated some gaps and missed existing capabilities. An accurate inventory prevents us from building what already exists.

### 3.1 What Already Works Well

**Five-axis fraud classification** (`cases.classification_result`)

- Every case carries scored labels across Intent, Channel, Technique, Action, and Persona
- This is richer than IC3's single-category classification and maps well to FTC's multi-faceted view
- Currently used only for individual case review — not aggregated, not trended

**Entity extraction with temporal metadata** (`entities` table)

- Entities carry `first_seen_at` and `last_seen_at`, automatically maintained
- Unique constraint on `(case_id, entity_type, canonical_value)` provides natural deduplication per case
- Types: wallet_address, ip, email, phone, person, domain, url, bank_account
- Currently: no cross-case aggregation is surfaced in the UI

**Financial indicator extraction** (`indicators` table + `AccountListService`)

- Structured indicators with `category` (bank/crypto/payments), `item` (institution name), `type` (account type), `number` (the identifier)
- LLM-powered extraction from case source documents
- Currently: batch extraction job triggered manually from `/accounts` page; no persistent aggregation

**Campaign auto-clustering** (`ssi/src/ssi/ecx/correlation.py`)

- `CampaignCorrelator` runs three strategies: wallet-based, IP/ASN-based, and brand-impersonation clustering
- Creates `campaigns` records and links cases via `cases.campaign_id` FK
- Minimum cluster size: 2 cases
- Currently: campaigns exist in the DB but the `/campaigns` page in the console is admin-only and minimal

**Dossier pipeline** (`core/src/i4g/reports/`)

- A mature LangChain-based tool suite: GeoReasonerTool, TimelineSynthesizerTool, EntityGraphTool, ChartRendererTool, NarrativeWriterTool
- BundleBuilder: filters cases by loss threshold, recency, jurisdiction; chunks into dossier plans
- Full PDF generation with dossier_exports, dossier_templates, template_engine
- Currently: used only for standalone dossier generation, not for interactive analytics

**EntityStore with indicator search** (`core/src/i4g/store/entity_store.py`)

- `search_cases_by_indicator()`: finds cases by indicator type+value with exact/prefix/contains matching
- Supports dataset filtering and loss bucket range filtering
- Returns case_id, classification, loss_amount per match
- Currently: powers the case-to-indicator search flow; no entity-level aggregation

**eCrimeX bidirectional integration** (`ecx_submissions` + `ecx_polling_state`)

- Outbound: indicators submitted to APWG clearinghouse with tracking
- Inbound: phish/domain/IP/crypto enrichment polled from eCX
- SSI enrichment result attached to investigation output
- Currently: visible only in SSI investigation details; no aggregate view of our contribution to or benefit from the clearinghouse

**SSI investigation evidence** (`site_scans`, `harvested_wallets`, `pii_exposures`, `agent_sessions`)

- Full investigation record: WHOIS, DNS, SSL, GeoIP, page screenshots, harvested wallets, PII collection forms identified
- Chain-of-custody manifests with SHA-256 hashing already implemented
- Currently: viewable per-investigation in the SSI section; no aggregate analytics

### 3.2 What the Current `/accounts` Page Actually Does

The `/accounts` page is not an entity browser or indicator registry. It is a **batch extraction tool**:

1. Analyst fills a form: date range, categories (bank/crypto/payments), top-K, output format (XLSX/PDF)
2. System runs an LLM extraction job over case source documents within that date range
3. Job produces a flat deduplicated indicator list and saves artifacts (XLSX, PDF files)
4. Analyst downloads the artifacts
5. Run history is displayed

This is useful as an export mechanism but is architecturally wrong as the primary analytics surface:

- It re-extracts on every run (no persistence of aggregated stats)
- No entity-level aggregation (same wallet across 30 cases = 30 rows, not 1 row with case_count=30)
- No temporal context (no first_seen, last_seen, activity trend)
- No loss attribution (victim loss amounts from intake records are never joined)
- No interactivity (no drill-down, no graph, no filter-and-explore)
- No role differentiation (everyone sees the same form)

### 3.3 What is Actually Missing (not overstated)

The real gaps, distinguishing what doesn't exist at all from what exists but isn't surfaced:

| Gap Category                           | Description                                                                                                                                                                                                              | Severity                         |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| **No entity-level pre-computed stats** | Entity/indicator case counts, loss sums, risk scores are never aggregated — every query is ad hoc                                                                                                                        | Critical                         |
| **Loss not linked to indicators**      | `intake_records.loss_amount` has `case_id` FK but no `indicator_id` — loss is at case level, not indicator level                                                                                                         | Critical                         |
| **No interactive analytics UI**        | The dossier pipeline computes entity graphs, timelines, and geo analysis — but only for PDF output, never for browser exploration                                                                                        | Critical                         |
| **Campaigns are invisible**            | Auto-clustering creates campaigns but the console barely surfaces them                                                                                                                                                   | High                             |
| **Campaign ≠ batch upload**            | `campaign_id` today is overloaded: sometimes it means "a student competition batch upload," sometimes it means "an auto-detected threat cluster." These are fundamentally different concepts and need distinct modeling. | High                             |
| **No loss currency**                   | `loss_amount` is a raw float with no currency field                                                                                                                                                                      | Medium                           |
| **No victim demographics**             | No age, location, or structured contact_channel fields on intake records                                                                                                                                                 | Medium                           |
| **No takedown tracking**               | No record of whether a scam site went offline after intervention                                                                                                                                                         | Medium                           |
| **No LEA referral tracking**           | No record of which cases were referred to law enforcement                                                                                                                                                                | Medium                           |
| **taxonomy_rollup never populated**    | The `campaigns.taxonomy_rollup` field exists but is never computed                                                                                                                                                       | Medium                           |
| **No blockchain on-chain data**        | We harvest wallet addresses but not transaction amounts or wallet entity labels                                                                                                                                          | Lower (requires vendor contract) |

---

## 4. Who This Is For — Personas

### P1 — Fraud Analyst (Primary Daily User)

The person who reviews cases, looks up indicators, and decides what to escalate. They want to answer: "This wallet address just showed up in a new case — have we seen it before? In how many cases? How much total loss? Is it part of a known campaign?"

**Key needs:** indicator lookup with instant context, entity detail with related cases, one-click eCrimeX submission, short PDF summary for supervisor briefing.

### P2 — Intelligence Analyst (Strategic Pattern Work)

The person who steps back from individual cases to identify emerging campaigns, attribute infrastructure to threat actors, and produce intelligence reports. They think in graphs and timelines, not rows and columns.

**Key needs:** network graph with entity expansion, campaign lifecycle tracking, temporal animation, PDF intelligence bulletins for partner distribution.

### P3 — Law Enforcement Liaison (Evidence Packages)

Not a daily console user. Receives a tip or an indicator and needs a legally defensible evidence package: chain of custody, timestamped screenshots, source attribution, cumulative impact across all related cases.

**Key needs:** indicator lookup → evidence dossier PDF with SHA-256 chain of custody. Does not need to navigate complex dashboards — needs a direct path from indicator to package. The platform should _prompt analysts_ when a case or entity cluster is strong enough to warrant LEA referral, then the analyst reviews and decides whether to compile the dossier.

### P4 — Executive / Investor Audience

Needs quarterly impact metrics: total fraud detected, estimated victim losses, platform growth trends, geographic coverage. Consumes PDFs and slide-ready charts, not interactive tools.

**Key needs:** Impact Dashboard with period comparison, one-click quarterly summary PDF.

### P5 — Compliance Officer

Extracts structured indicator lists for FinCEN SAR supplements and regulatory reporting. Needs date range + category filtering with export in compliance-compatible formats.

**Key needs:** Indicator Registry filtered export to XLSX with SAR-compatible field structure.

### P6 — Industry Partner (Bidirectional)

ISPs, banks, payment providers, domain registrars, or exchanges that receive indicator feeds and contribute observations. Machine-to-machine in most cases.

**Key needs:** STIX 2.1 export, TLP-tagged indicator feeds, API access for programmatic integration.

### P7 — Academic Researcher

Studies fraud economics, social engineering patterns, and victim demographics. Needs anonymized aggregate statistics, not case-level PII.

**Key needs:** Anonymized aggregate CSV/JSON datasets exportable from Impact Analytics views.

---

## 5. Design Decisions Already Made

The following questions were raised in the v0.1 draft and have been resolved through discussion. They are recorded here as binding constraints on the design.

### D1: Campaign Model — Hybrid (Auto + Manual)

**Decision:** Campaigns are both auto-detected by algorithmic clustering AND manually manageable by analysts.

**Rationale:** The SSI `CampaignCorrelator` already implements three auto-clustering strategies (wallet-based, IP-based, brand-impersonation). Without automated detection, emerging patterns are invisible unless a single analyst happens to be watching all incoming cases — which does not scale when intake review is distributed across a team. However, automated clustering alone is insufficient: analysts need to annotate, merge, split, rename, and enrich campaigns based on domain expertise.

**Important context:** The `campaign_id` field on `cases` is currently overloaded. It sometimes represents a "batch upload cycle" (e.g., a student competition cohort) and sometimes represents a threat-operation cluster detected by the correlator. These are fundamentally different concepts. The analytics platform must distinguish between **ingestion batches** (provenance) and **threat campaigns** (attribution). See Section 7 for the detailed design.

### D2: Entity Aggregation — Scheduled Job (not Materialized Views)

**Decision:** Pre-computed entity/indicator stats will be written to denormalized tables (`entity_stats`, `indicator_stats`) by a scheduled job, not by PostgreSQL materialized views.

**Rationale:** Materialized views are elegant but fragile — refresh timing, dependency chains, and debugging are harder than a simple job that runs SQL aggregation queries and writes results. Database triggers were also considered but rejected as too complex to design correctly and painful to debug.

**BigQuery consideration:** The question was raised whether BigQuery might be a better target for aggregated data than PostgreSQL. For the current data volumes, PostgreSQL is sufficient and avoids introducing a new infrastructure dependency. However, the aggregation job should be designed with a clear ETL boundary so that if volumes grow, we can redirect the output to BigQuery without restructuring the analytics queries. Specifically: the aggregation job should produce well-defined output schemas (entity_stats, indicator_stats, campaign_stats) that can be consumed by either PostgreSQL queries or BigQuery queries with only the data source swapped. If we later need BigQuery for scale, the investment will be in the data pipeline (dbt or equivalent), not in rearchitecting the UI queries.

### D3: Graph Infrastructure — In-Memory First, Neo4j Later

**Decision:** Start with in-memory graph computation (NetworkX on the Python backend), serve pre-computed graph payloads to the frontend. Architect the graph service behind an abstraction layer so Neo4j can be swapped in later.

**Rationale:** The `EntityGraphTool` in the dossier pipeline already computes entity-to-case adjacency graphs in memory. We should extend this pattern rather than introduce a new infrastructure dependency. The system will not scale to millions of entities quickly, so we have time to migrate.

**Abstraction contract:**

```python
class GraphService(Protocol):
    def get_neighbors(self, entity_id: str, *, hops: int = 1) -> GraphPayload: ...
    def get_subgraph(self, entity_ids: list[str]) -> GraphPayload: ...
    def detect_clusters(self, min_size: int = 3) -> list[Cluster]: ...
```

The initial implementation uses NetworkX behind this interface. A future Neo4j implementation would satisfy the same interface. The frontend graph rendering (D3.js force layout) doesn't change regardless of backend.

### D4: LEA Dossier — Analyst-Prompted, Not Automated

**Decision:** LEA dossier generation is not automated. The platform should _prompt_ analysts when it detects a cluster or entity that meets referral criteria (loss threshold, indicator count, eCrimeX corroboration), but the analyst makes the decision to compile and export the dossier.

**Rationale:** We are not yet at the stage where automated LEA referral is appropriate — the legal, procedural, and relationship requirements vary by jurisdiction and agency. The right UX is:

1. Platform surfaces a "potential LEA case" prompt (e.g., an entity with >$50K cumulative loss, >5 cases, eCrimeX hits)
2. Analyst reviews a synopsis (entity stats, case list, loss summary, evidence availability)
3. Analyst decides whether to compile the full dossier
4. If yes, the dossier pipeline kicks in — generating the chain-of-custody PDF from the existing dossier infrastructure

This builds on the existing `BundleBuilder` which already filters by `min_loss_usd` and computes dossier plans.

### D5: Loss-to-Indicator Linkage — Critical Priority

**Decision:** Linking victim loss amounts to specific indicators is a P0 prerequisite for the analytics platform.

**Rationale:** Without this linkage, we cannot answer "which wallet address has caused $1.2M in losses" — we can only say "this wallet appears in 31 cases" without knowing the dollar impact. The metric "cumulative loss per entity" is the single most compelling number for executives, law enforcement, and investors. Two approaches will be combined:

1. **Structural linkage:** Add optional `indicator_id` FK on `intake_records` for cases where the association is explicit
2. **LLM extraction:** Run an extraction pass over intake narratives to identify mentioned financial indicators and create soft links (a join table `intake_indicator_links` with `confidence` score)

This is Phase 1 work — no analytics feature should ship without it.

---

## 6. Platform Design — Pages & Interactions

### 6.1 Revised Console Navigation

The current console navigation has these entries:

- Dashboard, Search, Account list, Discovery, Cases & Tasks, Evidence dossiers, Campaigns, Taxonomy, Analytics, Scam Investigator (with sub-pages)
- Plus admin-only: Users

The analytics platform reorganizes this into a clearer information architecture:

```
Console
├── Dashboard (enhanced — absorbs current analytics widgets)
├── Search (enhanced — cross-entity, cross-indicator, cross-case)
│
├── Cases & Tasks (existing, minimal changes)
├── Scam Investigator (existing SSI section, unchanged)
│
├── Intelligence ← NEW top-level section
│   ├── Entity Explorer (replaces nothing — new)
│   ├── Indicator Registry (replaces Account List)
│   ├── Network Graph (new)
│   ├── Campaigns (promotes existing admin-only page to full capability)
│   └── Timeline (new)
│
├── Impact ← NEW top-level section
│   ├── Impact Dashboard (replaces current Analytics page)
│   ├── Geographic Heatmap (new)
│   └── Taxonomy Explorer (replaces/enhances current Taxonomy page)
│
├── Reports ← NEW top-level section
│   ├── Evidence Dossiers (moves from current position)
│   ├── Report Builder (new)
│   └── Report Library (new)
│
├── Discovery (existing)
└── Admin (existing)
    └── Users
```

**What moves where:**

- `/accounts` → becomes `/intelligence/indicators` (Indicator Registry)
- `/analytics` → becomes `/impact` (Impact Dashboard, enhanced significantly)
- `/taxonomy` → becomes `/impact/taxonomy` (interactive, not just a reference page)
- `/campaigns` → becomes `/intelligence/campaigns` (promoted from admin-only to analyst-visible, major enhancement)
- `/reports/dossiers` → moves under `/reports/dossiers`
- `/dashboard` → enhanced with intelligence widgets but keeps its URL

### 6.2 Intelligence Hub — Entity Explorer

**URL:** `/intelligence/entities`
**Persona:** P1 (Fraud Analyst), P2 (Intelligence Analyst)

This is the heart of the analytics platform. Every unique entity (wallet, IP, email, phone, domain, bank account, person, URL) is a first-class object with pre-computed stats.

**List View:**

| Column          | Source                                                    | Default Sort |
| --------------- | --------------------------------------------------------- | ------------ |
| Entity Type     | `entity_stats.entity_type`                                | —            |
| Value           | `entity_stats.canonical_value` (masked for bank accounts) | —            |
| Case Count      | Pre-computed                                              | ✓ descending |
| First Seen      | `entity_stats.first_seen_at`                              | —            |
| Last Active     | `entity_stats.last_seen_at`                               | —            |
| Cumulative Loss | Pre-computed from intake linkage                          | —            |
| Peak Risk Score | MAX(cases.risk_score)                                     | —            |
| Campaign        | Campaign name if linked                                   | —            |
| Status          | Active / Dormant / Flagged                                | —            |

**Filters** (sidebar, combinable):

- Entity type checkboxes (wallet, ip, email, phone, domain, url, bank_account, person)
- Activity window (date range picker for first_seen / last_seen)
- Minimum case count (slider)
- Minimum cumulative loss (input)
- Risk score range (slider)
- Campaign membership (dropdown)
- Status toggle (Active / Dormant / All)

**Entity Detail** (slide-over panel or dedicated page `/intelligence/entities/{entity_id}`):

The detail view has four sections:

**Header:** Entity type icon + value + risk badge + status + first/last seen dates

**Impact section:** Case count, victim count, cumulative loss (with currency note), average loss per victim. Below: a sparkline showing case count per week over the entity's lifetime.

**Related Cases table:** case_id, detected_at, classification, risk_score, status, loss_amount — sorted by most recent. Each row links to case detail.

**Network mini-graph:** 1-hop entity co-occurrence graph (entities that appear in the same cases as this entity). Each neighbor node shows its own case count. Clicking a node navigates to that entity's detail. A button opens the full Network Graph view seeded with this entity.

**Actions:** Expand Network, Export Summary PDF, Submit to eCrimeX, Flag for Review, Add Annotation.

### 6.3 Intelligence Hub — Indicator Registry

**URL:** `/intelligence/indicators`
**Persona:** P1 (Fraud Analyst), P5 (Compliance Officer), P6 (Industry Partner)
**Replaces:** Current `/accounts` page

The "Account List" page is reconceived as the **Indicator Registry** — a persistent, always-up-to-date, browsable list of all financial indicators extracted from cases. No batch job required.

The existing `AccountListService` batch extraction job remains available as an on-demand "re-extraction" action for specific date ranges where the analyst suspects missed indicators. But the primary view is the pre-computed registry.

**Segmentation tabs:** All | Bank | Crypto | Payments | IP | Domain

**List View:**

| Column          | Notes                                                                     |
| --------------- | ------------------------------------------------------------------------- |
| Indicator       | Masked for bank accounts (last 4 digits); full for wallets                |
| Category / Type | bank/crypto/payments + sub-type (checking, savings, cryptocurrency, etc.) |
| Institution     | Bank name, coin name, or payment service                                  |
| First Seen      | `indicator_stats.first_seen_at`                                           |
| Last Active     | `indicator_stats.last_seen_at`                                            |
| Case Count      | Pre-computed                                                              |
| Cumulative Loss | Sum of linked intake losses                                               |
| Risk Level      | Badge: Critical / High / Medium / Low                                     |
| eCX Status      | Submitted / Hit / Not Submitted                                           |

**Bulk actions:** Export selection (XLSX, CSV, STIX 2.1), Submit to eCrimeX, Tag.

**Key design question resolved:** The Entity Explorer and Indicator Registry overlap — both show "things that appear in cases." The distinction is:

- **Entity Explorer** = all entity types, optimized for intelligence analysts doing cross-type exploration and graph analysis
- **Indicator Registry** = financial indicators specifically, optimized for compliance officers and partner feeds, with institution/category filtering and SAR-format exports

Both views drill into the same underlying entity detail panel. They are different lenses on overlapping data, not separate data stores.

### 6.4 Intelligence Hub — Network Graph

**URL:** `/intelligence/graph`
**Persona:** P2 (Intelligence Analyst), P1 (Fraud Analyst), P3 (LEA Liaison)

Force-directed graph where nodes are entities and edges represent co-occurrence in cases or shared infrastructure. This is our equivalent of IBM i2 Analyst's Notebook — in the browser.

**Node visual encoding:**

| Entity Type    | Color  | Icon     |
| -------------- | ------ | -------- |
| wallet_address | Amber  | Wallet   |
| ip             | Red    | Server   |
| domain / url   | Orange | Globe    |
| email          | Blue   | Envelope |
| phone          | Teal   | Phone    |
| bank_account   | Green  | Bank     |
| person         | Purple | User     |

Node size scales with case count. Border thickness scales with risk score.

**Edge types:**

- **Co-occurrence** (gray, thin): two entities appear in the same case
- **Shared IP** (orange, solid): a domain resolves to an IP via DNS data
- **Same campaign** (blue, dashed): both linked to the same campaign_id
- **Wallet cluster** (gold, thick): future — blockchain analytics cluster

**Controls:**

- Seed from entity search, case ID, or campaign ID
- Expand neighbors: 1-hop / 2-hop / custom
- Filter by entity type, edge type, risk score threshold
- Date range slider (future Phase 3: animate graph growth over time)
- Pin nodes for stable layout during exploration
- Select subgraph → Export as PNG/SVG or trigger dossier PDF

**Implementation note (D3):** The GraphService (see Section 8) computes the graph on the backend and sends a JSON payload of nodes and edges to the frontend. The frontend uses D3.js force-directed layout. For graphs exceeding ~500 nodes, the backend should pre-compute layout coordinates (using NetworkX spring_layout or similar) and send positioned nodes to avoid browser-side layout jitter. The frontend then renders but doesn't re-layout.

### 6.5 Intelligence Hub — Campaigns (Major Enhancement)

**URL:** `/intelligence/campaigns`
**Persona:** P2 (Intelligence Analyst), P4 (Executive)

Currently admin-only and minimal. This becomes a core analytical surface.

See Section 7 for the complete campaign intelligence design, including the important disambiguation between ingestion batches and threat campaigns.

### 6.6 Intelligence Hub — Timeline

**URL:** `/intelligence/timeline`
**Persona:** P2 (Intelligence Analyst), P4 (Executive)

Horizontal scrollable timeline placing case clusters, campaign lifetimes, indicator emergence, and actions on a common temporal axis.

**Tracks** (toggleable):

1. **Case volume** — bar chart (day/week/month granularity, zoomable)
2. **New indicators** — colored marks by type (wallet=amber, domain=orange, ip=red, etc.)
3. **Victim reports** — intake record submissions
4. **Campaigns** — horizontal bands showing campaign lifetime and status (Emerging → Active → Declining → Dormant)
5. **Actions** — eCrimeX submissions, dossier generations, LEA referrals (when tracked)

Any event on any track is clickable → navigates to the relevant detail page.

### 6.7 Impact Dashboard

**URL:** `/impact`
**Persona:** P4 (Executive), P5 (Compliance Officer)

Replaces the current `/analytics` page. The existing analytics endpoint already computes detection rate, time-to-action, proactive interventions, and SLA adherence. This page enhances those with loss-based KPIs and richer visualizations.

**KPI Cards** (top row, each with vs-prior-period trend):

| KPI                      | Formula                                                                  |
| ------------------------ | ------------------------------------------------------------------------ |
| Total Detected Cases     | COUNT(cases) in period                                                   |
| Estimated Victim Losses  | SUM(linked intake_records.loss_amount) in period                         |
| Active Threat Actors     | Distinct entities with last_seen_at within 30 days                       |
| Sites Investigated       | COUNT(site_scans) in period                                              |
| Unique Indicators        | COUNT(indicators) in period                                              |
| Detection-to-Action Time | Median hours from case creation to first review_action (existing metric) |

**Charts:**

- **Loss by fraud type** (treemap): area proportional to loss sum per `classification` label
- **Cases by delivery channel** (donut): EMAIL / SMS / CHAT / SOCIAL / PHONE / WEB
- **Cases by requested action** (horizontal bar): SEND_MONEY / GIFT_CARDS / CRYPTO / CREDENTIALS / etc.
- **Detection velocity** (line chart): cases per week, split by proactive (SSI) vs reactive (user-report)
- **Cumulative indicators** (area chart): running total of unique indicators over time, stacked by category
- **Source pipeline** (funnel): intake → ingestion → classification → review → action — showing drop-off

Period selector: Last 7 days / 30 days / 90 days / Quarter / Year / Custom range.

### 6.8 Geographic Heatmap

**URL:** `/impact/geography`
**Persona:** P2 (Intelligence Analyst), P4 (Executive), P3 (LEA)

The `GeoReasonerTool` in the dossier pipeline already computes jurisdiction counts and cross-border patterns. This page surfaces that analysis interactively.

**Map layers** (toggleable):

- **Scam site hosting** (red intensity): GeoIP country of scam site IPs from site_scans metadata
- **Victim location** (orange intensity): from intake_records.victim_country (new field — see Data Gaps)
- **eCrimeX overlap** (blue outline): countries where eCX also has matching indicators

Click a country → slide-over: case count, indicator count, loss sum, entity type breakdown, "drill into cases" button.

### 6.9 Taxonomy Explorer

**URL:** `/impact/taxonomy`
**Persona:** P2 (Intelligence Analyst), P5 (Compliance Officer), P7 (Researcher)

Interactive visualization of the five classification axes. Currently `/taxonomy` is a reference page — this becomes an analytical tool.

**Primary view — Sankey diagram:**
Flow from Intent → Channel → Action. Band width = case count. Color intensity = average risk score. Clicking a band filters to those cases.

**Secondary view — Heatmap grid:**
Select any two axes as X and Y. Cell color = case count (or loss sum, toggle). Hovering shows the exact count. Clicking a cell drills into the cases at that intersection.

**Trend view:**
Select one axis value (e.g., INTENT.INVESTMENT) and see how its share of total cases has changed over time (line chart, weekly resolution).

---

## 7. Campaign Intelligence — The Big Redesign

This section addresses the most important architectural decision in the PRD: what a "campaign" means and how it is managed.

### 7.1 The Problem with `campaign_id` Today

The `campaign_id` field on `cases` currently conflates two unrelated concepts:

1. **Ingestion batch**: "These 50 cases came from the January 2026 student competition submissions." This is a provenance label — it tells you _how_ the data arrived, not what fraud operation it belongs to.

2. **Threat campaign**: "These 12 cases all involve domains hosted on the same two IPs, all impersonating the same brand, all active since January 13." This is an intelligence attribution — it tells you the cases are _related by adversary behavior_.

These serve completely different analytical purposes. An ingestion batch is useful for data quality tracking (how many cases from competition X were high-risk?). A threat campaign is useful for intelligence work (what infrastructure does this threat actor control?).

### 7.2 Proposed Model: Separate Provenance from Attribution

**Ingestion batches** continue to use the existing `ingestion_runs` table plus optional `campaign_id` set at import time. The name "campaign_id" is unfortunate but can be aliased in the UI as "Source Batch" to avoid confusion. No schema change needed — just a UI label change.

**Threat campaigns** get a new first-class model:

```
threat_campaigns
├── campaign_id (UUID PK)
├── name (TEXT) — analyst-assigned or auto-generated
├── description (TEXT) — analyst notes
├── origin (TEXT) — "auto:wallet_cluster" / "auto:infrastructure" / "auto:brand" / "manual"
├── status (TEXT) — "emerging" / "active" / "declining" / "dormant" / "closed"
├── risk_score (NUMERIC) — computed
├── taxonomy_rollup (JSON) — aggregated from member cases
├── created_at, updated_at (TIMESTAMP)
├── created_by (TEXT) — analyst or "system"
└── metadata (JSON) — open-ended

threat_campaign_cases (join table — M:N)
├── campaign_id FK
├── case_id FK
├── linked_at (TIMESTAMP)
├── linked_by (TEXT)
├── link_reason (TEXT) — "shared_wallet:0xABC...", "shared_ip:1.2.3.4", "manual", etc.
└── UNIQUE(campaign_id, case_id)
```

**Why M:N instead of FK on cases:**
A single case can legitimately belong to multiple threat campaigns. A domain might be part of both a "Shared Infrastructure: 1.2.3.4" campaign and a "Brand Impersonation: Chase Bank" campaign — because both are true simultaneously. The current FK model (`cases.campaign_id`) forces a single campaign per case, which loses information.

The existing `CampaignCorrelator` auto-creation logic writes to the new `threat_campaigns` table instead of updating `cases.campaign_id`. The existing `cases.campaign_id` retains its ingestion-batch meaning.

### 7.3 Campaign Lifecycle

| State         | Meaning                                              | Transition Conditions                            |
| ------------- | ---------------------------------------------------- | ------------------------------------------------ |
| **Emerging**  | Newly auto-detected or manually created, <7 days old | Default state on creation                        |
| **Active**    | New cases are still being linked                     | Any new case linked, or analyst manual promotion |
| **Declining** | No new cases in 14 days but not closed               | Automatic transition after 14-day inactivity     |
| **Dormant**   | No new cases in 30+ days                             | Automatic transition                             |
| **Closed**    | Analyst determination that threat is resolved        | Manual only                                      |

State transitions can be automatic (based on case linking activity) or manual (analyst action).

### 7.4 Campaign Dashboard

**URL:** `/intelligence/campaigns`

**List view** shows campaign cards:

```
┌─────────────────────────────────────────────────────┐
│  Pig Butchering Wave — Jan 2026                     │
│  Origin: auto:wallet_cluster → manual rename        │
│  Status: ACTIVE  ·  Risk: 87/100                    │
│  Cases: 47  ·  Loss: $980,000  ·  Indicators: 54    │
│  Duration: Jan 8 → present (63 days)                │
│  Primary types: wallet (34), domain (12), ip (8)    │
└─────────────────────────────────────────────────────┘
```

**Filters:** Status, risk score range, date range, origin (auto/manual), loss threshold.
**Sort:** By risk score, loss, case count, recency.

**Campaign Detail** (`/intelligence/campaigns/{campaign_id}`):

- **Header:** Name, description, origin, status, risk score, created_by, date range
- **Key metrics:** Case count, indicator count, cumulative loss, average loss per victim, victim count
- **Timeline:** Cases per day over campaign lifetime, with markers for key events (first detection, peak, decline)
- **Taxonomy rollup:** Aggregated classification across all member cases — which intents, channels, techniques, actions, personas are represented, and in what proportions
- **Entity list:** All entities/indicators across member cases, deduplicated, with per-entity case count within this campaign
- **Network graph:** Scoped to this campaign's entities and cases — shows the internal structure of the threat operation
- **SSI investigations:** Site scans linked to cases in this campaign
- **eCrimeX status:** Submission and hit summary for this campaign's indicators

**Management actions:**

- Rename, edit description
- Merge two campaigns (combine case memberships, retain both histories in metadata)
- Split campaign (move selected cases to a new campaign)
- Link/unlink individual cases
- Change status
- Generate Campaign Intelligence Report (PDF)

### 7.5 Campaign Risk Scoring

```
Campaign Risk Score = weighted_sum(
    case_count_normalized     × 0.15,   # More cases = broader impact
    loss_sum_normalized       × 0.30,   # Financial impact is the primary signal
    avg_case_risk_score       × 0.25,   # Severity of individual cases
    recency_factor            × 0.15,   # Recent activity scores higher
    indicator_diversity       × 0.15,   # More indicator types = more sophisticated
)
```

Where:

- `case_count_normalized` = min(case_count / 50, 1.0) — caps at 50 cases
- `loss_sum_normalized` = min(loss_sum / 1_000_000, 1.0) — caps at $1M
- `recency_factor` = 1.0 if last_case < 7d, 0.75 if < 30d, 0.5 if < 90d, 0.25 otherwise
- `indicator_diversity` = count(distinct entity_types) / 8

This is computed by the aggregation job and stored on the campaign record.

---

## 8. Analytics Data Architecture

This section specifies how raw data flows from ingestion to the pre-computed aggregations that power the analytics UI. Getting this right is the foundation that every feature depends on.

### 8.1 Aggregation Pipeline

```
Raw Tables                   Aggregation Job              Pre-Computed Tables
─────────────            ──────────────────────          ────────────────────
entities          ─┐
indicators        ─┤     entity_aggregation_job          entity_stats
cases             ─┤     (scheduled, e.g. every 15min)   indicator_stats
intake_records    ─┤     ───────────────────────→        campaign_stats
threat_campaigns  ─┤                                     platform_kpis
site_scans        ─┤
harvested_wallets ─┤
ecx_submissions   ─┘

UI queries hit pre-computed tables only (fast, bounded).
Drill-downs hit raw tables (ad-hoc, but scoped to single entity/case).
```

### 8.2 Pre-Computed Table Schemas

**`entity_stats`** — one row per unique (entity_type, canonical_value) across all cases:

| Column              | Type      | Notes                                                        |
| ------------------- | --------- | ------------------------------------------------------------ |
| entity_type         | TEXT      |                                                              |
| canonical_value     | TEXT      |                                                              |
| case_count          | INT       | COUNT(DISTINCT case_id)                                      |
| victim_count        | INT       | COUNT(DISTINCT intake_records linked to those cases)         |
| loss_sum            | NUMERIC   | SUM(linked intake losses)                                    |
| loss_currency       | TEXT      | "USD" (normalized)                                           |
| max_risk_score      | NUMERIC   | MAX(cases.risk_score)                                        |
| avg_risk_score      | NUMERIC   | AVG(cases.risk_score)                                        |
| first_seen_at       | TIMESTAMP | MIN(entities.first_seen_at)                                  |
| last_seen_at        | TIMESTAMP | MAX(entities.last_seen_at)                                   |
| status              | TEXT      | "active" / "dormant" / "flagged" — derived from last_seen_at |
| campaign_ids        | JSON      | Array of threat_campaign_ids this entity participates in     |
| top_classifications | JSON      | Top-3 classification labels by frequency                     |
| ecx_submitted       | BOOLEAN   | Any indicator for this entity submitted to eCX               |
| ecx_hit             | BOOLEAN   | Any eCX submission returned hits                             |
| updated_at          | TIMESTAMP | When this row was last recomputed                            |

**`indicator_stats`** — one row per unique (category, number):

| Column         | Type      | Notes                                     |
| -------------- | --------- | ----------------------------------------- |
| indicator_id   | UUID      | PK                                        |
| category       | TEXT      | bank / crypto / payments                  |
| item           | TEXT      | Institution name                          |
| type           | TEXT      | Sub-type (checking, cryptocurrency, etc.) |
| number         | TEXT      | The identifier itself                     |
| case_count     | INT       |                                           |
| loss_sum       | NUMERIC   |                                           |
| first_seen_at  | TIMESTAMP |                                           |
| last_seen_at   | TIMESTAMP |                                           |
| max_risk_score | NUMERIC   |                                           |
| ecx_status     | TEXT      | "submitted" / "hit" / "not_submitted"     |
| updated_at     | TIMESTAMP |                                           |

**`campaign_stats`** — one row per threat campaign:

| Column          | Type      | Notes                                   |
| --------------- | --------- | --------------------------------------- |
| campaign_id     | UUID      | FK                                      |
| case_count      | INT       |                                         |
| indicator_count | INT       | Distinct indicators across member cases |
| entity_types    | JSON      | {wallet: 34, domain: 12, ip: 8, ...}    |
| loss_sum        | NUMERIC   |                                         |
| victim_count    | INT       |                                         |
| risk_score      | NUMERIC   | Computed using formula from Section 7.5 |
| taxonomy_rollup | JSON      | Aggregated classification axes          |
| first_case_at   | TIMESTAMP |                                         |
| last_case_at    | TIMESTAMP |                                         |
| status          | TEXT      | Computed lifecycle state                |
| updated_at      | TIMESTAMP |                                         |

**`platform_kpis`** — per-period summary (one row per period_type + period_start):

| Column              | Type    | Notes                                           |
| ------------------- | ------- | ----------------------------------------------- |
| period_type         | TEXT    | "day" / "week" / "month" / "quarter"            |
| period_start        | DATE    |                                                 |
| total_cases         | INT     | Total cases detected_at within period           |
| proactive_cases     | INT     | source_type != "user-report"                    |
| reactive_cases      | INT     | source_type == "user-report"                    |
| total_loss          | NUMERIC |                                                 |
| new_indicators      | INT     | indicators.first_seen_at within period          |
| new_entities        | INT     | entities.first_seen_at within period            |
| site_scans          | INT     |                                                 |
| ecx_submissions     | INT     |                                                 |
| cases_actioned      | INT     | Cases with at least one review_action in period |
| median_action_hours | NUMERIC | Median case-to-first-action time                |

### 8.3 Graph Service

The graph computation is encapsulated behind an interface (see D3 in Section 5):

**Data flow:**

1. Frontend requests `GET /api/intelligence/graph?seed={entity_id}&hops=2`
2. Backend `GraphService` (NetworkX implementation) queries `entities` + `cases` to build an adjacency graph of entity co-occurrence
3. For graphs >500 nodes, backend pre-computes layout positions using `networkx.spring_layout`
4. Response is a JSON payload: `{ nodes: [...], edges: [...], layout: {...} }`
5. Frontend renders with D3.js force layout (or static layout if pre-computed)

**Graph edge construction rules:**

- Two entities share an edge if they co-occur in at least one case (edge weight = case count)
- Strength of connection = number of shared cases (drives edge thickness and layout proximity)
- Entity nodes carry pre-computed stats from `entity_stats` (case count, loss, risk — no additional DB queries per node)

### 8.4 BigQuery Migration Path

The aggregation job writes to PostgreSQL tables initially. If data volumes grow beyond PostgreSQL's comfortable OLAP range (rough threshold: >10M entity rows, >1M cases, or query latency >2s for dashboard loads), the migration path is:

1. Add a BigQuery dataset `i4g_analytics` with the same table schemas
2. Modify the aggregation job to dual-write (or replace with a dbt pipeline)
3. Point dashboard API queries to BigQuery via the BigQuery Python client
4. PostgreSQL retains raw tables and drill-down queries (OLTP workload)
5. BigQuery serves aggregate dashboard queries (OLAP workload)

This is a clean separation because the aggregation tables have well-defined schemas that are query-consumer-agnostic. The UI API layer doesn't know or care whether the underlying storage is PostgreSQL or BigQuery — it speaks SQL or API either way.

---

## 9. User Journeys

### Journey A: Fraud Analyst — "Is this indicator known?"

**User:** Marcus, Fraud Analyst
**Trigger:** A new case just came in containing a phone number. Marcus wants to know if this number has appeared before.

```
1. Marcus uses Global Search (Cmd+K), pastes the phone number
   → Result: 1 entity match: type=phone, case_count=6, first_seen=8 months ago,
     risk=81, loss=$34,000

2. Clicks the entity → Entity Detail panel loads
   → 6 cases spanning 8 months. Classification breakdown: 5× PERSONA.GOVERNMENT
     (IRS impersonation), 1× PERSONA.TECH.
   → Timeline sparkline: dormant for 3 months, new activity in last 2 weeks.
     Re-emerging pattern.

3. Clicks "Related Cases" → opens the oldest case to read the narrative.
   Confirms pattern: IRS impersonation with gift card payment.

4. Returns to entity detail → clicks the mini network graph.
   → This phone number co-occurs with 2 email addresses and 1 bank account
     across its 6 cases. One email appears in 4 additional cases that Marcus
     hasn't seen.

5. Promotes new case to "Critical" priority and assigns to himself.

6. Clicks "Export Indicator Summary" → short PDF for supervisor briefing.

7. Notes the entity is not in eCrimeX → clicks "Submit to eCrimeX."
```

**Time from initial search to informed decision: ~3 minutes.**
**Currently possible? No.** Marcus can search for the phone number in cases, but there is no entity-level aggregate view, no case count, no loss sum, no timeline, and no network graph.

### Journey B: Intelligence Analyst — Campaign Attribution

**User:** Maya, Intelligence Analyst
**Trigger:** The Intelligence Dashboard shows a "Top Emerging Campaigns" widget flagging a cluster: "Emerging — 12 new cases this week, INTENT.INVESTMENT"

```
1. Maya clicks the campaign cluster → Campaign Detail loads
   → 12 cases, auto-detected via "auto:wallet_cluster" origin
   → 8 new wallet addresses, 3 domains, 2 IPs
   → Risk Score: 74    Loss: $210,000 so far

2. She opens the Network Graph scoped to this campaign
   → All 3 domains resolve to the same 2 IPs
   → One IP is also linked to a domain from an older, dormant campaign
   → She pins the shared IP and expands 2-hop neighbors

3. The expansion reveals 4 additional domains not in the current campaign
   → 2 have recent SSI site scans — actively collecting victim PII (SSN fields detected)
   → The PII exposure data from pii_exposures confirms these are pig butchering intake forms

4. She links the 4 new domains' cases to this campaign using the Campaign
   Management actions (link cases)

5. She renames the campaign: "Pig Butchering Wave — Jan 2026"
   → Writes description: "Investment scam cluster centered on 2 IPs in
      Southeast Asia. Active PII collection on 4 domains. 16 cases, $210K loss."

6. The platform surfaces a prompt: "This campaign has >$50K loss, >5 cases,
   and eCrimeX hits. Consider compiling a law enforcement dossier."

7. Maya reviews the synopsis, decides it's not yet strong enough for LEA
   referral — but flags the campaign for weekly monitoring.

8. She clicks "Generate Campaign Intelligence Report" → selects TLP:AMBER
   → PDF renders: campaign summary, network graph, indicator table, timeline.
   → She sends the PDF to the eCrimeX partner mailing list.
```

### Journey C: Executive — Quarterly Impact Briefing

**User:** Sarah, CEO
**Trigger:** Board meeting in 2 days; needs quarterly fraud detection impact metrics

```
1. Navigates to Impact Dashboard → selects period: Q1 2026

2. KPI cards show:
   → 3,847 cases detected (+40% QoQ)
   → $28.4M estimated victim loss exposure (+22% QoQ)
   → 287 active threat actors
   → 412 sites investigated

3. Loss by Fraud Taxonomy treemap:
   → Investment scams = 62% of loss ($17.6M)
   → She hovers to read the detail

4. Geographic Heatmap:
   → Southeast Asia is the primary hosting hotspot
   → US, Canada, UK are primary victim locations

5. Clicks "Generate Executive Report" → Quarterly Impact Summary template
   → 2-page branded PDF: KPI snapshot, loss treemap, detection velocity,
     geographic thumbnail, brief narrative
   → Also available: data appendix XLSX for investor data room

Total time: ~10 minutes for a board-ready impact summary.
```

### Journey D: Analyst-Prompted LEA Referral

**User:** The system surfaces a prompt to Analyst Marcus
**Trigger:** An entity (wallet 0xABC...123) has crossed the LEA referral suggestion threshold

```
1. Marcus sees a notification in his Intelligence Dashboard:
   "Potential LEA case: wallet 0xABC...123 — 31 cases, $1.2M cumulative loss,
    3 eCrimeX external corroborations"

2. Clicks the prompt → Synopsis page shows:
   → Entity stats, case list (abbreviated), loss breakdown
   → Evidence availability: 8 SSI investigation screenshots, 4 site scan
     evidence bundles with chain-of-custody manifests
   → eCrimeX status: Hit — 3 external agencies have also flagged this address

3. Marcus decides this is strong enough for referral. Clicks "Compile LEA Dossier."

4. The existing dossier pipeline (BundleBuilder + dossier tools) kicks in:
   → Selects relevant cases by the entity linkage
   → GeoReasonerTool analyzes jurisdictions
   → TimelineSynthesizerTool builds event timeline
   → EntityGraphTool computes the network
   → ChartRendererTool renders the visuals
   → NarrativeWriterTool drafts the summary
   → PDF generated with TLP:RED watermark, SHA-256 chain of custody

5. Marcus downloads the package and forwards to the FBI Cyber Division contact.
```

**Key design principle:** The platform surfaces the opportunity; the analyst makes the judgment call. This respects the legal and procedural complexity while ensuring strong cases don't go unnoticed.

---

## 10. Feature Catalogue

Features tagged by priority (P0 = prerequisite, P1 = launch, P2 = fast-follow, P3 = future), and whether they extend breadth (B) or depth (D).

### 10.1 Data Foundation (P0 — Must ship before any analytics feature)

| #     | Feature                   | B/D | Description                                                                                                                                                                                  |
| ----- | ------------------------- | --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| F-00a | Loss-to-indicator linkage | D   | Add `intake_indicator_links` join table + LLM extraction pass over intake narratives to link loss amounts to specific indicators. This is the prerequisite for "cumulative loss per entity." |
| F-00b | Entity aggregation job    | D   | Scheduled job that computes `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis` tables. Runs every 15 minutes or on ingestion completion event.                             |
| F-00c | Threat campaign model     | D   | New `threat_campaigns` + `threat_campaign_cases` tables. Migrate existing `CampaignCorrelator` output to write here. Disambiguate from ingestion batches.                                    |

### 10.2 Core Intelligence (P1 — Launch)

| #    | Feature                            | B/D | Description                                                                                                |
| ---- | ---------------------------------- | --- | ---------------------------------------------------------------------------------------------------------- |
| F-01 | Entity Explorer list view          | B   | Sortable/filterable entity table at `/intelligence/entities` powered by `entity_stats`                     |
| F-02 | Entity Detail panel                | D   | Stats card, sparkline, related cases, mini network graph, eCX status, actions                              |
| F-03 | Indicator Registry                 | B   | Replaces `/accounts` — always-on indicator list at `/intelligence/indicators` powered by `indicator_stats` |
| F-04 | Indicator Detail page              | D   | Per-indicator stats, case linkage, source documents                                                        |
| F-05 | Global Search enhancement          | B   | Cross-entity, cross-indicator, cross-case search with type facets in Cmd+K                                 |
| F-06 | Intelligence Dashboard widgetboard | B   | Configurable widgets: active threats, new indicators, emerging campaigns, loss trend, source breakdown     |

### 10.3 Impact Analytics (P1 — Launch)

| #    | Feature                  | B/D | Description                                                                |
| ---- | ------------------------ | --- | -------------------------------------------------------------------------- |
| F-07 | Impact Dashboard         | B   | KPI cards + charts, replaces current `/analytics` page. Period comparison. |
| F-08 | Loss by Taxonomy treemap | B   | Interactive treemap: area = loss sum per classification label              |
| F-09 | Detection Velocity chart | B   | Cases/week line chart: proactive vs. reactive split                        |
| F-10 | Pipeline funnel          | B   | Intake → ingestion → classification → review → action flow visualization   |

### 10.4 Campaign Intelligence (P1 — Launch)

| #    | Feature                     | B/D | Description                                                                   |
| ---- | --------------------------- | --- | ----------------------------------------------------------------------------- |
| F-11 | Campaign list + cards       | B   | Campaign dashboard at `/intelligence/campaigns` with cards, filters, sort     |
| F-12 | Campaign detail page        | D   | Metrics, timeline, entity list, taxonomy rollup, SSI links, eCX status        |
| F-13 | Campaign management actions | D   | Rename, merge, split, link/unlink cases, change status, annotate              |
| F-14 | Campaign auto-detection     | D   | Extend existing `CampaignCorrelator` to write to new `threat_campaigns` model |

### 10.5 Reports & Exports (P1 — Launch)

| #    | Feature                        | B/D | Description                                                                           |
| ---- | ------------------------------ | --- | ------------------------------------------------------------------------------------- |
| F-15 | Executive Summary PDF template | B   | Quarterly impact report — extends existing dossier pipeline                           |
| F-16 | LEA Dossier template           | D   | Chain-of-custody PDF — extends existing dossier pipeline, triggered by analyst prompt |
| F-17 | LEA referral suggestion engine | D   | Surfaces prompts when entity/campaign meets threshold criteria                        |
| F-18 | XLSX/CSV bulk export           | B   | Export from any list view                                                             |
| F-19 | TLP labeling on all exports    | B   | Traffic Light Protocol applied to every generated document                            |
| F-20 | Role-based view restrictions   | B   | Research role = anonymized aggregates only. LEO = full detail. Analyst = full.        |
| F-21 | Indicator masking              | B   | Bank account numbers show last 4 in list views; reveal on explicit click              |
| F-22 | Export audit log               | B   | Every export action logged with user, timestamp, scope                                |

### 10.6 Network & Graph (P2 — Fast Follow)

| #    | Feature                         | B/D | Description                                                        |
| ---- | ------------------------------- | --- | ------------------------------------------------------------------ |
| F-23 | Network Graph page              | D   | Force-directed graph at `/intelligence/graph` with D3.js rendering |
| F-24 | Graph seed + expansion controls | D   | Seed from entity/case/campaign, expand 1-hop/2-hop                 |
| F-25 | Graph edge filtering            | D   | Toggle co-occurrence / shared IP / same campaign edges             |
| F-26 | Graph PDF export                | D   | Render visible subgraph to PNG/PDF for dossier inclusion           |

### 10.7 Taxonomy & Geography (P2 — Fast Follow)

| #    | Feature                 | B/D | Description                                         |
| ---- | ----------------------- | --- | --------------------------------------------------- |
| F-27 | Taxonomy Sankey diagram | B   | Intent → Channel → Action flow visualization        |
| F-28 | Taxonomy Heatmap grid   | B   | Any two axes as X/Y, cell = case count or loss      |
| F-29 | Taxonomy Trend view     | D   | Time-series of one taxonomy value's share over time |
| F-30 | Geographic Heatmap      | B   | World map with scam origin + victim location layers |
| F-31 | Country drill-down      | D   | Per-country case list and loss stats from map click |

### 10.8 Workflow & Operations (P2 — Fast Follow)

| #    | Feature                            | B/D | Description                                       |
| ---- | ---------------------------------- | --- | ------------------------------------------------- |
| F-32 | Entity status labels               | B   | Active/Dormant/Flagged/Taken Down on entities     |
| F-33 | Analyst annotations                | D   | Freeform notes on entities, indicators, campaigns |
| F-34 | eCrimeX submission UI              | D   | Submit selected indicators from any list view     |
| F-35 | Bulk entity actions                | B   | Multi-select → export / eCX submit / tag          |
| F-36 | Timeline view                      | B   | Multi-track temporal visualization (Section 6.6)  |
| F-37 | Intelligence Bulletin PDF template | B   | Campaign-focused partner report                   |
| F-38 | SAR supplement export              | B   | FinCEN-compatible structured indicator list       |
| F-39 | STIX 2.1 export                    | B   | Machine-readable threat intelligence format       |
| F-40 | Report Library                     | B   | History of generated reports with download links  |

### 10.9 Advanced & Future (P3)

| #    | Feature                              | B/D | Description                                                    |
| ---- | ------------------------------------ | --- | -------------------------------------------------------------- |
| F-41 | Temporal graph animation             | D   | Date slider that animates graph growth over time               |
| F-42 | Graph clustering (Louvain)           | D   | Auto-detect dense subgraphs                                    |
| F-43 | Watchlist + alerts                   | D   | Pin entities; alert on new case activity                       |
| F-44 | Shared infrastructure clustering job | D   | Scheduled job linking entities by shared IP / registrar        |
| F-45 | Passive DNS enrichment               | D   | SecurityTrails / Farsight integration for historical DNS       |
| F-46 | Blockchain analytics integration     | D   | Chainalysis / TRM Labs wallet labels and transaction data      |
| F-47 | Scheduled reports                    | B   | Weekly/monthly report auto-generation + email delivery         |
| F-48 | Embeddable charts                    | B   | Shareable chart URLs with read-only, time-limited tokens       |
| F-49 | Victim analytics                     | B   | Aggregate victim demographics (pending intake field additions) |
| F-50 | Researcher data portal               | B   | Anonymized aggregate dataset exports                           |
| F-51 | LEA referral tracking                | D   | Log referral date, agency, case number per case                |
| F-52 | Partner indicator feed API           | B   | Machine-readable, TLP-tagged indicator feed                    |

---

## 11. Hardcopy & Export System

### 11.1 Building on the Existing Dossier Pipeline

The codebase already has a mature report generation infrastructure in `core/src/i4g/reports/` — 15+ modules including:

- `bundle_builder.py` — case filtering, grouping, plan creation
- `dossier_tools.py` — LangChain tool suite (geo analysis, timeline, entity graph, chart rendering, narrative)
- `dossier_templates.py` + `template_engine.py` — template rendering
- `dossier_exports.py` — PDF/document export
- `dossier_signatures.py` — chain-of-custody hashing
- `dossier_visuals.py` — chart/map generation
- `gdoc_exporter.py` — Google Docs export

The analytics platform does NOT build a new report pipeline. It extends the existing one with new templates and new data sources (the pre-computed stats tables).

### 11.2 New Report Templates

**Template 1: Executive Impact Summary**

- Source: `platform_kpis` + `campaign_stats`
- Contents: KPI snapshot, detection velocity, loss treemap, geographic thumbnail, narrative
- Length: 1–2 pages
- Branding: i4g logo, confidentiality footer
- Generator: existing `template_engine.py` + `dossier_visuals.py` for charts

**Template 2: Campaign Intelligence Bulletin**

- Source: `campaign_stats` + `entity_stats` (filtered to campaign)
- Contents: Campaign summary, indicator list, taxonomy rollup, timeline, network graph render, source attribution
- Length: 3–8 pages
- TLP: AMBER or WHITE (analyst selects)
- Generator: extends existing `dossier_tools.py` (EntityGraphTool + TimelineSynthesizerTool + NarrativeWriterTool)

**Template 3: LEA Evidence Dossier**

- Source: entity/campaign selection → related cases → intake records → site_scan evidence
- Contents: cover sheet, indicator declarations, evidence exhibits (timestamped screenshots from SSI), case history, chain-of-custody manifest (SHA-256), certification statement
- Length: 10–50 pages
- TLP: RED
- Generator: extends existing `bundle_builder.py` (DossierCandidate + BundleCriteria) + `dossier_signatures.py` for chain-of-custody

**Template 4: SAR Supplement**

- Source: `indicator_stats` filtered by date range and category
- Contents: FinCEN-structured indicator list (account name, number, type, institution, activity dates, suspicion narrative)
- Format: PDF + companion XLSX
- Generator: new template in `template_engine.py`; data from `indicator_stats` + `entity_stats`

### 11.3 Report Builder UI

**URL:** `/reports/new`

Step 1: Select template (Executive Summary / Intelligence Bulletin / LEA Dossier / SAR Supplement)

Step 2: Select scope

- For Executive Summary: date range (pre-filled with last quarter)
- For Intelligence Bulletin: campaign picker
- For LEA Dossier: entity or campaign — system auto-selects related cases
- For SAR Supplement: date range + category filter

Step 3: Options — TLP level, include sections (toggle: network graph, timeline, screenshots, chain of custody), custom header note

Step 4: Preview (watermarked) → Generate → download link + optional email delivery

### 11.4 Export Formats Available Across the Platform

| Format            | Where Available                                    | Notes                                |
| ----------------- | -------------------------------------------------- | ------------------------------------ |
| **PDF**           | Report Builder, Entity Detail, Campaign Detail     | Template-driven, branded             |
| **XLSX**          | Indicator Registry, Entity Explorer, any list view | Flat tabular export                  |
| **CSV**           | Same as XLSX                                       | Plain text variant                   |
| **STIX 2.1 JSON** | Indicator Registry bulk export                     | Machine-readable threat intel format |
| **PNG / SVG**     | Network Graph, any chart                           | Visual capture                       |

All exports carry TLP labels and are logged to the audit trail.

---

## 12. Data Gaps & Collection Plan

Organized by priority and complexity. Each gap includes what needs to change and where.

### 12.1 P0 — Must Complete Before Analytics Launch

| Gap                                | Change Required                                                                                                                                                         | Complexity                          |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **Loss-to-indicator linkage**      | New `intake_indicator_links` table (intake_id, indicator_id, confidence, linked_by). LLM extraction pass over existing intake narratives. New FK option on intake form. | Medium — schema + batch job + UI    |
| **`loss_currency` on intake**      | Add TEXT column, default "USD". Add currency picker to intake form.                                                                                                     | Low — schema migration + form field |
| **Threat campaign model**          | New `threat_campaigns` + `threat_campaign_cases` tables. Migrate `CampaignCorrelator` output.                                                                           | Medium — schema + SSI code change   |
| **Aggregation job infrastructure** | New worker job computing `entity_stats`, `indicator_stats`, `campaign_stats`, `platform_kpis`.                                                                          | Medium — new job, well-defined SQL  |

### 12.2 P1 — Complete During Phase 1 Development

| Gap                                    | Change Required                                                                                         | Complexity                        |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------- |
| **`victim_country` on intake**         | Add TEXT column + country picker on intake form                                                         | Low                               |
| **`victim_age_range` on intake**       | Add TEXT column + optional age-range selector                                                           | Low                               |
| **`contact_channel` structured field** | Split existing `contact_handle` into `contact_channel` (email/phone/social/chat) + `contact_identifier` | Low                               |
| **Campaign taxonomy_rollup**           | Computed by aggregation job from member cases' `classification_result`                                  | Low — included in aggregation job |
| **`taken_down_at` on site_scans**      | Add TIMESTAMP column; SSI re-scan job to confirm takedown                                               | Low — schema + scheduled check    |

### 12.3 P2 — Complete During Phase 2

| Gap                                  | Change Required                                                                 | Complexity |
| ------------------------------------ | ------------------------------------------------------------------------------- | ---------- |
| **LEA referral tracking**            | Add `lea_referred_at`, `lea_agency`, `lea_case_number` columns on `cases`       | Low        |
| **Partner action tracking**          | New `partner_actions` table linked to indicators                                | Low        |
| **Shared infrastructure clustering** | Scheduled job that queries entity co-occurrence and writes infrastructure edges | High       |
| **Passive DNS integration**          | SecurityTrails or Farsight API integration                                      | Medium     |
| **ASN enrichment**                   | RIPE/ARIN RDAP API queries                                                      | Low        |

### 12.4 P3 — Future

| Gap                                           | Change Required                                           | Complexity               |
| --------------------------------------------- | --------------------------------------------------------- | ------------------------ |
| **Blockchain analytics**                      | Chainalysis or TRM Labs vendor contract + API integration | High (vendor dependency) |
| **Wallet cluster IDs**                        | Depends on blockchain analytics vendor                    | High                     |
| **Discovery channel** (how victim found scam) | Intake form field                                         | Low                      |
| **Victim financial institution**              | Intake form field                                         | Low                      |

---

## 13. Phased Delivery

### Phase 0 — Data Foundation (Weeks 1–4)

Goal: Build the pre-computed aggregation layer and campaign model. No UI changes yet — purely backend.

**Deliverables:**

- F-00a: `intake_indicator_links` table + LLM batch extraction to link existing intake losses to indicators
- F-00b: Entity aggregation scheduled job → `entity_stats`, `indicator_stats`, `platform_kpis`
- F-00c: `threat_campaigns` + `threat_campaign_cases` tables; migrate `CampaignCorrelator` output
- Schema migrations: `loss_currency`, `victim_country`
- F-00b verification: aggregation job runs successfully on dev data, stats are accurate

**Exit criteria:** Dashboard API can serve pre-computed entity stats, indicator stats, and platform KPIs from the new tables. Loss-per-entity numbers are populated for entities linked to intake records.

### Phase 1 — Core Analytics UI (Weeks 5–12)

Goal: Ship the Entity Explorer, Indicator Registry, Campaign Dashboard, Impact Dashboard, and basic PDF reports. Replace `/accounts` page.

**Deliverables:**

- F-01/02: Entity Explorer + Detail — new pages at `/intelligence/entities`
- F-03/04: Indicator Registry + Detail — replaces `/accounts` at `/intelligence/indicators`
- F-05: Global Search enhancement with entity/indicator facets
- F-06: Intelligence Dashboard widgetboard at `/intelligence`
- F-07/08/09/10: Impact Dashboard with KPIs, treemap, velocity chart, pipeline funnel — replaces `/analytics`
- F-11/12/13/14: Campaign Dashboard with list, detail, management, auto-detection integration
- F-15/16: Executive Summary + LEA Dossier report templates (extending existing dossier pipeline)
- F-17: LEA referral suggestion engine
- F-18/19/20/21/22: Exports, TLP, role restrictions, masking, audit log
- Navigation restructure per Section 6.1

**Exit criteria:** An analyst can search for an entity, see its case count and cumulative loss, drill into related cases, explore the campaign it belongs to, and export a PDF summary. An executive can see quarterly impact KPIs and generate a summary PDF.

### Phase 2 — Depth & Breadth (Weeks 13–20)

Goal: Ship the Network Graph, Taxonomy Explorer, Geographic Heatmap, Timeline, and workflow tools.

**Deliverables:**

- F-23/24/25/26: Network Graph with seed/expand/filter/export
- F-27/28/29: Taxonomy Sankey, Heatmap, Trend
- F-30/31: Geographic Heatmap + Country drill-down
- F-32/33/34/35: Entity status labels, annotations, eCX submission UI, bulk actions
- F-36: Timeline view
- F-37/38/39/40: Intelligence Bulletin template, SAR export, STIX 2.1, Report Library
- Schema: LEA referral fields, `taken_down_at`

**Exit criteria:** An intelligence analyst can construct a network graph from a campaign, explore shared infrastructure, and generate a Campaign Intelligence Bulletin PDF for partner distribution.

### Phase 3 — Automation & Integration (Weeks 21–30)

Goal: Advanced graph features, external data enrichment, automated workflows.

**Deliverables:**

- F-41/42: Temporal graph animation, Louvain clustering
- F-43: Watchlist + alerts
- F-44/45: Shared infrastructure clustering job, passive DNS
- F-47/48: Scheduled reports, embeddable charts
- F-49: Victim analytics (using demographic fields added in Phase 0)
- F-50: Researcher data portal (anonymized exports)

### Phase 4 — External Ecosystem (Weeks 30+)

**Deliverables:**

- F-46: Blockchain analytics vendor integration
- F-51: LEA referral tracking workflow
- F-52: Partner indicator feed API
- Mobile summary views (read-only dashboards)

---

## 14. Success Metrics

### Platform Adoption

| Metric                                                | Target (6 months post-launch)      |
| ----------------------------------------------------- | ---------------------------------- |
| Entity Explorer weekly active users                   | >80% of analyst seats              |
| Search queries involving entity/indicator type facets | >50/week                           |
| Reports generated per month                           | >30                                |
| LEA dossiers generated per quarter                    | >5                                 |
| Time from entity lookup to escalation decision        | <5 min (currently: not measurable) |

### Data Quality

| Metric                                                    | Target                          |
| --------------------------------------------------------- | ------------------------------- |
| Intake records with loss_amount populated                 | >70%                            |
| Intake records with loss linked to at least one indicator | >50%                            |
| Cases with at least one extracted indicator               | >80%                            |
| Threat campaigns with ≥2 cases                            | >60% of auto-detected campaigns |
| Entity dedup rate (canonical_value consolidation)         | >95%                            |

### Intelligence Impact

| Metric                                                    | Notes                                                                           |
| --------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Confirmed site takedowns per quarter                      | Requires `taken_down_at` tracking                                               |
| eCrimeX submission rate (% new indicators submitted <24h) | Target: >90%                                                                    |
| LEA referral suggestions surfaced → actually compiled     | Track conversion rate                                                           |
| Campaign detection lead time vs. manual discovery         | Compare auto-detected campaign creation_date to when analyst would have noticed |

### Business Impact

| Metric                                          | Notes                          |
| ----------------------------------------------- | ------------------------------ |
| Executive reports generated per quarter         | Track via Report Library       |
| Partner organizations consuming indicator feeds | Track via API access logs      |
| Investor presentations using platform data      | Qualitative — quarterly survey |

---

## Appendix A: Design Decision Log

All design questions from v0.1 and v0.2 have been resolved. Decisions D1–D5 were resolved during the v0.1→v0.2 revision. Decisions D6–D16 were resolved during the v1.0 consolidation.

### Foundational Decisions (D1–D5)

| #   | Question                                                         | Decision                                                                | Rationale                                                                                                                   |
| --- | ---------------------------------------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| D1  | Campaign: auto-generated, manual, or both?                       | Both. Auto-detect + manual management UI.                               | Distributed intake review means no single analyst sees emerging patterns. Auto-clustering catches them; analysts refine.    |
| D2  | Entity aggregation: materialized views or scheduled job?         | Scheduled job writing to denormalized tables.                           | Simpler to debug than materialized views; triggers too complex. BigQuery migration path preserved by clean schema boundary. |
| D3  | Graph infrastructure: in-memory, Neo4j, or PostgreSQL adjacency? | In-memory (NetworkX) behind an abstraction interface. Neo4j swap later. | Existing `EntityGraphTool` already uses this pattern. Low data volume means no near-term scaling pressure.                  |
| D4  | LEA dossier: automated or analyst-triggered?                     | Analyst-prompted. Platform suggests; analyst decides.                   | Legal/procedural requirements vary by jurisdiction. Not ready to automate.                                                  |
| D5  | Loss-indicator linkage priority?                                 | Critical. P0 prerequisite.                                              | "Cumulative loss per entity" is the most compelling metric for every audience.                                              |

### Product Decisions (D6–D8)

**D6: Campaign Naming Convention — LLM-Generated Semantic Names**

**Decision:** Auto-generate semantic campaign names using LLM summarization of campaign characteristics, with analyst override.

**Rationale:** Correlator-generated names like "Shared Wallet: 0xABC..." are technically accurate but opaque to non-technical stakeholders and unusable in partner communications. An LLM can derive a human-readable label from the campaign's fraud type, geography, infrastructure pattern, and timeline — e.g., "Southeast Asia Investment Scam Cluster — Jan 2026." This makes campaigns immediately interpretable in the Campaign Dashboard, executive reports, and partner bulletins.

**Implementation:** On campaign auto-creation, the naming job summarizes the cluster's `classification_result` labels, GeoIP data from linked site scans, and primary indicator types into a short descriptive name (≤60 chars). The generated name is stored with `origin: "auto:llm_summary"`. Analysts can rename at any time via the Campaign Management UI. The original correlator label (e.g., `"Shared Wallet: 0xABC..."`) is preserved in the campaign's `metadata.original_label` field for traceability.

**Phase:** Phase 1. Depends on the threat campaign model (F-00c).

---

**D7: Entity Explorer and Indicator Registry — Permanently Separate Views**

**Decision:** Keep Entity Explorer and Indicator Registry as distinct views. They are different lenses on overlapping data, not separate data stores.

**Rationale:** These serve fundamentally different workflows and personas:

- **Entity Explorer** (`/intelligence/entities`) — All entity types (wallet, IP, email, phone, domain, URL, bank_account, person). Optimized for intelligence analysts doing cross-type exploration, graph expansion, and ad-hoc investigation. This is the low-level, discovery-oriented view where analysts explore freely — many queries will not yield concrete intelligence, but the ability to explore is essential for pattern discovery.
- **Indicator Registry** (`/intelligence/indicators`) — Financial indicators specifically (bank/crypto/payments). Optimized for compliance officers needing SAR-format exports, partner feeds needing STIX 2.1, and fraud analysts looking up a specific account number. This is the structured, compliance-oriented view with institution filtering and category segmentation.

Both views drill into the same underlying entity detail panel. Merging them would compromise both experiences: analysts would wade through compliance filters, and compliance officers would be overwhelmed by non-financial entity types. The shared detail panel and shared `entity_stats`/`indicator_stats` tables ensure there is no data duplication.

---

**D8: Ingestion Batch Relabeling — Add `ingestion_batch_id` Column**

**Decision:** Add a new `ingestion_batch_id` column to `cases` and migrate existing `cases.campaign_id` values that represent batch provenance (not threat campaigns) to the new column.

**Rationale:** A UI alias ("Source Batch") is insufficient because the underlying data model needs to be structurally correct. An alias masks a semantic ambiguity that compounds as the system grows — queries, aggregation jobs, and reports would need to constantly distinguish between "campaign_id values that mean batches" and "campaign_id values that mean threat campaigns." This is fragile and error-prone. A clean migration now (during Phase 0, alongside the threat_campaigns model work) prevents years of workarounds.

**Migration plan:** During Phase 0, a one-time migration script identifies which `cases.campaign_id` values represent ingestion batches (e.g., student competition cohorts, bulk CSV imports) vs. correlator-detected threat clusters. Batch-provenance values are moved to `ingestion_batch_id`. The existing `cases.campaign_id` is retained for backward compatibility but deprecated — new threat campaign linkage goes through the M:N `threat_campaign_cases` join table.

### Legal / Compliance Decisions (D9–D11)

**D9: PII Retention in Analytics — Soft Anonymization Model**

**Decision:** When cases are purged (`purged_at` set), retain anonymized aggregate data in `entity_stats` but strip retrievable PII.

**Rationale:** The guiding principle is "design so we won't regret it" — deleting aggregate intelligence is irreversible and destroys trend analysis. But retaining raw PII after a purge violates the spirit of data protection.

**Implementation:**

1. When the aggregation job detects that all cases linked to an entity have `purged_at` set, it replaces `canonical_value` with a deterministic hash (SHA-256 of the original value, salted with a system secret).
2. The entity_stats row is flagged with `purge_status = "anonymized"` and retains aggregate counts: `case_count`, `loss_sum`, `victim_count`, `max_risk_score`, `first_seen_at`, `last_seen_at`.
3. Dashboard queries include anonymized aggregates in totals (e.g., total platform loss includes purged-entity loss) but exclude anonymized entities from drill-down lists and exports.
4. The deterministic hash preserves cross-entity correlation — if the same PII value appears in a future unpurged case, the system can detect the match without storing the raw value.
5. If legal later requires full deletion, a second pass can zero out anonymized rows. If legal confirms aggregates are acceptable, no further action is needed.

---

**D10: TLP Defaults Per Template — Adopted with Override Controls**

**Decision:** Accept the proposed TLP defaults. Override permissions are role-restricted.

| Template                       | Default TLP | Rationale                          |
| ------------------------------ | ----------- | ---------------------------------- |
| Executive Impact Summary       | TLP:AMBER   | Internal + trusted partners only   |
| Campaign Intelligence Bulletin | TLP:AMBER   | Partner distribution               |
| LEA Evidence Dossier           | TLP:RED     | Restricted to named LEA recipients |
| SAR Supplement                 | TLP:AMBER   | Regulatory compliance, internal    |

**Override rules:**

- `analyst` and `admin` roles can raise TLP (make more restrictive) at any time.
- Only `admin` can lower TLP (e.g., RED → AMBER). Lowering requires a confirmation dialog: "Lowering TLP expands the permitted audience. Proceed?"
- TLP:WHITE (public/unrestricted) is available only via explicit `admin` override with a mandatory reason field.
- TLP level is recorded in the export audit log alongside user and timestamp.

---

**D11: Chain of Custody for Analytics-Derived Data — Two-Tier Model**

**Decision:** Apply different chain-of-custody rigor based on report type and audience.

| Report Type                                               | Chain-of-Custody Approach                                                                                                                                                                                                                      |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LEA Dossier** (TLP:RED)                                 | Full per-record hashing. Hash each individual intake record, case record, and evidence artifact referenced in the report. This is for court-admissible evidence packages where every source must be individually traceable.                    |
| **Executive Summary / Intelligence Bulletin** (TLP:AMBER) | Aggregation-level hashing. Hash the aggregation job output that produced the figures, plus the job `run_id` and timestamp. Include a citation: "Figures derived from [N] intake records processed by aggregation job [run_id] at [timestamp]." |
| **SAR Supplement**                                        | Indicator-level hashing. Each indicator row in the export is individually hashed with its source case references.                                                                                                                              |

**Rationale:** Full per-record hashing is essential for LEA evidence but creates unnecessary overhead for executive reports. The two-tier model provides legal defensibility where it matters (law enforcement) while keeping executive reporting lightweight. All reports include a generation timestamp and the generating user's identity regardless of tier.

### Engineering Decisions (D12–D14)

**D12: Aggregation Job Frequency — Configurable with Real-Time Drill-Down Fallback**

**Decision:** 15-minute default refresh with real-time bypass for entity detail lookups.

**Implementation:**

1. **Dashboard aggregates (Impact Dashboard, Campaign Dashboard KPIs):** Read from pre-computed stats tables. Refreshed every 15 minutes by the scheduled job. Executives and analysts viewing aggregate dashboards see data that is at most 15 minutes stale — acceptable for both audiences.
2. **Entity detail drill-downs (single entity lookups from Entity Explorer or Global Search):** Bypass `entity_stats` and query raw tables directly. When an analyst looks up a specific entity, they get real-time case count, loss, and risk — not a cached snapshot. The performance cost of a single-entity raw query is negligible.
3. **On-demand refresh:** In addition to the scheduled interval, the aggregation job triggers automatically at the end of each ingestion batch (after new cases are ingested, stats refresh immediately). A CLI command `i4g jobs analytics refresh` provides manual triggering.
4. **Configurable interval:** The refresh frequency is set via `I4G_ANALYTICS__REFRESH_INTERVAL_MINUTES` env var (default: 15). Production deployments can increase this to 60 or even 1440 (daily) if query load warrants it.

---

**D13: D3.js Graph Performance Threshold — 500 Nodes**

**Decision:** Set the client-side/server-side layout threshold at 500 nodes.

- **Below 500 nodes:** Frontend performs live D3.js force-directed layout. Interactive: drag nodes, expand neighbors, filter edges.
- **Above 500 nodes:** Backend pre-computes layout coordinates using NetworkX `spring_layout` and sends positioned nodes. Frontend renders but does not re-layout. Interaction is limited to pan/zoom and click-to-expand (which requests a new layout from the backend).

The 500-node threshold is configurable via settings. Browser performance testing on target analyst devices should occur during Phase 2 QA, and the threshold can be adjusted based on real-world results. Initial value is conservative — it is better to serve a pre-computed layout that loads instantly than to freeze an analyst's browser.

---

**D14: Report Rendering Stack — Extended Python Pipeline with Chart Rendering**

**Decision:** Extend the existing Python-based dossier pipeline. Add server-side chart rendering via `matplotlib`/`plotly`. No hybrid Next.js rendering pipeline.

**Implementation:**

1. **Primary renderer:** Jinja2 templates + WeasyPrint (existing pipeline). All report templates (Executive Summary, Intelligence Bulletin, LEA Dossier, SAR Supplement) use this stack.
2. **Chart rendering:** Add `matplotlib` and/or `plotly` server-side chart generation to `dossier_visuals.py`. Charts render as SVG/PNG and embed directly in Jinja2 templates. This keeps the entire pipeline in Python without introducing a Node.js rendering dependency.
3. **Fallback for complex layouts:** If WeasyPrint struggles with specific layouts (e.g., complex multi-chart dashboards), use `playwright`-based PDF rendering as a fallback — render the HTML template in a headless browser and print to PDF. Playwright is already in our dependency tree for SSI screenshots.
4. **Browser charts vs. report charts:** Interactive dashboard charts (D3.js in the Next.js frontend) are separate from report charts (static matplotlib/plotly renders of the same data). They share the same data API but render independently.

**Rationale:** A hybrid Python/Next.js rendering pipeline doubles the maintenance surface and creates deployment complexity. The Python pipeline already handles text-heavy dossiers with chain-of-custody manifests. Adding chart capability within the same pipeline keeps the rendering stack unified and testable.

### Partnership Decisions (D15–D16)

**D15: eCrimeX Export Format Strategy — Extensible Adapter Pattern**

**Decision:** Maintain current eCrimeX submission format for the initial release. Design the export system with a pluggable adapter pattern for future format requirements.

**Implementation:**

1. **Initial release:** Keep the existing eCrimeX integration as-is (already working). Add STIX 2.1 JSON export (F-39) and CSV export with configurable field mappings.
2. **Architecture:** Introduce an `ExportAdapter` protocol in the export pipeline:
   ```python
   class ExportAdapter(Protocol):
       def format_indicators(self, indicators: list[IndicatorExport]) -> bytes: ...
       def content_type(self) -> str: ...
       def file_extension(self) -> str: ...
   ```
   Initial implementations: `StixAdapter`, `CsvAdapter`, `XlsxAdapter`. If APWG mandates a specific format or STIX version, we add a new adapter without changing core export logic.
3. **TLP headers:** All exports carry TLP metadata regardless of format. For STIX 2.1, TLP maps to the standard `marking-definition` objects. For CSV/XLSX, TLP appears as a header row and filename suffix.

---

**D16: Researcher Access Model — Console Role, Not Separate Portal**

**Decision:** Start as a role inside the existing console. Separate portal is Phase 4+ if demand warrants it.

**Rationale:** A separate researcher portal doubles the frontend maintenance burden, creates authentication/authorization sync issues, and delays delivery. A console role ships with the existing infrastructure and can be extracted later if needed.

**"Researcher" role permissions:**

| Surface            | Access                              | Notes                                                    |
| ------------------ | ----------------------------------- | -------------------------------------------------------- |
| Impact Dashboard   | Anonymized                          | PII entities hashed, loss amounts rounded to nearest $1K |
| Taxonomy Explorer  | Full                                | No PII involved — classification axes only               |
| Geographic Heatmap | Full                                | Country-level aggregation only                           |
| Export             | Anonymized CSV/JSON aggregates only | No case-level or entity-level PII                        |
| Entity Explorer    | No access                           | —                                                        |
| Indicator Registry | No access                           | —                                                        |
| Campaign Dashboard | No access                           | —                                                        |
| Network Graph      | No access                           | —                                                        |
| Reports/Dossiers   | No access                           | —                                                        |
| Cases & Tasks      | No access                           | —                                                        |

If researcher demand grows (different auth model, public access, different SLA), the anonymized dashboard can be extracted as a standalone Next.js app consuming the same `platform_kpis` API. But that is not needed now.

## Appendix B: Industry & Market Research

This appendix synthesizes the government, academic, and commercial landscape informing the platform design. Included for stakeholder context and to validate that our approach aligns with established practices.

### B.1 Government & Law Enforcement

**FBI Internet Crime Complaint Center (IC3)**

- Annual Internet Crime Report aggregates victim-reported losses by crime type, geography, and demographic — drives congressional funding allocation.
- Key metrics: victim count, total losses, complaints received, loss per victim.
- **Our mapping:** We must produce IC3-compatible aggregations (loss by fraud type, by state/country, by demographic) as a standard export. Our taxonomy axes map directly to IC3 crime categories.

**FTC Consumer Sentinel Network**

- Shared multi-agency database of consumer fraud reports used by 2,500+ law enforcement agencies.
- Aggregates by fraud category, payment method (wire, gift card, crypto, bank transfer), and contact method (social media, phone, email, web).
- **Our mapping:** Our `DeliveryChannel` and `RequestedAction` taxonomy axes map directly to FTC's structure. The Indicator Registry should be capable of producing FTC-format exports.

**FinCEN (Financial Crimes Enforcement Network)**

- Suspicious Activity Reports (SARs) require structured indicator lists (account numbers, routing numbers, wallet addresses) with activity date ranges and suspicion narratives.
- BSA E-Filing system expects: filer info, subject identity indicators, transaction details, narrative.
- **Our mapping:** The indicator extraction flow extends to produce SAR-ready structured exports. The SAR Supplement template (Section 11.2) implements this.

**INTERPOL Financial Crimes Unit**

- Focuses on money laundering typologies, asset tracing, crypto analytics.
- Key analytical concept: "follow the money" — linking indicators through transaction chains even when different wallets are used.
- **Our mapping:** Crypto wallet clustering (same controller, same exchange) is on the roadmap (F-46). The Network Graph enables visual "follow the money" analysis.

**FATF (Financial Action Task Force)**

- Sets AML/CTF standards adopted by 200+ countries. Requires risk-based approach: high-risk entities get enhanced due diligence.
- "Virtual Assets" guidance covers crypto exchanges, wallet risk scoring.
- **Our mapping:** Risk scores on entities and indicators are expressed in FATF-compatible language. The risk scoring formula (Section 7.5) aligns with FATF's risk-based approach.

**ACCC Scamwatch (Australia) & UK FCA ScamSmart**

- Both publish annual reports with trend analysis, loss aggregation, and geographic breakdowns.
- Both segment by victim age group, payment method, and scam category.
- **Our mapping:** Demographic aggregation of intake records (age, contact method) is a Phase 3 capability (F-49). Data gaps for `victim_age_range` and `victim_country` are addressed in Phase 0/1.

### B.2 Academic Research

**University of Cambridge Cybercrime Centre**

- Criminal market economics research: most fraud families show power-law distribution — a small number of actors cause disproportionate harm.
- **Platform implication:** "Top N entities by impact" ranking is the single most important analytical view. The Entity Explorer default sort (by case count descending) directly implements this insight.

**Carnegie Mellon CyLab**

- "Measuring the Effectiveness of Privacy Policies" — many scam sites expose PII collection forms; measuring what fields are harvested is a research signal.
- **Platform implication:** Our `pii_exposures` table from SSI investigations provides research-grade data on attacker intent — what data the adversary is trying to collect.

**MIT Lincoln Laboratory & Stanford AI Lab**

- Graph-based fraud detection: fraudsters reuse infrastructure (IPs, hosting providers, domain registrars) across campaigns even when they change surface indicators.
- _"Evil Twins"_ pattern: malicious domains that mimic legitimate brands differ by only 1-2 characters.
- **Platform implication:** Entity deduplication and shared infrastructure clustering (F-44) are core analytics primitives. Brand impersonation is already a `CampaignCorrelator` strategy.

**Georgia Tech & UC San Diego (Anti-Phishing Research)**

- Phishing campaigns have measurable lifetimes: most sites are live for under 48 hours; highly organized campaigns sustain for weeks.
- "Takedown velocity" is a key metric — time from detection to site going offline.
- **Platform implication:** `site_scans.started_at` vs. `taken_down_at` gives us takedown velocity as a performance metric (requires P1 schema gap closure).

### B.3 Commercial Platform Benchmarks

**Palantir Gotham** (Law Enforcement Data Fusion)

- Object-based data model: every person, phone, address, organization is an "object" with properties and temporal edges.
- Intel graphs show connections between objects, colored by source confidence.
- Filtering by date range animates the graph across time ("temporal spread").
- **Our mapping:** Our entity/indicator model maps well. Network Graph with temporal animation (F-41) mirrors this capability.

**IBM i2 Analyst's Notebook**

- Industry-standard link analysis for financial crime and organized crime.
- Core workflow: find an entity, expand its connections, find clusters, generate chart as PDF evidence.
- Standard export: i2 chart file (XML) or PDF with chain-of-custody metadata.
- **Our mapping:** Our Network Graph (Section 6.4) with PDF export (F-26) replicates this workflow in the browser.

**Chainalysis Reactor**

- Blockchain analytics with wallet clustering, exchange attribution, risk labels.
- "Hop" analysis: follows funds across multiple hops to identify exchange deposits.
- **Our mapping:** For crypto-heavy campaigns, wallet-to-wallet flow visualization is the gold standard. Our wallet data model is integration-ready (F-46 roadmap).

**Elliptic & TRM Labs**

- Both provide entity-level labels on blockchain addresses (mixer, exchange, dark market, known scam).
- API-based enrichment: given a wallet address, return risk score + label.
- **Our mapping:** Integration with one of these providers is on the P3 roadmap (F-46).

**NICE Actimize, SAS Fraud Management**

- Enterprise financial crime platforms used by major banks.
- Key concept: "case network" — linking SAR cases by shared entities across different customers.
- Key metric: "loss exposure by network" — if entity A is in 5 cases totaling $200K, any new case involving entity A inherits that risk weight.
- **Our mapping:** Our entity-level impact aggregation (`entity_stats.loss_sum`) directly mirrors this pattern.

**Sift, Sardine (Real-Time Fraud)**

- These platforms focus on real-time fraud detection at transaction time.
- Their visualizations are optimized for sub-second decisions; ours are for analytical investigation.
- **Our positioning:** We are in the post-hoc intelligence space, not real-time decisioning. Our UX emphasizes depth and comprehensiveness over speed.

### B.4 Industry Collaboration

**eCrimeX (Electronic Crime Exchange)** — APWG's shared intelligence database

- i4g both submits to and polls from eCrimeX, creating a two-way enrichment loop.
- The platform should visualize the eCrimeX enrichment status of our indicators — what % of our submissions returned hits, what % were novel contributions.

**Financial Services ISAC (FS-ISAC)**

- Sector-specific threat sharing for banks and financial institutions.
- Operates on Traffic Light Protocol (TLP) coloring for data sensitivity.
- **Our mapping:** All exported data packages carry TLP labels. The Partner Indicator Feed API (F-52) is designed for FS-ISAC-compatible distribution.

### B.5 Standards

- **STIX/TAXII 2.1** — OASIS standard for structured threat intelligence exchange. Our entity/indicator model maps to STIX Observable objects. F-39 implements STIX export.
- **Traffic Light Protocol (TLP)** — FIRST standard for data sensitivity. Applied to all exports per D10.
- **MITRE ATT&CK** — Adversary techniques framework. Future mapping: social engineering techniques could map to our Technique taxonomy axis.

---

## Appendix C: Data Asset Inventory

This appendix inventories the analytically valuable data already in the database — the raw material that the analytics platform transforms into intelligence.

### C.1 Entity Signals

| Field             | Table                                   | Analytic Use                                                                  |
| ----------------- | --------------------------------------- | ----------------------------------------------------------------------------- |
| `entity_type`     | `entities`                              | Segment by type (wallet, IP, email, phone, person, domain, URL, bank_account) |
| `canonical_value` | `entities`                              | Unique normalized identifier — dedup key                                      |
| `first_seen_at`   | `entities`                              | Campaign onset, actor tenure                                                  |
| `last_seen_at`    | `entities`                              | Activity recency, dormancy                                                    |
| Case count (join) | `entities` ↔ `cases`                    | Prevalence rank                                                               |
| Loss sum (join)   | `entities` → `cases` → `intake_records` | Impact rank                                                                   |
| Risk score (join) | `entities` → `cases.risk_score`         | Max / avg risk                                                                |

### C.2 Indicator Signals

| Field                  | Table                                        | Analytic Use                                                                     |
| ---------------------- | -------------------------------------------- | -------------------------------------------------------------------------------- |
| `category`             | `indicators`                                 | Bank / Crypto / Payments segmentation                                            |
| `item`                 | `indicators`                                 | Named financial institution (e.g. "Chase", "Bitcoin")                            |
| `type`                 | `indicators`                                 | Account type (checking, savings, routing, cryptocurrency, payment_service, etc.) |
| `number`               | `indicators`                                 | The identifier itself (wallet address, account number, handle)                   |
| `first_seen_at`        | `indicators`                                 | First appearance                                                                 |
| `last_seen_at`         | `indicators`                                 | Most recent activity                                                             |
| Case link count (join) | `indicators` → `indicator_sources` → `cases` | Usage frequency                                                                  |

### C.3 Case & Classification Signals

| Field                          | Table   | Analytic Use                                                 |
| ------------------------------ | ------- | ------------------------------------------------------------ |
| `classification`               | `cases` | Top-level fraud type                                         |
| `classification_result` (JSON) | `cases` | Five-axis: Intent, Channel, Technique, Action, Persona       |
| `risk_score`                   | `cases` | 0-100 severity score                                         |
| `confidence`                   | `cases` | Classification confidence                                    |
| `detected_at`                  | `cases` | Detection timeline                                           |
| `reported_at`                  | `cases` | Report-to-detection lag                                      |
| `source_type`                  | `cases` | Proactive (`ssi_investigation`) vs. reactive (`user-report`) |
| `tags`                         | `cases` | Freeform analyst labels                                      |
| `status`                       | `cases` | Open / closed lifecycle                                      |
| `campaign_id`                  | `cases` | Legacy campaign/batch grouping (see D8 for migration)        |

### C.4 Victim Loss Signals

| Field                 | Table            | Analytic Use                                         |
| --------------------- | ---------------- | ---------------------------------------------------- |
| `loss_amount`         | `intake_records` | Dollar loss per victim                               |
| `incident_date`       | `intake_records` | Victim-reported date of loss                         |
| `contact_handle`      | `intake_records` | Contact method of scammer                            |
| `summary` / `details` | `intake_records` | Narrative (for LLM extraction of additional signals) |

### C.5 SSI Investigation Signals

| Field                                             | Table                 | Analytic Use                                         |
| ------------------------------------------------- | --------------------- | ---------------------------------------------------- |
| `url`                                             | `site_scans`          | Scam site URL                                        |
| `scan_type`                                       | `site_scans`          | passive / active / full                              |
| `started_at`, `completed_at`                      | `site_scans`          | Investigation duration, site availability            |
| `wallet_address`, `token_symbol`, `network_short` | `harvested_wallets`   | Crypto indicator from live site                      |
| `confidence`, `source`                            | `harvested_wallets`   | Extraction confidence, method                        |
| `field_type`, `element_type`                      | `pii_exposures`       | What victim data the scam site attempts to collect   |
| `page_url`                                        | `pii_exposures`       | Which page collects PII                              |
| Domain WHOIS fields                               | `site_scans.metadata` | Registrar, creation date, expiry, registrant country |
| SSL fields                                        | `site_scans.metadata` | Issuer, validity, SAN                                |
| GeoIP fields                                      | `site_scans.metadata` | Country, city, ASN                                   |

### C.6 eCrimeX Enrichment Signals

| Field                                                 | Analytic Use                                                |
| ----------------------------------------------------- | ----------------------------------------------------------- |
| `ecx_submissions` count                               | Contribution rate to the global clearinghouse               |
| `ecx_submissions.status`                              | Acceptance rate — quality signal                            |
| `ecx_polling_state` freshness                         | How current our inbound enrichment is                       |
| `phish_hits`, `crypto_hits`, `domain_hits`, `ip_hits` | Cross-validation rate (our indicators vs. known bad in eCX) |

### C.7 Temporal Richness (Time-Series Potential)

The following time-series analyses are enabled by existing timestamped data:

- New cases per day/week/month (trend line)
- Entity `first_seen` distribution over time (campaign emergence)
- Victim report timing vs. case detection timing (response lag)
- Campaign lifetimes (first case `detected_at` → last case `resolved_at` per campaign)
- SSI site availability windows (time from `site_scans.started_at` to case closure)

---

_End of Document — PRD v1.0 (Consolidated)_

_This document consolidates v0.1 and v0.2 with all open questions resolved. Ready for stakeholder review._

_Next steps:_

1. _Distribute to product, engineering, security research, and LEA liaison for review_
2. _Prototype the Entity Explorer and Impact Dashboard wireframes before committing Phase 1 scope_
3. _Spike: LLM extraction accuracy for intake-to-indicator loss linkage — test on 50 intake narratives and measure precision/recall_
4. _Phase 0 kickoff: `threat_campaigns` schema + `ingestion_batch_id` migration + aggregation job_
