# Milestone 2 – Dual Extraction Schema Requirements

_Last updated: 29 Nov 2025_

## 1. Objectives
- Normalize extracted evidence so Firestore, Vertex AI Search, and SQL share a consistent entity/indicator contract.
- Support incremental backfills: every ingestion run must be traceable (idempotent replays, per-store retry signals).
- Keep the local developer story simple (SQLite migrations) while targeting Postgres/AlloyDB in cloud environments.
- Expose query patterns required by Milestone 3 hybrid retrieval (per-case rollups, indicator lookups, time slicing).

## 2. Data Model Overview
| Table | Purpose |
| --- | --- |
| `ingestion_runs` | Track every dual-extraction execution with dataset metadata and per-store write counters. |
| `cases` | Canonical case metadata (case_id, dataset, classification, status) shared by reviews + reports. |
| `source_documents` | Individual documents/attachments that fed the extractor. Multiple per case. |
| `entities` | Normalized people/organization/device entities lifted from the evidence. |
| `entity_mentions` | Denormalized link between entities and the documents/spans they came from. |
| `indicators` | Financial/technical indicators (bank, crypto, payments, IP, ASN, browser). |
| `indicator_sources` | Join table connecting indicators to the documents (and optional entities) that justify them. |

## 3. Table Requirements
### 3.1 `ingestion_runs`
- Columns: `run_id` (PK, UUID), `dataset` (text), `source_bundle` (text), `started_at`, `completed_at`, `status`, `case_count`, `entity_count`, `indicator_count`, `vector_enabled` (bool), `metadata` (JSONB).
- Index `started_at`, `status` for operational dashboards.
- Store per-store counters (`firestore_writes`, `vertex_writes`, `sql_writes`, `retry_count`).
- Foreign key target for `cases.ingestion_run_id`.

### 3.2 `cases`
- Columns: `case_id` (PK), `ingestion_run_id` (FK), `dataset`, `source_type` (enum: `ocr`, `email`, `chat`, etc.), `classification`, `confidence`, `detected_at`, `reported_at`, `raw_text_sha256`, `status`, `metadata` (JSONB), `created_at`, `updated_at`.
- Unique constraint on (`dataset`, `raw_text_sha256`) to prevent duplicate ingests when the same bundle is replayed.
- Indexes: `idx_cases_dataset_reported_at`, `idx_cases_classification`, `idx_cases_status`.
- Soft-delete column (`is_deleted` bool + `deleted_at`) to support redaction without cascading physical deletes.

### 3.3 `source_documents`
- Columns: `document_id` (PK, UUID), `case_id` (FK), `title`, `source_url`, `mime_type`, `text`, `text_sha256`, `excerpt`, `score`, `captured_at`, `metadata` (JSONB).
- Index `case_id` + `captured_at` for chronological assembly.
- Enforce `ON DELETE CASCADE` from `cases` → `source_documents`.
- Store up to 8 KB excerpt inline; full text can sit in `text` column (SQLite) or external storage path referenced by `metadata`.

### 3.4 `entities`
- Columns: `entity_id` (PK, UUID), `case_id` (FK), `entity_type` (enum), `canonical_value`, `raw_value`, `confidence`, `first_seen_at`, `last_seen_at`, `metadata` (JSONB).
- Unique constraint on (`case_id`, `entity_type`, `canonical_value`).
- Index `entity_type`, `canonical_value` (btree + trigram when supported) for exact + fuzzy lookups.

### 3.5 `entity_mentions`
- Columns: `entity_id` (FK), `document_id` (FK), `span_start`, `span_end`, `sentence`, `metadata` (JSONB).
- Composite PK (`entity_id`, `document_id`, `span_start`).
- Enables highlighting within the analyst console and Vertex doc enrichment.

### 3.6 `indicators`
- Columns: `indicator_id` (PK, UUID), `case_id` (FK), `category` (enum aligned with `IndicatorCategory`), `item` (bank/entity name), `type` (e.g., `iban`, `swift`, `wallet`), `number` (account/wallet string), `status`, `confidence`, `first_seen_at`, `last_seen_at`, `metadata` (JSONB).
- Unique constraint on (`category`, `number`) scoped by `dataset` to dedupe repeated sightings.
- Indexes: `idx_indicators_category_number`, `idx_indicators_case_id`, `idx_indicators_last_seen_at`.

### 3.7 `indicator_sources`
- Columns: `indicator_id` (FK), `document_id` (FK), `entity_id` (nullable FK), `evidence_score`, `explanation`, `metadata` (JSONB).
- Composite PK (`indicator_id`, `document_id`).
- Supports show-your-work features, letting analysts trace each indicator back to documents/entities.

