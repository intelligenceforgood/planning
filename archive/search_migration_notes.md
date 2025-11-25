- [x] Inspect recent discovery operations via Python helper (superseded by import script logging the LRO name):
  ```bash
  python - <<'PY'
  from google.cloud import discoveryengine_v1beta as discoveryengine

  client = discoveryengine.DocumentServiceClient()
  ops_client = client.transport.operations_client
  name = "projects/i4g-dev/locations/global/operations"

  for op in ops_client.list_operations(name=name, filter_=""):
      if "retrieval-poc" in op.name:
          print(op.name, op.done)
          break
  PY
  ```
# Azure Cognitive Search → Vertex AI Search Migration Notes

_Last updated: 15 Nov 2025_

This scratchpad captures index inventory, export checkpoints, and field mapping decisions while we migrate Azure Cognitive Search content into Vertex AI Search.

## 1. Index Inventory

| Index Name | Purpose / Dataset | Notes |
|---|---|---|
| groupsio-search | Groups.io message corpus | Exported 1000 documents → `data/search_exports/groupsio-search_documents.jsonl`; schema at `data/search_exports/groupsio-search_schema.json`. Uploaded to `gs://i4g-migration-artifacts-dev/search/20251114/groupsio-search_documents.jsonl`. |
| intake-form-search | Intake form submissions | Exported 505 documents → `data/search_exports/intake-form-search_documents.jsonl`; schema at `data/search_exports/intake-form-search_schema.json`. Uploaded to `gs://i4g-migration-artifacts-dev/search/20251114/intake-form-search_documents.jsonl`. |

Action items:
- [ ] Install the Azure Search CLI extension: `az extension add --name search`.
- [ ] Authenticate and select the subscription: `az login`, `az account list --output table`, `az account set --subscription "<subscription>"`.
- [ ] Display available search services: `az search service list --output table`.
- [ ] Inspect the target service for resource group + endpoint (`properties.endpoint`): `az search service show --name <service> --resource-group <rg>`.
- [ ] Run `az search index list --service-name <service> --resource-group <rg>` to confirm index names and document them in the table above.
- [ ] Capture per-index statistics (`documentCount`, storage size) with `az search index show` for sizing the GCP data store.

## 2. Export Artifacts

Command used:

```bash
python scripts/migration/azure_search_export.py \
  --endpoint "$AZURE_SEARCH_ENDPOINT" \
  --admin-key "$AZURE_SEARCH_ADMIN_KEY" \
  --output-dir data/search_exports/20251114
```

Artifacts:
- Schemas: `data/search_exports/<index>_schema.json`
- Documents: `data/search_exports/<index>_documents.jsonl`

- Next steps:
- [x] Upload the export directory to the shared GCS bucket (`gs://i4g-migration-artifacts-dev/search/20251114/`).
- [x] Verify document counts in each JSONL file match Azure `documentCount` values. `groupsio-search`: 1000, `intake-form-search`: 505 (339 attachment-only rows intentionally skipped during transform; 7 additional intake docs dropped during import due to empty text).
- [x] Run transformation helper: `python scripts/migration/azure_search_to_vertex.py --input-dir data/search_exports --output-dir data/search_exports/vertex`.
- [x] Copy Vertex-ready JSONL files to `gs://i4g-migration-artifacts-dev/search/20251114/vertex/`.
- [ ] Create Discovery Engine import manifest referencing uploaded Vertex files. (Not required for Python helper workflow; draft template before next CLI-driven import.)
- [x] Execute `python scripts/migration/import_vertex_documents.py --project i4g-dev --location global --data-store-id retrieval-poc --uris gs://i4g-migration-artifacts-dev/search/20251114/vertex/groupsio-search_vertex.jsonl gs://i4g-migration-artifacts-dev/search/20251114/vertex/intake-form-search_vertex.jsonl` to load documents. Script waits for the long-running operation to finish and logs the result.
- [x] Verify documents exist with `python - <<'PY'
from google.cloud import discoveryengine_v1beta as discoveryengine

client = discoveryengine.DocumentServiceClient()
parent = (
  "projects/i4g-dev/locations/global/"
  "collections/default_collection/dataStores/retrieval-poc/branches/default_branch"
)

for doc in client.list_documents(request={"parent": parent}):
  print(doc.id, doc.title)
  break
PY`
- Output 14 Nov 2025: `gift_card_shakedown-000`

