# Planning (Active Guidance Only)

[![Docs](https://img.shields.io/badge/Docs-Planning%20Hub-blue.svg)](README.md)
[![Roadmap](https://img.shields.io/badge/Artifacts-PRDs%20%2B%20Roadmap-informational.svg)](roadmap.md)

This folder now holds the minimal planning artifacts needed to steer ongoing and future design/development. The goal is
to keep collaboration fast and unambiguous: engineers and designers should be able to pick up context quickly, make
decisions with confidence, and keep execution aligned.

## What Stays Here
- **PRDs** and **roadmap** for future development.
- **Current change log** (trimmed) that captures decisions still relevant to upcoming work.
- **Copilot prompts** under `copilot_prompt/`; these must be read and used efficiently before starting tasks.

## How We Work
- Copilot is a first-class collaborator. Keep prompts up to date, rehydrate sessions via `copilot_prompt/persistent_prompt.md`,
	and record state in `copilot_prompt/COPILOT_SESSION.md` when pausing work.
- When plans change, update the PRDs/roadmap and add a concise entry to `change_log.md` so future contributors inherit
	the latest intent without digging through archives.
- Anything no longer actionable lives in `planning/archive/` to keep the active surface small and trustworthy.
