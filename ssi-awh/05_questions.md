# Questions & Decisions Log

> Questions from the SSI + AWH consolidation analysis, with resolved decisions.
> Resolved on 2026-02-20. See `06_flexible_scan_research.md` and `07_gemini_vision_research.md` for supporting research.

---

## Context

- **GCP nonprofit org** — considerable free quota on Vertex AI, Cloud Run, GCS, Cloud SQL
- **Premium DECODO account** — residential proxy costs are covered

---

## Critical Decisions

### Q1: PDF Slides Data Requirements — RESOLVED

**Answer:** The PDF covers eCX (eCrime eXchange) API endpoints for threat data:

| Endpoint           | Description                                                  | Volume                   |
| ------------------ | ------------------------------------------------------------ | ------------------------ |
| `/phish`           | Phishing URLs with confidence scores and brand tags          | Tens of thousands/month  |
| `/report_phishing` | Reported phishing emails including content, images, headers  | Hundreds of thousands/mo |
| `/mal_ip`          | IPs observed in malicious activity (fraud, logins, scanning) | —                        |
| `/mal_domain`      | Suspected/known malicious domains (fake stores, fraud sites) | —                        |
| `/crypto`          | Problematic virtual currency addresses for tracking          | —                        |
| `/malicious-sms`   | SMS/text phishing records                                    | —                        |

**Impact on merged product:** The eCX feeds are a **upstream data source** for SSI. The `/phish`, `/mal_domain`, and `/crypto` endpoints can feed URLs and wallet addresses into the investigation pipeline. The `/crypto` endpoint is directly relevant to wallet extraction — SSI-harvested wallets should be cross-referenced against eCX's known-bad wallet database. This will be designed as a future integration (post-Phase 8).

### Q2: OpenClaw Clarification — RESOLVED

**Answer:** The AWH developer hadn't integrated with OpenClaw — he was exploring how to build flexible scan workflows for sites that all interact differently. Rule-based templates cannot handle them all.

**Decision:** Research was conducted into flexible scan approaches. See `06_flexible_scan_research.md` for the full report. The recommended approach is a **four-tier cascade**:

1. **Playbook** ($0) — Deterministic scripts for known site templates
2. **DOM pre-scan** ($0) — AWH's three-tier DOM Inspector (≥75 direct, ≥40 assisted)
3. **Gemini Flash text** (~$0.0001/step) — DOM extraction → LLM action selection
4. **Gemini Flash vision** (~$0.0002/step) — Screenshot → LLM action selection (for overlays, dynamic UIs)
5. **Human guidance** ($0) — WebSocket-based human-in-the-loop as last resort

Target: **<$0.01 per full investigation** on GCP credits.

### Q3: Browser Engine Choice — RESOLVED

**Decision: Dual engine.**

- **zendriver** — active interaction (stealth matters)
- **Playwright** — passive capture (HAR, DOM snapshots, download interception)

Both share proxy configuration and stealth settings. Orchestrator selects engine by investigation phase.

### Q4: LLM Provider for Active Interaction — RESOLVED

**Decision: Hybrid approach (DOM pre-scan + vision fallback).**

Key update based on Q16 research: **Gemini 2.0 Flash replaces Claude as the primary vision model.** See `07_gemini_vision_research.md`. Claude is dropped from the critical path.

Provider matrix:

| Environment    | Text (DOM)         | Vision (screenshots) | Classification   |
| -------------- | ------------------ | -------------------- | ---------------- |
| **Local**      | Ollama (Llama 3.3) | Ollama (Gemma 3 12B) | Ollama           |
| **Dev/Prod**   | Gemini 2.0 Flash   | Gemini 2.0 Flash     | Gemini 2.0 Flash |
| **Escalation** | Gemini 2.5 Pro     | Gemini 2.5 Pro       | Gemini 2.5 Pro   |
| **Test**       | Mock               | Mock                 | Mock             |

### Q5: AWH Developer Involvement — RESOLVED