## 3. Field Mapping & Transformations

For each index, document the target Vertex AI Search schema expectations:

| Azure Field | Type | Vertex Field | Transform | Notes |
|---|---|---|---|---|
| **groupsio-search** |  |  |  |  |
| subject | Edm.String | `content` + `title` | Prepend to `content`; also becomes `title` | Analyzer already handled prior to export. |
| body | Edm.String | `content` | Append to multiline `content` |  |
| content | Edm.String | `content` | Append if non-null | Rarely populated but preserved. |
| sender_name | Edm.String | `structData.sender_name` | Direct copy | Preserve original formatting. |
| sender_id | Edm.String | `structData.sender_id` | Direct copy | Mostly null. |
| group_name | Edm.String | `structData.group_name` | Direct copy | Used for filtering. |
| topic_id | Edm.String | `structData.topic_id` | Direct copy |  |
| timestamp | Edm.DateTimeOffset | `structData.timestamp` | Keep ISO-8601 string | Suitable for filter/sort. |
| source | Edm.String | `structData.source` | Direct copy | Values such as `groups_email`. |
| blob_urls | Edm.String | `structData.blob_urls` | Direct copy | Remains string of URL(s). |
| groupsio_message_id | Edm.String | `structData.groupsio_message_id` | Direct copy |  |
| **intake-form-search** |  |  |  |  |
| incident_details | Edm.String | `content` | Forms long text portion |  |
| additional_info | Edm.String | `content` | Append to `content` |  |
| criminal_bank_info | Edm.String | `content` | Append to `content` |  |
| money_send_method | Edm.String | `content` | Append to `content` |  |
| crypto_info | Edm.String | `content` | Append to `content` |  |
| apps_or_websites | Edm.String | `content` | Append to `content` |  |
| criminal_contacts | Edm.String | `content` | Append to `content` |  |
| criminal_address | Edm.String | `content` | Append to `content` |  |
| payment_handles | Edm.String | `content` | Append to `content` |  |
| content | Edm.String | `content` | Append if present | Usually null. |
| email | Edm.String | `structData.email` | Direct copy | Also used as `title` fallback. |
| first_name / last_name | Edm.String | `structData.first_name`, `structData.last_name` | Direct copy |  |
| country / city / state | Edm.String | Corresponding `structData` fields | Direct copy |  |
| reported_to_law | Edm.String | `structData.reported_to_law` | Direct copy |  |
| law_agencies | Edm.String | `structData.law_agencies` | Direct copy |  |
| timestamp | Edm.DateTimeOffset | `structData.timestamp` | Keep ISO-8601 string |  |
| blob_urls | Edm.String | `structData.blob_urls` | Direct copy |  |
| (Vertex title) | — | `title` | Pull from `email` when available |  |

Tasks:
- [x] Identify fields requiring flattening or restructuring to match Discovery Engine `structData` constraints.
- Current transformer emits flat string fields only (`email`, `group_name`, etc.) plus `content` text stored in both `content.rawBytes` and `structData.content`, so no additional reshaping required for MVP.
- 15 Nov 2025: Transformer now sets `structData.source` to the index name when Azure leaves it blank (e.g. intake forms get `source=intake-form-search`), giving us a lightweight dataset tag without touching Discovery Engine schema.
- [x] Determine how to regenerate embeddings (if Azure stored vector fields) using Vertex AI models or existing pipelines.
- MVP decision: rely on Discovery Engine's built-in semantic pipeline; revisit custom embedding generation (Vertex Embedding API vs. repurposing Azure vectors) after stakeholder feedback.

## 4. Import Planning

- [ ] Create dedicated Discovery Engine data stores per index or consolidate into a single store with `structData.index_type` field.
- MVP leaning: keep a single data store (`retrieval-poc`) and tag each document with `structData.index_type` so stakeholders can filter by dataset without fragmenting the store; revisit multiple stores if quotas or tuning requirements diverge later.
- [ ] Define GCS manifests for bulk import (`gs://i4g-migration-artifacts/search/20251114/<index>_documents.jsonl`).
- Manifest template (if CLI import becomes necessary):
  ```json
  {
    "gcsSource": {
      "inputUris": [
        "gs://i4g-migration-artifacts-dev/search/20251114/vertex/groupsio-search_vertex.jsonl",
        "gs://i4g-migration-artifacts-dev/search/20251114/vertex/intake-form-search_vertex.jsonl"
      ]
    }
  }
  ```
