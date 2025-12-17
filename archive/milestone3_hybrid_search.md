# Milestone 3 Hybrid Search Design Spike

_Last updated: 2 Dec 2025_

Milestone 3 focuses on empowering analysts with a unified search experience that merges semantic retrieval (Vertex AI Search) with structured filtering backed by SQL/Firestore entities. This spike captures the architecture decisions, API contracts, UI requirements, and delivery plan needed before implementation begins.

## 1. Goals & Success Criteria

1. **Single Search Surface**: Analysts issue one query and receive deduplicated results that blend Vertex AI semantic hits with SQL/Firestore structured matches.
2. **Deterministic Filters**: Analysts can constrain searches by indicator type, entity value (bank account, wallet, email, IP, ASN, browser agent, etc.), classification, dataset, and time range.
3. **Auditable Results**: Every merged result exposes provenance metadata (source store, scores, entity matches) so analysts can explain why a document appeared.
4. **Pluggable Backends**: The design must honor the existing settings/factory pattern so local dev sticks with Chroma/SQLite while dev/prod speak Vertex AI Search + Cloud SQL/Firestore.

## 2. Current State Recap

- **Ingestion**: Milestone 2 dual-write pipeline stores entities in SQLite/SQL + Firestore and pushes documents to Vertex AI Search. Retry queue guarantees Vertex parity.
- **API**: `HybridRetriever` currently proxies a text query to the vector + structured stores but lacks configurable filters, scoring policies, or dataset awareness.
- **UI**: Streamlit + Next.js consoles expose basic search (text + case/classification filters) without structured entity selectors.

## 3. Proposed Retrieval Architecture

### 3.1 Service-level Changes

- Introduce `services/hybrid_search.py` that orchestrates retrieval across:
  - **Semantic Provider**: Vertex AI Search (or Chroma locally) via a `VectorSearchClient` abstraction.
  - **Structured Provider**: SQL/Firestore via `ReviewStore` + future `EntityStore` queries.
- The service accepts a `HybridSearchQuery` dataclass with:
  - `text: str | None`
  - `entities: list[EntityFilter]` (type, value, match mode)
  - `classifications: list[str]`
  - `datasets: list[str]`
  - `time_range: tuple[datetime, datetime] | None`
  - `limit/vector_limit/structured_limit`
- Response surface: list of `HybridSearchResult` containing case metadata, structured attributes, semantic snippet, `scores` dict, and `source` ("vertex", "structured", "merged").

### 3.2 API Updates (`src/i4g/api/review.py`)

1. Add request models for the richer filters (entity filters, date ranges, dataset selectors).
2. Replace direct `HybridRetriever` calls with the new service, ensuring dependency injection still flows through factories for testability.
3. Emit audit logs that capture:
   - filter payloads
   - per-store hit counts
   - normalized scores after deduplication/merging
4. Support pagination by carrying cursor tokens for Vertex (if available) and offsets for SQL queries; default to 25 merged results.

### 3.3 Deduplication & Scoring

- Merge results by `case_id` (primary) and document URI (secondary).
- Score policy proposal:
  - `merged_score = max(vertex_score * semantic_weight, structured_rank * structured_weight)`
  - Expose weights via settings, defaulting to 0.65 semantic / 0.35 structured.
- Track `vector_hits`, `structured_hits`, and `merged_count` for UI metrics.

### 3.4 Observability

- Emit structured logs (JSON) with request_id, filters, backend latencies, result counts.
- Add `metrics/hybrid_search.py` helper for StatsD/OTel counters: total queries, per-backend latency, cache hit rate (future).

## 4. Structured Filter Requirements

### 4.1 Supported Filters (MVP)

| Filter | Description | Backend Source |
| --- | --- | --- |
| Indicator Type | Enum (bank_account, crypto_wallet, email, phone, ip_address, asn, browser_agent, url, merchant) | SQL/Firestore (entity tables) |
| Indicator Value | Exact or prefix match, case-insensitive | SQL LIKE + Firestore queries |
| Dataset | `retrieval_poc_dev`, `account_list`, etc. | SQL + Vertex metadata |
| Classification | `romance`, `tech_support`, `pig_butcher`, etc. | Stored on cases/entities |
| Time Range | `created_at` or `ingested_at` window | SQL timestamps + Vertex metadata |
| Loss Threshold | Numeric min/max (USD) | SQL case summary |

