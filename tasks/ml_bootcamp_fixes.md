# ML Bootcamp — Exercise Fix-Up Tasks

> **Source:** Bootcamp assessment (2025-03-25)
> **Goal:** Make all 9 exercises in `ml/docs/bootcamp/` fully functional for novice developers

---

## Tasks

- [x] **T1 — Bootcamp README.md:** Create `ml/docs/bootcamp/README.md` — numbered exercise index, prerequisites, progressive difficulty ordering (basics → advanced)
- [x] **T2 — Fix Exercise 2 (blocker):** Container interface mismatch — exercise uses env vars but `train.py` uses argparse + GCS paths
  - [x] T2a: Update `containers/train-xgboost/train.py` to support local file paths (detect `gs://` vs local)
  - [x] T2b: Rewrite `02-train-locally.md` — fix data format, docker run command, output file names
  - [x] T2c: Add Docker cleanup note (image pruning guidance)
- [x] **T3 — Fix Exercise 7 test path:** Change `tests/unit/serving/test_spam_prediction.py` → `tests/unit/test_spam_prediction.py` (flat layout)
- [x] **T4 — GCP access prereqs:** Add "requires GCP access" callout to exercises 01, 03, 04, 05, 06, 08, 09 with local fallback guidance

---

## Config Framework Note

Reviewed the TOML settings framework in core (`BaseSettings` + `TomlConfigSettingsSource`) and ssi (`BaseSettings` + manual merge).
The ML repo's `config.py` uses `BaseModel` with manual TOML merge + env var loop — simpler but less robust.

**For the training container specifically:** argparse is the right choice because Vertex AI passes parameters as
CLI args. The TOML settings framework is for platform-wide config (project_id, BigQuery dataset, GCS bucket),
not per-job training config. The exercise's original use of env vars was incorrect — the container has always
used argparse. The fix is to update the exercise, not change the config approach.
