# Gemini Model Migration Plan

> **Created**: February 23, 2026
> **Source**: [Google Vertex AI migration guide](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/migrate)
> **Status**: Planning
> **Priority**: High — earliest retirement date is **June 1, 2026**

---

## Context

Google announced deprecation timelines for current Gemini models on Vertex AI:

| Model                 | Retirement Date                  |
| --------------------- | -------------------------------- |
| Gemini 2.0 Flash      | June 1, 2026                     |
| Gemini 2.0 Flash-Lite | June 1, 2026                     |
| Gemini 2.5 Pro        | June 17, 2026                    |
| Gemini 2.5 Flash      | June 17, 2026                    |
| Gemini 2.5 Flash-Lite | July 22, 2026                    |
| Gemini 3 Flash        | Preview (no retirement date yet) |
| Gemini 3 Pro          | Preview (no retirement date yet) |
| Gemini 3.1 Pro        | Preview (no retirement date yet) |

Google also advises migrating from the **Vertex AI SDK** (`google-cloud-aiplatform` / `vertexai`) to the **Gen AI SDK** (`google-genai`). Vertex AI SDK releases after June 2026 will no longer support Gemini models.

---

## Current State (Audit Summary)

| Concern             | Core (`i4g`)                        | SSI                                     | AWH          |
| ------------------- | ----------------------------------- | --------------------------------------- | ------------ |
| Active Gemini model | `gemini-2.5-flash` (retires Jun 17) | `gemini-2.0-flash` (retires Jun 1)      | N/A (Claude) |
| SDK                 | `google-cloud-aiplatform` (old)     | `google-genai` (new) — already migrated | `anthropic`  |
| Provider name       | `vertex_ai`                         | `gemini`                                | N/A          |
| Model configurable? | Yes (`I4G_LLM__CHAT_MODEL`)         | Yes (`SSI_LLM__MODEL`)                  | N/A          |

**Key risks:**

1. **SSI hits the wall first** — `gemini-2.0-flash` retires June 1, 2026 (~14 weeks).
2. **Core SDK is deprecated** — `vertexai.generative_models` imports in `client.py` and `classifier.py` will stop working for Gemini post-June 2026.
3. **Hardcoded model strings** — `gemini-2.0-flash` default in `GeminiProvider.__init__`, `gemini-2.5-flash` in Core bootstrap jobs CLI, cost table entries in SSI monitoring.

---

## Task List

### Phase 1: Immediate — Choose Target Models (week 1)

- [ ] **1.1** — Decide target model for each repo. Recommended candidates:
  - **SSI**: `gemini-2.5-flash` (GA, function calling, medium latency, context caching) or `gemini-3-flash` once GA
  - **Core**: `gemini-2.5-flash` → `gemini-3-flash` (when GA), or stay on 2.5 Flash until Jul 22 deadline
- [ ] **1.2** — Review pricing changes — newer models use token-based pricing; compare cost per 1M tokens against current spend
- [ ] **1.3** — Check region availability for target models in `us-central1` (our `gcp_location`)

### Phase 2: SDK Migration — Core (weeks 1–2)

Core still uses the deprecated `vertexai.generative_models` SDK. This is the **largest code change**.

- [ ] **2.1** — Replace `google-cloud-aiplatform` dependency with `google-genai` in `core/pyproject.toml`
  - Current: `google-cloud-aiplatform>=1.70.0,<3.0`
  - Target: `google-genai>=1.0.0,<2.0` (aligned with SSI)
- [ ] **2.2** — Rewrite `src/i4g/llm/client.py`:
  - Replace `import vertexai; from vertexai.generative_models import GenerativeModel` with `from google import genai`
  - Update `VertexAIClient.generate()` to use `genai.Client(vertexai=True).models.generate_content()`
  - Update `_VertexLangChainAdapter` wrapping to work with new SDK
  - Remove legacy `_resolve_model_name()` shim for `vertex_ai_model`
- [ ] **2.3** — Rewrite `src/i4g/services/classifier.py`:
  - Replace `vertexai.init()` + `GenerativeModel()` with `genai.Client(vertexai=True)`
- [ ] **2.4** — Update `core/requirements.txt` — regenerate pinned deps after dependency swap
- [ ] **2.5** — Run full unit test suite (`pytest tests/unit`) — fix any breaking imports or mocks
- [ ] **2.6** — Update LLM settings section — consider renaming provider from `vertex_ai` to `gemini` for consistency with SSI (coordinate with env var docs)

### Phase 3: Model String Updates (week 2)

- [ ] **3.1** — **SSI**: Update default model from `gemini-2.0-flash` to target model
  - `src/ssi/llm/gemini_provider.py` — `__init__` default parameter
  - `config/settings.dev.toml` — `model` value
  - `tests/unit/test_settings.py` — expected model assertions
