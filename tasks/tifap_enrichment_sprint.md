# TIFAP Enrichment Sprint — Post-Demo Feedback

**Created:** 2026-04-03
**Status:** Planning
**Trigger:** Stakeholder demo feedback — impressive ideas, but users can't intuitively understand
what they're seeing. Data and UI need to support each other more tightly.

---

## Executive Assessment (CTO / CPO / Consultant)

The demo surfaced a fundamental gap: **TIFAP has good data depth but poor data
storytelling.** The platform computes entities, graphs, classifications, and campaigns — but
each feature is a silo. Users hit dead ends when they want to answer "why?" or "what else?"

The fix isn't more features — it's **connective tissue**: cross-references, provenance trails,
contextual explanations, and seamless navigation between related objects. Every screen should
answer "what am I looking at?" and offer "where can I go next?"

### Guiding Principles

1. **Every data point is a doorway** — entities link to cases, cases link to graphs,
   graphs link back to cases. No dead ends.
2. **Explain, don't just display** — tooltips, legends, and inline descriptions for
   graph concepts, entity types, edge meanings.
3. **Reduce clicks for common workflows** — entity→graph in one click, case→entity
   drilldown without page navigation.
4. **Provenance is trust** — users need to see _which cases_ produced a connection,
   not just that a connection exists.

---

## Phase 0 — Bug Fix: Classification Job Regression

**Priority:** P0 (blocking demo data quality)
**Repos:** `core`
**Estimate:** Investigation + fix

### Problem

~1,300 ingested cases still show "unclassified" after 24 hours. The classification sweeper
should process all pending cases within hours.

### Investigation Steps

- [x] Check classification_status distribution:
      `SELECT classification_status, COUNT(*) FROM cases GROUP BY 1`
- [x] Check if sweeper job ran at all (Cloud Run job logs or local job output)
- [x] Check `settings.sweep.batch_size` and `settings.sweep.max_runtime_seconds` —
      if batch_size is small and max_runtime is short, 1,300 cases could take many runs
- [x] Check if entity extraction job is competing for the same LLM quota (both use
      LLM calls; if quota-limited, one starves the other)
