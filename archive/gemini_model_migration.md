# Gemini Model Migration — Completed

> **Created**: 2026-02-23 | **Completed**: 2026-03-04 | **Duration**: ~36 hours of active work
> **Trigger**: Google Vertex AI Gemini model deprecation (earliest retirement: June 1, 2026)

---

## Summary

Migrated all Gemini model references from `gemini-2.0-flash` → `gemini-2.5-flash` across Core, SSI, and Infra. Replaced the deprecated Vertex AI SDK (`google-cloud-aiplatform` / `vertexai`) with the Gen AI SDK (`google-genai`) in Core. Removed legacy `vertex_ai_model` setting and `_resolve_model_name()` shim. Standardized provider name from `vertex_ai` → `gemini` in all infra config.

## Phases

| #   | Phase                       | Scope                                                                                                                                                                                                                                                                   |
| --- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Choose Target Models**    | Selected `gemini-2.5-flash` (GA) for both Core and SSI. Reviewed pricing impact (~2× input, ~4× output vs 2.0-flash, offset by implicit context caching).                                                                                                               |
| 2   | **SDK Migration — Core**    | Replaced `google-cloud-aiplatform` with `google-genai` in `pyproject.toml` + `requirements.txt`. Rewrote `client.py` (`_VertexLangChainAdapter` → `genai.Client`) and `classifier.py` (`VertexAIClient` → `genai.Client`). Added `gemini` as accepted provider synonym. |
| 3   | **Model String Updates**    | SSI: default model, `settings.dev.toml`, test assertions. Core: test fixtures. SSI monitoring cost table updated with `gemini-2.5-flash` pricing.                                                                                                                       |
| 4   | **Handle Breaking Changes** | Audited top-k, thinking, thought signatures, PDF processing, temperature, content filters. No action required for `gemini-2.5-flash` target. Flagged items for future Gemini 3 Pro+ migration.                                                                          |
| 5   | **Testing & Evaluation**    | Core: 884 passed, 3 skipped. SSI: 715 passed. Prompt regression structural check clean. JSON mode paths verified.                                                                                                                                                       |
| 6   | **Infrastructure & Config** | Updated `terraform.tfvars` (dev + prod) for Core and SSI services. Docs/manifests verified current.                                                                                                                                                                     |
| 7   | **Deploy & Validate**       | Manual rebuild, deploy to `i4g-dev` and `i4g-prod` Cloud Run. E2E tests and monitoring passed.                                                                                                                                                                          |
| 8   | **Cleanup**                 | Removed `_resolve_model_name()`, `vertex_ai_model` field, legacy overrides. Provider naming standardized to `gemini` in all tfvars. Docs updated.                                                                                                                       |

## Repos Touched

| Repo         | Commits                                        | Key Changes                                  |
| ------------ | ---------------------------------------------- | -------------------------------------------- |
| **core**     | `18cd4f3` (Phases 2–3) + uncommitted (Phase 8) | SDK migration, model strings, legacy removal |
| **ssi**      | `937e9a1` (Phase 3)                            | Model default + cost table                   |
| **infra**    | uncommitted (Phases 6, 8)                      | `terraform.tfvars` model + provider updates  |
| **docs**     | uncommitted (Phases 6, 8)                      | `settings_manifest`, `settings.md`           |
| **planning** | uncommitted                                    | `change_log.md`, task file                   |

## Final Test Results

- **Core**: 881 passed, 3 skipped, 0 failures (3 fewer than pre-Phase-8 — removed `TestResolveModelName`)
- **SSI**: 715 passed, 0 failures
- **Pre-commit (Core)**: Clean double-pass — all hooks passed
