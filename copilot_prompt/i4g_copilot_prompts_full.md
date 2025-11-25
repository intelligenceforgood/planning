# i4g Copilot Chat Prompt Pack (ChatGPT-5.1-CODEX)

This file contains **backend-focused prompts** tailored to your i4g architecture:

- FastAPI 0.104+ (async)
- Python 3.11
- Firestore (google-cloud-firestore)
- Cloud Run deployment
- LangChain-based RAG
- PII tokenization / zero-trust model

All prompts are designed for **GitHub Copilot Chat in VS Code**, with **model = ChatGPT-5.1-CODEX** selected.

---

## Table of Contents

- [General Meta Prompt](#general-meta-prompt)
- [Backend](#backend)
  - [B1: New FastAPI Endpoint (CRUD + Firestore)](#b1-new-fastapi-endpoint-crud--firestore)
  - [B2: Extend Existing Endpoint](#b2-extend-existing-endpoint)
  - [B3: Error Handling + Logging](#b3-error-handling--logging)
  - [B4: Firestore Integration Patterns](#b4-firestore-integration-patterns)
  - [B5: PII / Tokenization Safety](#b5-pii--tokenization-safety)
  - [B6: LangChain / RAG Integration](#b6-langchain--rag-integration)
  - [B7: Background Work / Async Patterns](#b7-background-work--async-patterns)
  - [B8: Unit Tests for Endpoints](#b8-unit-tests-for-endpoints)
  - [B9: Integration / API Tests](#b9-integration--api-tests)
  - [B10: Service Layer Refactors](#b10-service-layer-refactors)
  - [B11: Security / Auth Review](#b11-security--auth-review)
  - [B12: Data Migration / Maintenance Scripts](#b12-data-migration--maintenance-scripts)

> **Repo structure assumption (Option A):**
> - `src/i4g/api/`
> - `src/i4g/models/`
> - `src/i4g/services/`
> - `src/i4g/rag/`
> - `src/i4g/utils/`

---

## General Meta Prompt

Use this at the **start of a Copilot Chat session** to anchor it on your architecture and expectations:

```text
You are my coding assistant working on the i4g project.

Architecture:
- Backend: FastAPI 0.104+, Python 3.11
- Data: Firestore (google-cloud-firestore), Cloud Storage
- LLM / RAG: LangChain in src/i4g/rag/, Ollama + remote providers
- Repo layout: src/i4g/api/, src/i4g/models/, src/i4g/services/, src/i4g/utils/

Ground rules:
- Never invent new top-level folders. Use existing layout.
- Prefer small, reviewable changes.
- Preserve PII / zero-trust guarantees. Raw PII must stay in the token vault.
- Match existing typing, logging, and error-handling style.
- When unsure about a function or module, ASK me which file to open instead of hallucinating it.

When I ask you to create or modify backend code, follow these rules automatically.
```

---

## Backend

<details>
<summary><strong>B1: New FastAPI Endpoint (CRUD + Firestore)</strong></summary>

### B1.1 – Create a New CRUD Endpoint for a Resource

```text
Create a new FastAPI endpoint for managing "{resource_name}" in the i4g backend.

Requirements:
- Place the router in: src/i4g/api/{resource_name}.py
- Use APIRouter with a /{resource_name} prefix.
- Define Pydantic models in src/i4g/models/{resource_name}.py:
  - {ResourceName}Create
  - {ResourceName}Update
  - {ResourceName}Read
- Implement Firestore persistence in src/i4g/services/{resource_name}_service.py using google-cloud-firestore async client.
- Include basic CRUD:
  - POST /{resource_name}           -> create
  - GET /{resource_name}/{id}       -> read
  - PATCH /{resource_name}/{id}     -> update
  - DELETE /{resource_name}/{id}    -> soft delete (mark as inactive)

Constraints:
- Reuse existing Firestore client utilities if they exist (e.g., in src/i4g/utils/db.py).
- Use async/await consistently.
- Use HTTPException with appropriate status codes.
- Add structured logging (info on success, warning on not found, error on failures).
- Ensure functions are fully typed.

First:
1. Show me the proposed file-level structure (router, models, services).
2. Then generate the code for models, service, and router in that order.
```

### B1.2 – Endpoint with Query Parameters and Pagination

```text
Extend the {resource_name} API to support querying with filters and pagination.

Requirements:
- Add GET /{resource_name} endpoint in src/i4g/api/{resource_name}.py:
  - query params:
    - status: Optional[str]
    - limit: int = 20
    - cursor: Optional[str] for pagination tokens
- Implement Firestore query logic in the service layer:
  - Support filtering by status if provided.
  - Implement simple cursor-based pagination using Firestore document snapshots.
- Return a response model with:
  - items: list[{ResourceName}Read]
  - next_cursor: Optional[str]

Constraints:
- Use async Firestore API.
- Reuse any existing pagination helpers if present in src/i4g/utils.
- Preserve existing auth and logging patterns.
- Do not break existing consumers of the API.

Walk through:
1. Propose the response model in models/{resource_name}.py.
2. Update the service.
3. Update the router.
4. Show me a final example JSON response.
```

</details>

---

<details>
<summary><strong>B2: Extend Existing Endpoint</strong></summary>

### B2.1 – Add a New Field to an Existing Resource

```text
We need to add a new field "{field_name}: {field_type}" to the existing resource "{resource_name}".

Tasks:
- Update Pydantic models in src/i4g/models/{resource_name}.py:
  - Include the new field in Create, Update, and Read models as appropriate.
- Update default values or migration behavior so old documents without this field still load correctly.
- Update the Firestore service in src/i4g/services/{resource_name}_service.py to:
  - Write the new field on create/update.
  - Handle missing fields when reading older documents.
- Update any related FastAPI responses in src/i4g/api/{resource_name}.py.

Constraints:
- Maintain backward compatibility: do not break existing API consumers.
- Ensure the new field is included in OpenAPI docs correctly.
- Add at least one unit test that covers the new field’s behavior (defaulting or optional handling).

Plan first:
1. Show me the diff you plan to make in each file (high-level).
2. Then generate the concrete code changes.
```

### B2.2 – Add Filtering / Sorting to an Existing List Endpoint

```text
Improve the GET /{resource_name} list endpoint to support filtering and sorting.

Requirements:
- Support query params:
  - sort_by: Optional[str] in {"created_at", "updated_at"}
  - sort_order: Optional[str] in {"asc", "desc"}
  - filters like status, analyst_id, etc. (use what is already present in the model)
- Implement the logic in the service layer to:
  - Use appropriate Firestore composite indexes (assume they exist or add comments indicating needed indexes).
  - Avoid loading entire collections into memory.

Constraints:
- Keep the function async.
- Preserve existing behavior as default (no filters -> current behavior).
- Log the filter/sort options for debugging.

Generate:
1. Updated endpoint signature in api/{resource_name}.py.
2. Updated service method.
3. Any necessary model changes (e.g., request DTO).
4. A short docstring describing the new behavior.
```

</details>

---

<details>
<summary><strong>B3: Error Handling & Logging</strong></summary>

### B3.1 – Standardize Error Handling for a Router

```text
Standardize error handling for the router in src/i4g/api/{resource_name}.py.

Goals:
- Replace ad-hoc try/except blocks with:
  - Specific exception types in the service layer.
  - Centralized translation to HTTPException in the router.
- Ensure all errors return:
  - JSON with fields: {"detail": "...", "error_code": "..."}
- Include structured logging for:
  - Validation errors
  - Not-found errors
  - Internal server errors

Tasks:
1. Propose a small set of custom exceptions in src/i4g/services/errors.py or similar.
2. Refactor the {resource_name} service to raise those exceptions.
3. Refactor the router to map each exception type to the correct HTTP status + error_code.
4. Add logging calls in both service (warn/error) and router (info/warn for responses).

Do this incrementally and show diffs per file.
```

### B3.2 – Add Request/Response Logging Middleware

```text
Add an ASGI middleware in the FastAPI app that logs request and response metadata WITHOUT logging sensitive PII.

Requirements:
- Create middleware in src/i4g/utils/middleware.py (or similar).
- Log:
  - method, path, status_code, duration_ms, user_id (if available from JWT), correlation_id.
- Do NOT log full request/response bodies.
- Attach correlation_id to request state if not present.
- Register the middleware in the main FastAPI app factory.

Generate:
1. The middleware implementation.
2. The wiring code in the FastAPI app init (where the app is created).
3. A short explanation of how this avoids PII leakage.
```

</details>

---

<details>
<summary><strong>B4: Firestore Integration Patterns</strong></summary>

### B4.1 – Create Firestore Repository Helper

```text
Create a reusable Firestore repository helper for i4g.

Requirements:
- New module: src/i4g/utils/firestore_repo.py
- Provide a generic async repository class with methods:
  - get(doc_id: str)
  - create(data: dict)
  - update(doc_id: str, data: dict)
  - soft_delete(doc_id: str)
  - query_by_field(field: str, value: Any, limit: int = 50)
- Use google-cloud-firestore async client.
- Support collection name injection via constructor or subclassing.

Then:
- Refactor one existing service (e.g., cases, analysts) in src/i4g/services/ to use this helper instead of inline Firestore calls.
- Ensure behavior remains identical (same document structure and field names).

Provide:
1. The helper implementation.
2. The refactored service code.
3. Notes on how to migrate other services later.
```

### B4.2 – Firestore Transaction Pattern

```text
Implement a Firestore transaction pattern to update a case and its audit log atomically.

Requirements:
- Identify or create a service function in src/i4g/services/case_service.py:
  - update_case_with_audit(case_id: str, payload: CaseUpdate)
- Inside, perform a Firestore transaction that:
  - Updates the case document.
  - Appends an entry to an "audit_log" subcollection or audit collection.
- Handle concurrent modification safely (e.g., via transaction retries or version fields if used).

Constraints:
- Use async transaction pattern supported by google-cloud-firestore.
- Preserve existing field naming conventions.
- Add structured logging for transaction start/success/failure.

Generate the function and any helper utilities required.
```

</details>

---

<details>
<summary><strong>B5: PII / Tokenization Safety</strong></summary>

### B5.1 – Safe PII Flow Audit for an Endpoint

```text
Audit the PII handling for the endpoint in src/i4g/api/{resource_name}.py.

Goals:
- Ensure no raw PII is returned to the client.
- Ensure all PII fields are:
  - Tokenized via the PII vault service.
  - Stored encrypted if needed.
- Confirm that logs do NOT contain raw PII.

Tasks:
1. Identify where PII enters the system in this endpoint.
2. Identify how it is persisted (which Firestore collections / fields).
3. Propose concrete code changes to:
   - Use the PII vault/tokenization service.
   - Mask PII in responses.
   - Avoid logging sensitive fields.
4. Generate the patches (code changes) to enforce this.

Explain each change you propose in one sentence.
```

### B5.2 – Add PII-Masking Utility and Apply It

```text
Create a PII-masking utility and apply it across selected endpoints.

Requirements:
- New helper: src/i4g/utils/pii_masking.py
  - Provide functions like:
    - mask_email(...)
    - mask_phone(...)
    - mask_generic(value: str) -> str
- Use simple masking strategies (e.g., keep first/last 2 characters).
- Update endpoints in src/i4g/api/cases.py and src/i4g/api/reviews.py to:
  - Mask PII in responses shown to analysts.
  - Keep internal logs PII-free.

Constraints:
- Do not change the underlying stored values, only response payloads.
- Keep the API contract stable where possible (same field names, masked values).
- Add or update at least one unit test per modified endpoint to verify masking.

Proceed file by file and show diffs.
```

</details>

---

<details>
<summary><strong>B6: LangChain / RAG Integration</strong></summary>

### B6.1 – Attach RAG Classification to Case Creation

```text
Wire the LangChain RAG pipeline into the case creation flow.

Requirements:
- When a new case is created via src/i4g/api/cases.py:
  - After validation and persistence, call a LangChain chain in src/i4g/rag/classifier.py.
  - The chain should:
    - Embed relevant text.
    - Retrieve supporting documents.
    - Classify the scam type.
    - Return classification + confidence + supporting snippets.
- Store classification metadata on the case document (e.g., fields: scam_type, scam_confidence, rag_evidence_ids).

Constraints:
- Make the RAG call async and non-blocking for the main request if possible:
  - Either fire-and-forget with background task (FastAPI BackgroundTasks) or queue for later processing.
- Ensure failures in RAG do NOT break case creation:
  - Log and continue.

Generate:
1. Updated service function for case creation.
2. The RAG call integration code.
3. Any new Pydantic models for classification metadata.
```

### B6.2 – Add an Endpoint to Re-run Classification

```text
Add an endpoint to re-run scam classification for an existing case.

Requirements:
- New endpoint in src/i4g/api/cases.py:
  - POST /cases/{case_id}/reclassify
- Logic:
  - Fetch the case.
  - Call the LangChain classifier pipeline.
  - Update classification metadata on the case.
  - Return the new classification result.

Constraints:
- Reuse existing RAG chain from src/i4g/rag/classifier.py.
- Handle missing cases gracefully.
- Log the reclassification request, including who triggered it (from auth context).

Generate:
1. Pydantic response model.
2. Router handler.
3. Service layer function.
```

</details>

---

<details>
<summary><strong>B7: Background Work / Async Patterns</strong></summary>

### B7.1 – Background Task for Heavy Processing

```text
Move a heavy post-processing step (e.g., PDF analysis, multi-page embeddings) into a background task.

Requirements:
- Identify a candidate endpoint where the response is slow due to heavy work.
- Introduce a background task pattern using FastAPI BackgroundTasks OR a job queue abstraction if already present.
- Persist a "processing" status on the case.
- When the background work is done, update the case with results.

Constraints:
- Avoid introducing new infrastructure for now (Celery etc.) unless it already exists.
- Ensure that the synchronous part of the endpoint returns quickly.

Steps:
1. Propose which endpoint to refactor.
2. Show the new endpoint code with BackgroundTasks usage.
3. Show the background task function implementation in the appropriate module.
```

</details>

---

<details>
<summary><strong>B8: Unit Tests for Endpoints</strong></summary>

### B8.1 – Unit Tests for a New Resource

```text
Create unit tests for the {resource_name} router.

Requirements:
- New test module: tests/api/test_{resource_name}.py
- Use pytest and pytest-asyncio.
- Use httpx.AsyncClient or the existing test client factory.
- Mock Firestore and any external services (e.g., via monkeypatch or fixtures).
- Cover:
  - happy path for create/read/update/delete
  - validation error
  - not-found case

Constraints:
- Follow existing test utilities and patterns from the repo.
- Keep tests deterministic and independent.

Generate:
1. The full test file.
2. Any fixtures or helpers needed.
```

</details>

---

<details>
<summary><strong>B9: Integration / API Tests</strong></summary>

### B9.1 – End-to-End API Test for Case Lifecycle

```text
Add an end-to-end API test for a typical case lifecycle.

Requirements:
- New test module: tests/integration/test_case_lifecycle.py
- Flow:
  1. Create a case via POST /cases.
  2. Fetch it via GET /cases/{id}.
  3. Trigger classification or status change.
  4. Verify data in Firestore (or via API responses).
- Use a real Firestore emulator if the repo already has that wired up; otherwise, explain how to simulate.

Constraints:
- Do not hit production Firestore.
- Clean up any created documents (or use isolated collections).

Provide the full test file and a short note on how to run it.
```

</details>

---

<details>
<summary><strong>B10: Service Layer Refactors</strong></summary>

### B10.1 – Extract Business Logic from Router into Service

```text
Refactor src/i4g/api/{resource_name}.py to keep routers thin and move business logic into src/i4g/services/{resource_name}_service.py.

Steps:
1. Identify functions in the router that contain business logic (beyond simple parameter passing).
2. Create corresponding service functions with clear, typed signatures.
3. Replace inline logic in router handlers with calls to service functions.
4. Ensure no behavior change.

Constraints:
- Do not change API routes or schemas.
- Improve testability by making pure business functions easier to unit test.

Show me:
- Before/after example for one endpoint.
- Then apply the pattern to the rest.
```

</details>

---

<details>
<summary><strong>B11: Security / Auth Review</strong></summary>

### B11.1 – Review Auth Guards for a Router

```text
Review the auth and authorization checks for src/i4g/api/{resource_name}.py.

Goals:
- Ensure that:
  - All write operations require authenticated users.
  - Only allowed roles can perform sensitive operations (e.g., approval, deletion).
- Confirm that route dependencies are:
  - Correctly applied (e.g., get_current_user, require_analyst, require_leo).
  - Not accidentally bypassed.

Tasks:
1. List all endpoints in this router and their current auth dependencies.
2. Identify any gaps or inconsistencies.
3. Propose and implement changes to align with the intended security model.

Then generate a short markdown summary explaining the final access rules per endpoint.
```

</details>

---

<details>
<summary><strong>B12: Data Migration / Maintenance Scripts</strong></summary>

### B12.1 – One-Off Migration Script

```text
Create a one-off data migration script to normalize a field in Firestore documents.

Scenario:
- We have a collection "{collection_name}" where a field "{field_name}" has inconsistent formats.
- We want to:
  - Scan all documents.
  - Normalize the field to a canonical format.
  - Write back the updated value.
  - Log a summary.

Requirements:
- New script: scripts/migrate_{collection_name}_{field_name}.py
- Use google-cloud-firestore async client.
- Provide a dry-run mode and a real mode (CLI flag or environment variable).
- Print a summary at the end: total docs scanned, updated, skipped.

Constraints:
- Script must be idempotent.
- Handle failures gracefully (log and continue).

Generate the full script and add a short docstring at the top explaining how to run it.
```

</details>

---

_End of Backend (Batch 1) section for Copilot Chat prompt pack.
Frontend / Infra / CI/CD sections can be added as subsequent batches._


---

# Batch 2: Frontend + Infra + CI/CD Prompts

## Frontend (Next.js 15, React 19)

<details><summary><strong>F1: New Next.js Page</strong></summary>
```
Create a new page in src/app/{route}/page.tsx with server-side data fetch, UI-kit usage, and OAuth session check.
```
</details>

<details><summary><strong>F2: Client Component</strong></summary>
```
Build a client component with Suspense, shadcn/ui, and correct typing.
```
</details>

<details><summary><strong>F3: API Proxy Route</strong></summary>
```
Create server action route that proxies to FastAPI with secret-injected headers.
```
</details>

## Infra (GCP)

<details><summary><strong>I1: Cloud Run YAML</strong></summary>
```
Generate cloudrun.yaml with env vars, secrets, CPU/Memory tuning, min/max instances.
```
</details>

<details><summary><strong>I2: Firestore Indexes</strong></summary>
```
Create firestore.indexes.json entries for compound queries.
```
</details>

<details><summary><strong>I3: Secret Manager Integration</strong></summary>
```
Show how to load secrets from Secret Manager inside FastAPI at startup.
```
</details>

## CI/CD

<details><summary><strong>C1: GH Actions Pipeline</strong></summary>
```
Create workflow: lint, test, docker build, push to GAR, deploy to Cloud Run.
```
</details>

<details><summary><strong>C2: PR Validation Workflow</strong></summary>
```
Create PR workflow checking formatting, mypy, eslint, and unit tests.
```
</details>