- [x] Check if any cases are stuck in a state other than "pending" (e.g., an intermediate
      status that the sweeper doesn't query)
- [x] Verify the sweeper query matches the ingestion pipeline's initial status assignment —
      if ingestion writes `classification_status = NULL` instead of `"pending"`, the sweeper
      skips them entirely

### Fix

Once root cause identified, fix + re-run sweeper on local dataset to verify all 1,300 cases
get classified. Add a monitoring query / health-check endpoint that reports classification
backlog.

---

## Phase 1 — Case Detail: Entity Card + Cross-References

**Priority:** P0 (core usability gap)
**Repos:** `core` (API), `ui` (case page)

### 1.1 Add Entity Card to Case Detail Page

- [x] **API: Include structured entities in CaseDetail response**
  - File: `core/src/i4g/api/cases.py` (GET `/cases/{case_id}` handler)
  - Currently entities are flattened into `graph_nodes` (just `{id, label, type}`)
  - Add a new `entities` field to `CaseDetail` model:
    ```
    entities: list[CaseEntity]  # grouped by type, with metadata
    ```
  - `CaseEntity` model: `entity_type`, `canonical_value`, `raw_value`, `confidence`,
    `first_seen_at`, display label from `ENTITY_TYPE_LABELS`
  - Query from `entities` table WHERE `case_id = {id}`, grouped by type

- [x] **UI: Render Entity Card on case detail page**
  - File: `ui/apps/web/src/app/(console)/cases/[id]/page.tsx`
  - Add 6th card: **"Extracted Entities"** between Classification and Artifacts
  - Group entities by type with collapsible sections
  - Each entity row shows: value, confidence badge, first-seen date
  - Each entity value is a **clickable link** to:
    - Entity detail: `/intelligence/entities/{type}/{value}`
    - Graph view: `/intelligence/graph?seed_type={type}&seed_value={value}`
      (one-click "View in Graph" icon button)
  - Show count badge per type group (e.g., "Wallet Addresses (3)")

- [x] **SDK: Add entity types to CaseDetail TypeScript type**
  - File: `ui/packages/sdk/src/index.ts`
  - Add `CaseEntity` type and update `CaseDetail` to include `entities` array

### 1.2 Classification Card Enhancement

- [x] **Show "Classification pending" with ETA for unclassified cases**
  - Instead of just "Not yet classified", show: "Classification in progress — typically
    completes within 2 hours of ingestion"
  - If classified, show full 5-axis breakdown (intent, channel, technique, action, persona)
    with confidence scores — not just the top label

---

## Phase 2 — Entity → Graph One-Click Navigation

**Priority:** P1 (workflow friction)
**Repos:** `ui`

### 2.1 "View in Graph" Button on Entity Explorer

- [x] **Entity explorer table: Add graph icon button per row**
  - File: `ui/apps/web/src/app/(console)/intelligence/entities/entity-explorer.tsx`
  - Add a small graph icon (⊛ or network icon) in each entity row
  - On click: navigate to `/intelligence/graph?seed_type={entityType}&seed_value={canonicalValue}`

- [x] **Entity detail panel: Add prominent "Explore in Graph" button**
  - In the slide-over entity detail panel, add a primary action button
  - Navigates to graph page with entity pre-loaded as seed

### 2.2 Graph Page: Accept URL Parameters for Deep Linking

- [x] **Support URL search params for seed initialization**
  - File: `ui/apps/web/src/app/(console)/intelligence/graph/network-graph.tsx`
  - Read `seed_type` and `seed_value` from URL search params
  - If present, auto-populate form fields and trigger graph load on mount
  - Update URL when user changes seed (for shareable links / browser back)

### 2.3 Case Detail → Graph Navigation

- [ ] **On the new Entity Card (Phase 1.1), add "View Case Graph" button**
  - Loads graph seeded from the case itself (using `seed_type=case`)
  - Shows all entities from this case and their connections

---

## Phase 3 — Graph Explainability & Provenance

**Priority:** P1 (trust and understanding)
**Repos:** `core` (API + graph service), `ui` (graph page)

### 3.1 Edge Provenance: Include Source Case IDs

- [x] **Graph service: Store case IDs on edges**
  - File: `core/src/i4g/services/graph_service.py`
  - When building co-occurrence edges, collect and attach the list of shared `case_id`s
    (capped at e.g. 20 for payload size)
  - Update `GraphEdge` model to include:
    ```python
    case_ids: list[str] = []  # IDs of cases where both entities co-occur
    ```

- [x] **Analytics store: Return case IDs in neighbor queries**
  - File: `core/src/i4g/store/analytics_store.py`
  - `get_entity_neighbors()` currently returns `shared_cases` count only
  - Add variant or option to return the actual case IDs (via `array_agg`)

- [x] **API: Include case_ids in GraphEdge response**
  - File: `core/src/i4g/api/intelligence.py`
  - Update `GraphEdgeResponse` to include `case_ids` list
  - Update SDK `GraphEdge` type to match

### 3.2 Edge Click → Case List

- [x] **UI: Clicking an edge shows a popover with linked cases**
  - File: `ui/apps/web/src/app/(console)/intelligence/graph/network-graph.tsx`
  - On edge click, show popover/tooltip listing:
    - Number of shared cases
    - Edge type with human-readable description
    - List of case IDs (clickable → `/cases/{id}`)
  - Example: "These two entities co-occur in 5 cases: [Case A], [Case B], ..."

### 3.3 Node Click → Entity Detail + Case List

- [x] **UI: Clicking a node shows entity summary popover**
  - Show: entity type (with human label), canonical value, case count, risk score
  - Action buttons: "View Entity Detail", "Explore from Here" (re-seed graph),
    "View Cases" (list of cases containing this entity)

- [ ] **API: Add endpoint for entity→cases lookup**
  - `GET /intelligence/entities/{type}/{value}/cases` → paginated list of case summaries
  - Returns: case_id, title, status, risk_score, classification, created_at

### 3.4 Graph Legend & Contextual Help

- [x] **Add persistent legend panel to graph page**
  - Node colors: map each entity type to its color with label
    (e.g., 🟣 Wallet Address, 🔵 Person, 🟢 Organization, ...)
  - Edge types: color + description
    - Gray solid = co-occurrence ("appear in the same case")
    - Orange dashed = shared infrastructure
    - Blue = same campaign
  - Node size: proportional to case count
  - Edge thickness: proportional to weight (shared case count)

- [x] **Add info button with modal explaining graph concepts**
  - "What am I looking at?" help modal:
    - **Nodes** are entities extracted from fraud complaint cases (people, wallet
      addresses, phone numbers, organizations, etc.)
    - **Edges** connect entities that appear together in the same case — the thicker
      the line, the more cases share those entities
    - **Organization nodes** represent business names, company names, or group names
      mentioned in case narratives — they may be legitimate businesses impersonated
      by scammers, or actual scam organizations
    - **Clusters** (colored rings) are groups of tightly connected entities detected
      by community analysis — they often represent a single fraud operation

---

## Phase 4 — Cross-Reference Enrichment (Connective Tissue)

**Priority:** P1 (platform cohesion)
**Repos:** `core`, `ui`

### 4.1 Entity Detail Page: Show Linked Cases

- [ ] **Enhance entity detail view with case list**
  - When viewing an entity (either from explorer or from case page link), show:
    - Entity metadata (type, value, first/last seen, risk score, loss sum)
    - **Cases tab**: Paginated list of cases containing this entity
    - **Graph tab**: Mini neighbor graph (existing `/neighbors` endpoint)
    - **Activity tab**: Sparkline (existing `/activity` endpoint)
    - **Campaigns tab**: Linked campaigns (existing campaign linkage)

### 4.2 Case Detail: Related Cases via Shared Entities

- [x] **API: Add "related cases" endpoint**
  - `GET /cases/{case_id}/related` → cases sharing entities with this case
  - Algorithm: Find entities of this case → find other cases with same entities →
    rank by number of shared entities
  - Returns: case_id, title, shared_entity_count, shared_entities sample

- [x] **UI: Add "Related Cases" card or section to case detail**
  - Shows top 5-10 related cases with shared entity badges
  - Clickable → navigate to related case

### 4.3 Campaign Context Everywhere

- [ ] **Case detail: Show linked campaigns**
  - If case belongs to any threat campaigns, show campaign badge(s)
  - Clickable → campaign detail page

- [ ] **Entity detail: Show campaigns**
  - Already partially supported via `campaign_ids` in entity_stats
  - Render campaign names as clickable badges

- [ ] **Graph nodes: Campaign membership indicator**
  - Nodes belonging to the same campaign get a shared visual indicator
  - Campaign filter toggle in graph controls

### 4.4 Breadcrumb Navigation

- [ ] **Add contextual breadcrumbs across intelligence pages**
  - `Cases > Case ABC-123 > Entities > wallet_address:0x... > Graph`
  - Supports browser back behavior and orientation
  - Every page knows where the user came from

---

## Phase 5 — Data Quality & Completeness

**Priority:** P1 (trust in data)
**Repos:** `core`

### 5.1 Aggregation Freshness

- [x] **Ensure analytics aggregation job runs after ingestion**
  - Verify `entity_stats`, `indicator_stats`, `campaign_stats` are fresh
  - Add "last updated" timestamp visible in dashboard

### 5.2 Entity Extraction Coverage

- [x] **Verify all 1,300 cases have entities extracted**
  - Query: `SELECT COUNT(*) FROM cases WHERE case_id NOT IN (SELECT DISTINCT case_id FROM entities)`
  - If extraction missed cases, investigate and re-run

### 5.3 Classification + Entity Dependency Check

- [ ] **Ensure both jobs can run without blocking each other**
  - Classification sweeper and entity extraction both use LLM
  - If sharing a quota, add staggered scheduling or separate quota pools

---

## Phase 6 — Polish & Demo Readiness

**Priority:** P2 (demo impact)
**Repos:** `ui`

### 6.1 Empty State Improvements

- [ ] **Every card/section: meaningful empty states instead of blank**
  - "No entities extracted yet — extraction runs automatically after ingestion"
  - "Classification in progress — 1,247 of 1,300 cases classified"
  - "No related cases found — this case's entities are unique"

### 6.2 Loading States & Progress

- [ ] **Show classification/extraction progress on dashboard**
  - "1,300 cases ingested | 1,247 classified | 1,198 entities extracted"
  - Progress bar or percentage

### 6.3 Graph Visual Polish

- [ ] **Node tooltips on hover** (quick info without clicking)
- [ ] **Edge labels on hover** ("3 shared cases")
- [ ] **Zoom-to-fit button** (auto-frame all nodes)
- [ ] **Minimap** for large graphs
- [ ] **Search within graph** (highlight a node by typing entity value)

---

## Implementation Order

```
Phase 0 ─── Classification Bug Fix ──────────────────── (do first, unblocks data)
   │
Phase 1 ─── Entity Card on Case Page ────────────────── (core usability)
   │
Phase 2 ─── Entity→Graph Navigation ─────────────────── (workflow friction)
   │
Phase 3 ─── Graph Explainability ─────────────────────── (trust & understanding)
   │
Phase 4 ─┬─ Cross-Reference Enrichment ──────────────── (platform cohesion)
   │      │
Phase 5 ─┘─ Data Quality ────────────────────────────── (parallel with Phase 4)
   │
Phase 6 ─── Polish & Demo Readiness ─────────────────── (final pass)
```

Phases 0–2 can realistically ship before a second demo.
Phases 3–4 are the high-impact "connective tissue" work.
Phases 5–6 are quality and polish.

---

## Risk Assessment

| Risk                                                   | Impact            | Mitigation                                                |
| ------------------------------------------------------ | ----------------- | --------------------------------------------------------- |
| Classification regression is deeper than config        | Blocks demo data  | Investigate first; can manually trigger re-classification |
| Edge provenance (case IDs) bloats graph payload        | Slow graph loads  | Cap at 20 case_ids per edge; lazy-load on click           |
| Entity card on case page requires API change           | SDK type mismatch | Update SDK types before UI work                           |
| Graph URL deep-linking changes browser history         | UX confusion      | Use `replaceState` not `pushState` for seed changes       |
| Related cases query is expensive (entity join fan-out) | Slow case detail  | Pre-compute in analytics aggregation; add index           |

---

## Files Affected (Summary)

### Core (API + Services)

- `src/i4g/api/cases.py` — Add entities to CaseDetail, add `/cases/{id}/related`
- `src/i4g/api/intelligence.py` — Add `/entities/{type}/{value}/cases`, update graph response
- `src/i4g/services/graph_service.py` — Store case_ids on edges
- `src/i4g/store/analytics_store.py` — Return case_ids in neighbor queries
- `src/i4g/worker/jobs/classification_sweeper.py` — Bug fix (TBD based on investigation)

### UI (Pages + Components)

- `apps/web/src/app/(console)/cases/[id]/page.tsx` — Entity card, related cases, campaign badges
- `apps/web/src/app/(console)/intelligence/entities/entity-explorer.tsx` — Graph nav button
- `apps/web/src/app/(console)/intelligence/graph/network-graph.tsx` — URL params, legend, explainability
- `packages/sdk/src/index.ts` — CaseEntity type, updated GraphEdge type

### Tests

- `tests/unit/api/test_cases.py` — Entity card response
- `tests/unit/api/test_intelligence.py` — New endpoints
- `tests/unit/services/test_graph_service.py` — Edge provenance
