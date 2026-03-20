# ADR-002: FastAPI + Pydantic v2 as Core API Framework

**Status:** ACCEPTED  
**Date:** 2025  
**Deciders:** CTO, Core tech lead

---

## Context

The I4G platform needed a Python web framework for the primary API. The prototype used ad-hoc scripts; the production rebuild required a choice that would scale with the team's needs: async support, strong typing, OpenAPI schema generation, and compatibility with the rest of the Python data/ML stack.

The team was also adopting Pydantic v2, which has significant performance and ergonomic improvements over v1, including the `alias_generator` pattern that eliminates manual camelCase/snake_case translation.

---

## Decision

**Use FastAPI as the web framework and Pydantic v2 as the data validation and serialization layer for `core-svc` and `ssi-svc`.**

Key conventions that follow from this choice:

- Internal Python code uses `snake_case` for all field names
- JSON API responses use `camelCase` via `alias_generator = to_camel` — no manual translation functions
- Dependency injection (`Depends()`) is used for auth, settings, and store access — no global singletons
- All pydantic models use `model_config = ConfigDict(...)` (v2 style) — no `class Config:` inner classes
- OpenAPI schema is auto-generated from the routers and available at `/docs` (disabled in prod)

---

## Alternatives Considered

| Alternative                 | Why Rejected                                                                                                                             |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Django REST Framework       | Too opinionated for a data-heavy service; ORM coupling reduces flexibility for multi-backend storage; async support weaker               |
| Flask                       | No native async; no built-in data validation; manual schema definition; not suitable for a 22-router API without significant scaffolding |
| aiohttp                     | Lower-level than needed; no dependency injection; no validation; more boilerplate                                                        |
| Starlette (without FastAPI) | FastAPI is essentially Starlette + Pydantic + OpenAPI generation; no reason to use the bare layer                                        |
| Pydantic v1                 | v2 is the current standard; v1 is in maintenance mode; v2 has 5-50x performance improvements for validation                              |

---

## Consequences

**Positive:**

- Auto-generated OpenAPI schema at `/docs` in dev/local — living API documentation
- Pydantic v2 `alias_generator` handles all camelCase serialization automatically
- `Depends()` makes auth, settings, and store injection testable without mocking globals
- Protocol familiarity: FastAPI is the most common Python async API framework — easy to hire for

**Negative / trade-offs:**

- Pydantic v2 serialize/deserialize semantics differ from v1 — be careful when reading old code or LLM suggestions that default to v1 patterns
- `model_validate()` vs `model_construct()` performance trade-off must be understood (validate for untrusted data, construct for internal records)
- The dependency injection pattern can become verbose for deeply nested dependencies

---

## Related Decisions

- ADR-001: GCP migration (chosen contemporaneously)
- SSI service also uses FastAPI + Pydantic v2 (same choice applied independently)
