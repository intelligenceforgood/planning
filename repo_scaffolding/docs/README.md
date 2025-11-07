# Intelligence for Good — Documentation Site

This repository will host the public-facing documentation for the Intelligence for Good platform.

## Proposed Stack
- Static site generator: MkDocs (Material theme) or Docusaurus (React).
- Deployment: GitHub Pages or Cloud Run + Cloud CDN.
- Content sources: Planning artifacts, architecture overviews, API references, onboarding guides.

## Getting Started
1. Choose the documentation stack (decision tracked in `planning/doc_site_option.md`).
2. Generate the starter project (e.g., `mkdocs new .` or `npx create-docusaurus@latest`).
3. Configure GitHub Actions for build + deploy.
4. Add site structure: Getting Started, Architecture, API, Operations, Contributing, FAQ.

## Contribution Guidelines
- Follow the main project Code of Conduct.
- Use pull requests for all changes; include screenshots for UI updates.
- Keep content accessible and volunteer-friendly.

## Related Repositories
- `intelligenceforgood/i4g` — production application code.
- `intelligenceforgood/infra` — infrastructure-as-code.
- `intelligenceforgood/proto` — experiments.