### 4.2 API Contract for Filters

Add `GET /reviews/search/schema` (or repurpose `/reviews/search/tag-presets`) to return:

```json
{
  "indicator_types": ["bank_account", "crypto_wallet", "ip_address"],
  "datasets": ["retrieval_poc_dev", "account_list"],
  "classifications": ["romance", "tech_support"],
  "loss_buckets": ["<10k", "10k-50k", ">50k"],
  "time_presets": ["7d", "30d", "90d"],
  "entity_examples": {
    "bank_account": ["021000021-123456789"],
    "crypto_wallet": ["bc1q..."],
    "ip_address": ["203.0.113.25"]
  }
}
```

This allows the UI to populate dropdowns without hardcoding enumerations.

### 4.3 UI Implications

- **Streamlit Console**: add an “Advanced Filters” drawer with multi-select chips. Persist selections per user via existing saved-search infrastructure.
- **Next.js Console**: implement reusable filter components under `ui/apps/web/src/components/search/filters/`, leveraging the API schema to stay dynamic.
- **Saved Searches**: extend the schema to include the new filter objects so analysts can re-run structured searches. Requires migrations/UI validation.

## 5. Delivery Plan

| Week | Workstream | Key Tasks |
| --- | --- | --- |
| Week 5 (Dev Sprint 1) | Backend | Build `HybridSearchService`, extend Review API models/endpoints, add settings + metrics. |
| Week 5 | Data | Ensure ingestion populates new entity fields (browser agent, IP, ASN) and expose SQL views for filter queries. |
| Week 6 (Dev Sprint 2) | UI | Implement Streamlit + Next.js filter components; wire to new API contract. |
| Week 6 | Testing | Add pytest coverage for query permutations, load-test hybrid search, capture golden responses for UI regression tests. |

## 6. Dependencies & Open Questions

1. **Entity Coverage**: confirm ingestion emits browser agent/IP/ASN fields before UI depends on them. Otherwise gate the filters via feature flags.
2. **Vertex Quota**: evaluate whether merging requires additional Vertex read quotas; consider caching frequent searches.
3. **SQL Backend**: local dev uses SQLite; need deterministic ordering + case-insensitive search (likely via indexed `LOWER()` columns).
4. **Security**: ensure new filters don’t expose PII beyond authenticated analysts; audit logging must include filter payloads for compliance.
5. **Saved Search Schema Migration**: decide whether to version saved searches or auto-migrate when new filters appear.

## 7. Next Actions

1. Finalize `HybridSearchService` interface and add stubs to `src/i4g/services/`.
2. Update `ReviewStore` and the forthcoming `EntityStore` with helper queries for indicator filters.
3. Define the JSON schema for `GET /reviews/search/schema` and mock responses for UI development.
4. Create Jira/Trello tasks (or equivalent) per table in the delivery plan and link them to this spike.

## 8. Execution Checklist & Status

### Backend / API
- [x] Ship `SearchSettings`, `HybridSearchService`, and `/reviews/search/schema` so FastAPI exposes the richer payloads.
- [x] Extend `ReviewStore`/`EntityStore` query helpers for entity filters (prefix/exact, dataset scoping, loss buckets), including dataset + entity example surfacing for the schema endpoint.
- [x] Finalize dedupe + scoring policy (semantic vs structured weights, tie-breakers) and add audit logging for merged counts. _Dec 2: HybridSearchService now emits winner/tie diagnostics, source breakdowns, and the Review API logs merged counts for every search._
- [x] Add observability hooks (structured logs + metrics helper) and wire to existing StatsD/OTel exporters.

### Data & Ingestion
- [x] Verify ingestion emits browser agent / IP / ASN fields and backfill any gaps before UI surfaces those filters.
- [x] Document ingestion smoke for the new entity columns (tests + `docs/smoke_test.md`).