- [ ] **3.2** — **SSI**: Update cost table in `src/ssi/monitoring/__init__.py` — add pricing for new model, keep old entries for historical cost tracking
- [ ] **3.3** — **Core**: Update hardcoded `gemini-2.5-flash` in `src/i4g/cli/bootstrap/dev/jobs.py` — use settings or bump to target model
- [ ] **3.4** — **Core**: Update test fixtures referencing `gemini-pro`, `gemini-2.5-flash` in `tests/unit/llm/test_client.py`
- [ ] **3.5** — Update all TOML config files and env var documentation with new model defaults

### Phase 4: Handle Breaking Changes (week 2)

Review Google's list of breaking changes for Gemini 3.x (if targeting 3.x):

- [ ] **4.1** — **Top-K removal**: Audit codebase for `top_k` parameter usage — remove or switch to `top_p` equivalent
- [ ] **4.2** — **Thinking parameter**: If using `thinking_budget`, switch to `thinking_level` for Gemini 3 Pro+
- [ ] **4.3** — **Thought signatures**: Ensure multi-turn conversations provide required thought signatures (Gemini 3 Pro+)
- [ ] **4.4** — **PDF processing**: If relying on OCR for scanned PDFs, note Gemini 3 Pro+ does not use OCR by default — may need explicit opt-in
- [ ] **4.5** — **Temperature**: Gemini 3 Pro+ recommends keeping temperature at default `1.0` — audit any custom temperature settings
- [ ] **4.6** — **Content filter defaults**: Review safety filter settings — defaults may have changed between model versions

### Phase 5: Testing & Evaluation (weeks 2–3)

- [ ] **5.1** — **Core**: Run unit tests with new SDK + model (`pytest tests/unit -q --tb=short`)
- [ ] **5.2** — **Core**: Run local dev smoke test with mock provider, then switch to `vertex_ai`/`gemini` provider
- [ ] **5.3** — **SSI**: Run full test suite (`pytest tests/unit tests/integration -q --tb=short`)
- [ ] **5.4** — **SSI**: Run local investigation against 5+ scam URLs with new model — compare report quality
- [ ] **5.5** — **Prompt regression**: Test key prompts (fraud classification, scam analysis, wallet extraction) — compare output quality against baseline
- [ ] **5.6** — Verify structured output / JSON mode still works as expected with new model
- [ ] **5.7** — Load test to validate throughput meets requirements (if applicable)

### Phase 6: Infrastructure & Config (week 3)

- [ ] **6.1** — Update Cloud Run Job environment variables in Terraform (`infra/environments/app/`) with new model names
- [ ] **6.2** — Update `docs/config/settings_manifest.json` with new model defaults and deprecation notes
- [ ] **6.3** — Update `docs/book/config/` pages if model names or provider names changed
- [ ] **6.4** — Update `core/config/settings.default.toml` commented examples with current model names
- [ ] **6.5** — Verify provisioned throughput / quota in `i4g-dev` GCP project for new model

### Phase 7: Deploy & Validate (week 3–4)

- [ ] **7.1** — Deploy updated Core API to `i4g-dev` Cloud Run — smoke test key endpoints
- [ ] **7.2** — Deploy updated SSI to `i4g-dev` Cloud Run — run batch investigation job
- [ ] **7.3** — Monitor for errors, latency changes, cost differences over 48h
- [ ] **7.4** — Deploy to `i4g-prod` after dev validation passes

### Phase 8: Cleanup (week 4)

- [ ] **8.1** — Remove legacy `vertex_ai_model` setting and `_resolve_model_name()` shim from Core
- [ ] **8.2** — Remove `google-cloud-aiplatform` from Core dependencies (if fully replaced by `google-genai`)
- [ ] **8.3** — Align provider naming: consider unifying Core and SSI to use `gemini` as provider value
- [ ] **8.4** — Update `planning/change_log.md` with migration summary

---

## Timeline Summary

| Week | Focus                                                          | Deadline Driver   |
| ---- | -------------------------------------------------------------- | ----------------- |
| 1    | Target model decision, start Core SDK migration                | —                 |
| 2    | Complete SDK migration, model string updates, breaking changes | —                 |
| 3    | Testing, infra updates, deploy to dev                          | —                 |
| 4    | Prod deploy, cleanup                                           | —                 |
| —    | **SSI hard deadline (gemini-2.0-flash)**                       | **June 1, 2026**  |
| —    | **Core deadline (gemini-2.5-flash)**                           | **June 17, 2026** |

---

## References

- [Migrate to the latest Gemini models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/migrate)
- [Vertex AI SDK → Gen AI SDK migration guide](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/deprecations/genai-vertexai-sdk)
- [Gemini model versions](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)
- [Gen AI SDK getting started notebook](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/sdk/intro_genai_sdk.ipynb)