## 4. Relationships & Access Patterns
- `cases` ←→ `source_documents`: 1:N, drives `/reviews/{id}` document lists.
- `cases` ←→ `entities`: 1:N, enabling case summaries and cross-case entity pivots.
- `cases` ←→ `indicators`: 1:N, enabling account list rollups and time-series dashboards.
- `indicators` ←→ `indicator_sources` ←→ `source_documents`: ensures Vertex doc payloads can embed `indicator_ids`, enabling hybrid filtering.
- Primary API queries to optimize:
  1. Fetch latest indicators for `categories` within a time window (account list worker).
  2. Pull complete case context (documents + entities + indicators) for analyst review.
  3. Backfill/verify ingestion runs (counts by store, failure modes).

## 5. Vertex AI Search Document Contract
- Every `source_document` row must translate into a Vertex document with the following fields: `doc_id` (string, matches SQL UUID), `case_id`, `dataset`, `classification`, `captured_at`, `categories` (list), `indicator_ids` (list of UUIDs), `entity_ids` (list), `text` (chunked body), `excerpt`, `score`, and `metadata` (JSON map mirroring SQL `metadata`).
- Vertex document IDs adopt the format `case/{case_id}/doc/{document_id}` to keep cross-store debugging simple and idempotent.
- Chunking rules: split `text` into ~1,000 token windows with 10% overlap; each chunk inherits the parent `document_id` plus a `chunk_index` so we can rebuild the full document if needed.
- Required filters: `dataset`, `classification`, `indicator_ids`, and `categories` must map to Vertex filterable fields to support hybrid retrieval queries in Milestone 3.
- Optional embeddings (from Gemini/Vertex) store under `embedding` vector field; when disabled locally we omit the field but keep the document schema identical so backfills remain compatible.

## 6. Firestore Projection Contract
- Store cases inside `cases/{case_id}` with subcollections `documents/{document_id}`, `entities/{entity_id}`, and `indicators/{indicator_id}` mirroring the SQL schema to simplify worker fan-out logic.
- Firestore documents carry minimal fields required by the analyst console: case summaries (`dataset`, `classification`, `confidence`, `status`, timestamps), document metadata (`title`, `excerpt`, `score`), indicator snapshots (`category`, `number`, `confidence`, `source_document_ids`).
- Each Firestore write must include `ingestion_run_id` and `source_bundle` so analysts can pivot by ingest batch when debugging.
- Avoid storing large blobs; documents reference Cloud Storage paths for raw attachments via `storage_uri` fields.
- Keep Firestore schema backwards compatible by versioning documents with `schema_version` (default `2` for dual extraction) and fall back to old readers when unspecified.

## 7. Migration & Environment Expectations
- Author canonical SQL migrations under `migrations/dual_extraction/*.sql` (or Alembic equivalent) with paired SQLite + Postgres compatibility notes.
- Provide bootstrap helper via `i4g bootstrap local reset` to apply migrations automatically for devs.
- Cloud SQL/AlloyDB migration scripts must be idempotent and runnable via CI/CD (Terraform null_resource or manual `psql`).
- Local default remains SQLite but schema should avoid Postgres-only datatypes; use `TEXT` + JSON where necessary.

## 8. Acceptance Criteria
1. Schema supports storing every field currently emitted by `FinancialIndicator` and `SourceDocument` without lossy mapping.
2. Re-ingesting the same bundle is idempotent (detected via `raw_text_sha256` + per-indicator uniqueness).
3. Querying indicators by `category` + `time range` returns results in <200 ms on dev data (target via appropriate indexes).
4. Every row across core tables carries `created_at`/`updated_at` timestamps for auditing.
5. Foreign keys enforce referential integrity; deleting a case cascades to dependent tables (except ingestion run stats).
6. Schema doc enumerates all enum values so backend + Vertex contract remain aligned.
7. Migration plan includes rollback guidance (drop objects in reverse order, guard production data via transactions).

## 9. Open Questions / Follow-Ups
- Confirm whether `entities` needs partitioning by dataset for analytics workloads (if yes, consider materialized views).
- Decide if `indicator_sources` should capture OCR bounding boxes for PDF evidence (impacts storage sizing).
- Validate whether we store the full document text in SQL or reference external blobs for large attachments (>64 KB).
- Determine if we mirror Firestore document IDs inside SQL to simplify cross-store debugging.
