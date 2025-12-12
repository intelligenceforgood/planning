# Proposed Repo Structure for Mobile

Goal: mirror existing top-level repos (`core`, `infra`, `ui`, `docs`) while isolating platform-specific build systems.

```
mobile/
  ios/
    App/
      Sources/
      Tests/
      UI/
      Networking/
      Auth/
      Resources/
    Tools/
      fastlane/
      scripts/
    Config/
      Environments/ (dev.json, prod.json without secrets)
  android/
    app/
      src/
        main/
        androidTest/
        test/
    buildSrc/ (dependency versions)
    config/
      environments/ (dev.properties, prod.properties)
  shared/
    design-tokens/ (generated from existing `ui/` tokens or JSON export)
    api-schemas/ (OpenAPI or typed models matching FastAPI/Next.js contracts)
  docs/
    prd.md
    tdd.md
    roadmap.md
```

**Notes**
- Keep mobile in its own top-level repo (`mobile/`) or as a sibling to `ui/`. If monorepo is preferred, place `mobile/` at root alongside `ui/` and share CI workflows.
- Avoid duplicating secrets; use `.env.local` style for local dev, but fetch runtime config from secure storage or build-time env injection.
- Generate design tokens from the same source used by `ui/` to ensure brand parity.