**Answer:** Available when needed, but limited bandwidth (volunteer, grad student, not in CS, no industry experience). Need a collaboration model that works for both.

**Decision:** Collaboration approach:

- Well-documented tasks with clear scope (no ambiguous stories)
- Pair review sessions rather than pair programming
- AWH developer focuses on what he knows: zendriver patterns, scam site behaviors, DOM detection heuristics
- Main developer handles architecture, integration, and SSI framework wiring

---

## Architecture Questions

### Q6: Repo Structure — RESOLVED

**Decision: Keep two repos (`core/` and `ssi/`), merge AWH into `ssi/`.** Direct inter-repo dependency is acceptable. The original `core`/`ssi` separation was a suggestion, not a hard requirement. If combining later makes sense, the team is open to it.

### Q7: Proxy Infrastructure — RESOLVED

**Decision: Decodo from day one.** Premium account is available, cost is covered. No need to defer or use alternatives.

### Q8: Investigation Concurrency — RESOLVED

**Decision: Sequential (one at a time) initially.** Note for later: Cloud Run jobs provide natural parallelism in dev/prod (each job is an independent container). Expanding concurrency is a deployment concern, not an architecture concern.

---

## Data & Integration Questions

### Q9: Core API Integration Mode — RESOLVED

**Decision: Direct DB access (option a).** Inter-repo coupling is acceptable per Q6. SSI uses `build_structured_store()` from core's factories, shares the same database connection.

### Q10: Wallet Allowlist Scope — RESOLVED

**Decision: Both (b) and (c) — expand the allowlist AND make it configurable.** Ship with an expanded default list, but load from a JSON config file so it can be updated without code changes.

### Q11: Historical AWH Data — RESOLVED

**Decision: Not a concern for now.** No migration needed.

---

## UI Questions

### Q12: SSI Page Auth — RESOLVED

**Answer:** A single protected page with a "quick scan" option is simpler than separate public/protected pages. Drop public access for now — the site and API are already protected. Can revisit public access later if needed.

**Decision:**

- Single `/ssi` page behind authentication (remove IAP exclusion)
- Quick scan toggle on the same page (passive-only mode)
- Deep investigation is the default full pipeline
- No separate "Quick Scan" vs "Deep Investigation" pages

### Q13: Playbook Management UI — RESOLVED

**Decision: Start with JSON files in repo (option a), add UI later (option c).** Playbooks as JSON in `config/playbooks/` directory.

---

## Scope & Priority Questions

### Q14: Phase Ordering — RESOLVED

**Decision: Keep the proposed ordering.** Phases 0–8 as documented in `04_roadmap.md`.

### Q15: AWH Repo Disposition — RESOLVED

**Decision: Defer.** Not a concern for now.

---

## Budget & Resource Questions

### Q16: LLM Budget — RESOLVED

**Answer:** GCP nonprofit credits cover Gemini costs. Claude is not required.

**Key findings from research** (see `07_gemini_vision_research.md`):

- **Gemini 2.0 Flash** handles screenshot-to-action tasks with ~90-95% accuracy vs Claude — the gap is small (5-10%)
- Native bounding box output solves AWH's CSS selector guessing problem
- Cost: ~$0.0002/step vs Claude's $0.007/step (35x cheaper)
- Full investigation: ~$0.005 vs $0.18 with Claude
- **Structured JSON output** is actually more reliable with Gemini (constrained decoding)
- **Ollama local dev**: Gemma 3 12B (closest to Gemini API), Qwen3-VL 8B (strongest open-source vision)

**Decision: Drop Claude dependency entirely.** Gemini 2.0 Flash is primary for both text and vision. Gemini 2.5 Pro reserved for escalation tier. Ollama with Gemma 3 / Qwen3-VL for local development.

### Q17: Volume Expectations — RESOLVED

**Decision: Not a concern for now.** GCP nonprofit credits and Decodo premium account cover anticipated usage. Sizing can be adjusted as patterns emerge.
