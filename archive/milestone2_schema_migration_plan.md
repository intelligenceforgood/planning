# Milestone 2 – Dual Extraction Schema & Migration Plan

_Last updated: 29 Nov 2025_

## 1. Goals
- Deliver concrete SQL definitions for the dual-write schema (runs, cases, documents, entities, indicators, joins).
- Describe the ERD relationships and indexing strategy required for Milestone 3 hybrid retrieval.
- Outline the migration path for both local SQLite (developer laptops) and Cloud SQL/AlloyDB (dev/prod).
- Provide execution/rollback procedures so CI/CD and operators can apply migrations safely.

## 2. Entity-Relationship Summary
```
ingestion_runs (1) ──< cases (1) ──< source_documents
                         └──< entities ──< entity_mentions
                         └──< indicators ──< indicator_sources
```
Key notes:
- `cases.dataset` + `cases.raw_text_sha256` keep replays idempotent.
- `source_documents` rows mirror the Vertex/Firestore document contract (document UUID + chunk metadata).
- `indicators.category` aligns with `IndicatorCategory` enum; `indicator_sources` bridges to both docs and entities.
- All child tables include `created_at`/`updated_at` timestamps for auditing and cross-store reconciliation.

## 3. Canonical Table Definitions
The following DDL targets Postgres/AlloyDB first; SQLite-compatible adjustments are listed after each block.

### 3.1 `ingestion_runs`
```sql
CREATE TABLE ingestion_runs (
    run_id UUID PRIMARY KEY,
    dataset TEXT NOT NULL,
    source_bundle TEXT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ NULL,
    status TEXT NOT NULL CHECK (status IN ('scheduled','running','succeeded','failed','partial')),
    case_count INTEGER NOT NULL DEFAULT 0,
    entity_count INTEGER NOT NULL DEFAULT 0,
    indicator_count INTEGER NOT NULL DEFAULT 0,
    firestore_writes INTEGER NOT NULL DEFAULT 0,
    vertex_writes INTEGER NOT NULL DEFAULT 0,
    sql_writes INTEGER NOT NULL DEFAULT 0,
    retry_count INTEGER NOT NULL DEFAULT 0,
    vector_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_ingestion_runs_started_at ON ingestion_runs (started_at DESC);
CREATE INDEX idx_ingestion_runs_status ON ingestion_runs (status);
```
SQLite notes: replace `UUID` with `TEXT`, `TIMESTAMPTZ` with `TEXT`, drop JSONB constraint (use `TEXT`).

### 3.2 `cases`
```sql
CREATE TABLE cases (
    case_id TEXT PRIMARY KEY,
    ingestion_run_id UUID REFERENCES ingestion_runs(run_id) ON DELETE SET NULL,
    dataset TEXT NOT NULL,
    source_type TEXT NOT NULL,
    classification TEXT NOT NULL,
    confidence NUMERIC(5,4) NOT NULL DEFAULT 0.0,
    detected_at TIMESTAMPTZ NULL,
    reported_at TIMESTAMPTZ NULL,
    raw_text_sha256 TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open',
    metadata JSONB NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_cases_dataset_rawsha UNIQUE (dataset, raw_text_sha256)
);
CREATE INDEX idx_cases_dataset_reported_at ON cases (dataset, reported_at DESC);
CREATE INDEX idx_cases_classification ON cases (classification);
CREATE INDEX idx_cases_status ON cases (status);
```
SQLite notes: emulate partial unique constraint via trigger; timestamps stored as ISO strings.

### 3.3 `source_documents`
```sql
CREATE TABLE source_documents (
    document_id UUID PRIMARY KEY,
    case_id TEXT NOT NULL REFERENCES cases(case_id) ON DELETE CASCADE,
    title TEXT NULL,
    source_url TEXT NULL,
    mime_type TEXT NULL,
    text TEXT NULL,
    text_sha256 TEXT NULL,
    excerpt TEXT NULL,
    chunk_index INTEGER NOT NULL DEFAULT 0,
    chunk_count INTEGER NOT NULL DEFAULT 1,
    score NUMERIC(6,3) NULL,
    captured_at TIMESTAMPTZ NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_documents_case ON source_documents (case_id, captured_at DESC);
```
SQLite notes: if `text` exceeds default page size, rely on external blobs referenced via `metadata.storage_uri`.

### 3.4 `entities`
```sql
CREATE TABLE entities (
    entity_id UUID PRIMARY KEY,
    case_id TEXT NOT NULL REFERENCES cases(case_id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    canonical_value TEXT NOT NULL,
    raw_value TEXT NULL,
    confidence NUMERIC(5,4) NOT NULL DEFAULT 0.0,
    first_seen_at TIMESTAMPTZ NULL,
    last_seen_at TIMESTAMPTZ NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_entities_case_type_value UNIQUE (case_id, entity_type, canonical_value)
);
CREATE INDEX idx_entities_type_value ON entities (entity_type, canonical_value);
```
SQLite notes: replace UNIQUE with trigger if needed for case-insensitive comparisons.

