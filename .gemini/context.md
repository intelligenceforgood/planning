# Gemini Code Assist Context for i4g/planning

**Unified Workspace Context:** This repository is part of the unified `i4g` parent workspace. Shared coding standards, routines, and platform context live in the `gemini` repo's styles directory (symlinked at the parent root). GCA will implicitly apply this file's context whenever you work within the `planning/` directory.

## GCA Framework & Workflows

- **Agent Mode Management:** Keep Agent Mode **OFF** for standard queries, isolated code reviews, and planning to conserve quota. Toggle **ON** strictly for autonomous multi-file execution or terminal tasks.
- **Standardized Prompts:** Use the standard VSCode snippets (`gca-plan`, `gca-prd`, `gca-impl`, `gca-work`) to trigger routine workflows.
- **Global Standards:** Broad coding conventions are referenced from `.gemini/styles/` (symlinked to the `gemini` repository).

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
