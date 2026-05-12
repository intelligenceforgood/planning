# Planning — Repo Context

> **For the Antigravity Agent:** Auto-read this file when working in the `planning/` repo.

## Purpose

This repo contains planning documents: PRDs, roadmaps, sprint task plans, and the running change log. It is Markdown only — no application code is written here.

## Structure

```
planning/
├── change_log.md           # Running log of all significant changes
├── roadmap.md              # Product roadmap
├── proposals/              # PRDs and feature proposals
├── tasks/                  # Sprint task plans with checkboxes
└── architecture/           # Architecture decision records
```

## Conventions

- **Task files** in `tasks/` use `- [ ]` / `- [x]` checkboxes. Check off tasks immediately when completed.
- **Change log** format: `## YYYY-MM-DD — <title>` followed by bullet points. Append entries at the bottom.
- **PRDs** in `proposals/` follow the pattern in existing files: Problem → Solution → Phases → Risks.
- Markdown: present tense, active voice, second person ("you"). Lines ≤ 120 chars.
- Do NOT write application code in this repo.