### 3.5 `entity_mentions`
```sql
CREATE TABLE entity_mentions (
    entity_id UUID NOT NULL REFERENCES entities(entity_id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES source_documents(document_id) ON DELETE CASCADE,
    span_start INTEGER NULL,
    span_end INTEGER NULL,
    sentence TEXT NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (entity_id, document_id, span_start)
);
CREATE INDEX idx_entity_mentions_document ON entity_mentions (document_id);
```

### 3.6 `indicators`
```sql
CREATE TABLE indicators (
    indicator_id UUID PRIMARY KEY,
    case_id TEXT NOT NULL REFERENCES cases(case_id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    item TEXT NULL,
    type TEXT NOT NULL,
    number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    confidence NUMERIC(5,4) NOT NULL DEFAULT 0.0,
    first_seen_at TIMESTAMPTZ NULL,
    last_seen_at TIMESTAMPTZ NULL,
    dataset TEXT NOT NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_indicators_dataset_category_number UNIQUE (dataset, category, number)
);
CREATE INDEX idx_indicators_category_number ON indicators (category, number);
CREATE INDEX idx_indicators_case_id ON indicators (case_id);
CREATE INDEX idx_indicators_last_seen_at ON indicators (last_seen_at DESC);
```

### 3.7 `indicator_sources`
```sql
CREATE TABLE indicator_sources (
    indicator_id UUID NOT NULL REFERENCES indicators(indicator_id) ON DELETE CASCADE,
    document_id UUID NOT NULL REFERENCES source_documents(document_id) ON DELETE CASCADE,
    entity_id UUID NULL REFERENCES entities(entity_id) ON DELETE SET NULL,
    evidence_score NUMERIC(5,4) NULL,
    explanation TEXT NULL,
    metadata JSONB NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (indicator_id, document_id)
);
CREATE INDEX idx_indicator_sources_document ON indicator_sources (document_id);
```

## 4. Migration Strategy
1. **Tooling**: Adopt Alembic under `src/i4g/migrations` (new package) with env configured to read `i4g.settings.get_settings()` for SQLite path / Postgres DSN. `poetry run alembic revision --autogenerate` is acceptable once base metadata exists.
2. **Order of operations**: create tables in dependency order (ingestion_runs → cases → documents/entities/indicators → join tables). Wrap each migration in a transaction.
3. **Local workflow**:
   - `poetry run alembic upgrade head` applies migrations to SQLite.
   - `scripts/bootstrap_local_sandbox.py --apply-migrations` invokes the same command before seeding bundles.
4. **Cloud workflow**:
   - Use Cloud SQL Proxy (or private IP) plus `ALEMBIC_DATABASE_URL=postgresql+psycopg://...` to run `poetry run alembic upgrade head` from CI/CD.
   - Terraform adds a `null_resource.run_migrations` placeholder referencing a shell script (`scripts/migrations/apply_cloud_sql.sh`) to ensure infra deploys bring databases forward.
5. **Rollback**: each migration file includes a `downgrade()` that drops objects in reverse order and reinstates previous constraints. Operators execute `poetry run alembic downgrade -1` if a deploy must be reverted.
6. **Data backfill**: once schema exists, run `python scripts/bootstrap_local_sandbox.py --reset --apply-migrations` locally and `i4g-ingest-job --fanout` in dev to populate baseline data before enabling Milestone 3 features.

## 5. Validation Checklist
- `alembic upgrade head` succeeds on both SQLite and Postgres containers inside CI.
- `pytest tests/unit/services/test_account_list_retriever.py` still passes using the migrated schema (structured store adapts to new tables once implemented).
- Manual smoke: run ingestion job against `data/bundles/account_list_smoke.jsonl`, verify counts in `ingestion_runs`, `cases`, `indicators` tables, and ensure `indicator_sources` rows match document IDs.
- Document schema diagrams + commands inside `docs/design/architecture.md` and `docs/cookbooks/smoke_test.md` after the migrations ship.

## 6. Outstanding Tasks
- Scaffold Alembic config + base metadata.
- Update `i4g.store.structured` to point to the new schema (either via ORM or raw SQL helpers).
- Extend `scripts/bootstrap_local_sandbox.py` with a migration step + data verification.
- Add unit tests under `tests/unit/store/test_migrations.py` to cover idempotent upgrade/downgrade sequences.