### UI Workstreams
- [x] Fetch schema server-side (Next.js) and plumb into search experience.
- [x] Finish Next.js filter UX (entity builder polish, saved-search parity, `/api/search` payload forwarding). _Dec 2: Next.js now forwards/clears saved-search descriptors, reuses the new payload builder everywhere, and has Vitest coverage for the rerun flows._
- [x] Update Streamlit console with the same schema-driven filters and persistence. _Dec 2: Streamlit adds a schema-driven Advanced Filters drawer (datasets, loss buckets, entity builder, time presets) backed by `/reviews/search/schema`, and saved searches now capture/replay the structured payloads._
- [x] Migrate saved-search payloads to persist the structured filters (schema versioning + validation UI). _Dec 2: backend + Streamlit now normalize saved-search params into the `HybridSearchRequest` schema, auto-inject schema_version, and replay via `/reviews/search/query`._

### Testing & Quality Gates
- [x] Add Vitest coverage for helper utilities (schema parsing, SearchExperience interactions).
- [x] Expand backend pytest suite with hybrid query permutations + dedupe scoring assertions. _Dec 2: added overlap/time-range/tie tests in `tests/unit/services/test_hybrid_search_service.py`._
- [x] Grow Playwright smoke coverage for `/search` (filters, saved-search create/run) and run before releases. _Dec 2: new smoke scenario exercises entity filters, taxonomy/dataset chips, and saved-search prompts via `conda run -n i4g pnpm --filter web test:smoke`._

### Documentation & Operations
- [x] Refresh `docs/config` + UI README with hybrid search env vars and testing strategy.
- [x] Draft analyst runbook entry (how to use structured filters, schema definitions, saved-search migration notes).
- [x] Capture deployment checklist (env vars, Task_STATUS expectations, metrics dashboards) ahead of dev → prod promotion. _See `docs/runbooks/hybrid_search_deployment_checklist.md` (Dec 2)._

## 9. Two-Week Execution Plan (Dec 1–12)

### Week of Dec 1 (Sprint 5 wrap-up)
- **Backend core** (owner: Jerry, due Dec 4): finalize `HybridSearchService` scoring knobs (`semantic_weight`, `structured_weight`) and surface diagnostics in `/reviews/search/query` responses; ship unit tests that assert merged ordering across mixed result sets.
- **Structured store extensions** (owner: Jerry, due Dec 5): land `EntityStore` helpers for prefix/contains filters plus dataset scoping; wire them into the service factories so local and dev environments stay in parity.
- **Schema + documentation** (owner: Jerry, done Dec 1): publish `docs/runbooks/analyst_runbook.md` (complete) and keep `/reviews/search/schema` payload examples in sync inside `docs/development/dev_guide.md` + the UI handbook.
- **Ingestion verification** (owner: Jerry, due Dec 5): re-run the dev `ingest-network-smoke` Cloud Run job after any schema change, then execute `pnpm --filter web test:smoke` to confirm the Next.js filter drawer renders the new chips.

### Week of Dec 8 (Sprint 6 kickoff)
- **Next.js integration** (owner: UI lead, target Dec 10): consume the expanded schema via server-side data fetch, migrate the Filter Drawer to schema-driven chips, and ensure saved searches persist the enriched payload.
- **Saved-search migration tooling** (owner: Jerry, completed Dec 2): added `--schema-version` to `i4g-admin export-saved-searches`, created `scripts/tag_saved_searches.py` for tagging/annotation, wired defaults through `[search.saved_search]`, and updated the analyst runbook with the workflow.
- **Testing & observability** (owner: Jerry, target Dec 11): expand pytest coverage with dedupe/scoring fixtures, add StatsD counters for per-source result ratios, and update Playwright smoke to assert that entity chips/datasets populate from live schema calls.
- **Operational readiness** (owner: Jerry, target Dec 12): draft the remaining deployment checklist (env vars, Task_STATUS expectations, dashboards) so Milestone 3 handoff notes cover both backend knobs and UI verification steps.