- [ ] Draft `gcloud discovery-engine data-stores documents import` commands and capture expected runtime.
- Candidate command mirroring the Python helper:
  ```bash
  gcloud discovery-engine data-stores documents import \
    --project=i4g-dev \
    --location=global \
    --data-store=retrieval-poc \
    --gcs-uri=gs://i4g-migration-artifacts-dev/search/20251114/vertex/groupsio-search_vertex.jsonl \
    --gcs-uri=gs://i4g-migration-artifacts-dev/search/20251114/vertex/intake-form-search_vertex.jsonl \
    --async
  ```
- Capture the operation name from the response, then poll with `gcloud discovery-engine operations describe` to track runtime when executed.
- Helper script now supports `--dry-run` to inspect the ImportDocumentsRequest without starting a new LRO.

## 5. Validation Checklist

- [x] Post-import `scripts/query_vertex_search.py` smoke test covering representative queries from each index.
- Query `wallet address`, 15 Nov 2025 (after hashed IDs + content fallback):
  ```bash
  /Users/jerry/miniforge3/envs/i4g/bin/python scripts/query_vertex_search.py \
    "wallet address" \
    --project i4g-dev \
    --location global \
    --data-store-id retrieval-poc \
    --page-size 3
  ```
  Returned `hash_59e42a19cd4568af71420034c6676b8d`, `hash_28bff17cee75c3d2db51b8d352d6a4e4`, `hash_ebcc5b30cf13655e57937a8d216a81c4` with snippet summaries showing wallet/IC3 complaint content.
- Discovery Engine count check, 14 Nov 2025:
  ```bash
  python - <<'PY'
  from google.cloud import discoveryengine_v1beta as discoveryengine

  client = discoveryengine.DocumentServiceClient()
  parent = (
      "projects/i4g-dev/locations/global/"
      "collections/default_collection/dataStores/retrieval-poc/branches/default_branch"
  )

    total = 0
    for doc in client.list_documents(request={"parent": parent}):
      total += 1
    print(f"Total Discovery Engine documents: {total}")
  PY
  ```
  Output 15 Nov 2025: `Total Discovery Engine documents: 1159`. Matches expected (1000 groupsio + 159 intake after dropping 339 attachment-only rows and 7 empty-text rows).
- Import error diagnostics, 14 Nov 2025:
  - Added `--error-prefix` support to `scripts/migration/import_vertex_documents.py` and reran import.
  - Error manifest at `gs://i4g-migration-artifacts-dev/search/20251114/import_errors/errors_00000000.json` showed every record rejected: `content` must be a structured object (`mimeType` + `structData`) rather than a raw string.
  - Updated `azure_search_to_vertex.py` to encode body text into `Document.content.rawBytes` (base64) while still copying a plain-text version plus title into `structData` so the GA API accepts the payload.
- 15 Nov 2025: Intake-form export contains ~339 attachment-only rows (every field null/empty) plus 7 submissions with no text content. Transformer currently skips them; document the omission or map the attachment URL into `structData` if we need them indexed.
- 15 Nov 2025: Added hashed IDs for documents whose Azure IDs exceed 128 chars (Discovery Engine limit). Original ID now saved in `structData.source_id`.
- 15 Nov 2025: Final import run → `success_count=1159`, `failure_count=0`, `total_count=1159` (input set excludes attachment-only and empty-text intake rows). Discovery Engine now holds all non-empty documents.
- 15 Nov 2025: Validation query:
  ```bash
  /Users/jerry/miniforge3/envs/i4g/bin/python scripts/query_vertex_search.py \
    "wallet address" \
    --project i4g-dev \
    --location global \
    --data-store-id retrieval-poc \
    --page-size 3
  ```
  Returned hashed document IDs with snippet summaries (e.g. `hash_59e42a19cd4568af71420034c6676b8d` showing wallet-address text), confirming content and searchability.
- [ ] Compare top results with Azure search responses for parity.
- [x] Record any ranking deviations and plan relevance tuning in Vertex AI Search.
- Manual spot checks (`wallet address`, `BEC mule`, `Chime account`) returned on-topic results in Vertex; no Azure baseline captured yet. Plan for MVP is to collect stakeholder feedback, log divergent rankings, and revisit tuning (boosting filters, synonyms) once shared queries arrive.

---

Update this file as exports complete and mappings solidify so the final migration runbook remains concise.
