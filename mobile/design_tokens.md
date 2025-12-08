# Design Tokens for Mobile

Design tokens are the single source of truth for colors, typography, spacing, radius, and elevation used across platforms. We will **consume** the existing web tokens (in `ui/`) and emit a platform-neutral JSON that both iOS and Android can ingest.

## What they are
- **Color tokens**: semantic names like `color.surface`, `color.text.primary`, `color.action.primary`.
- **Typography tokens**: font families, sizes, weights, line heights, letter spacing.
- **Spacing & radius**: base unit, padding scale, corner radii.
- **Elevation/shadows**: z-levels for surfaces/cards.

## Current Scaffold
- **Location**: `mobile/shared/design-tokens/` (own package, Style Dictionary based).
- **Source stub**: `mobile/shared/design-tokens/tokens/tokens.json` holds a temporary, minimal token set.
- **Export**: `npm run export` copies the source tokens into the package (override with `SOURCE_TOKENS_PATH`; default is `planning/mobile/tokens.json`).
- **Build**: `npm install && npm run build` emits JSON, Swift, Android XML, and CSS variables to `dist/` via `scripts/build.js`.
- **Consume**: `PLATFORM_WRAPPERS.md` sketches Swift/Compose wrappers for the generated outputs.
- **Schema**: Follows the neutral JSON shape below; themes can be added as top-level keys.
```json
{
  "color": {
    "surface": "#0B0C0E",
    "surfaceAlt": "#111318",
    "text": {
      "primary": "#E8EAED",
      "secondary": "#BEC2C8"
    },
    "action": {
      "primary": "#4F46E5",
      "primaryHover": "#4338CA"
    }
  },
  "typography": {
    "label": {"font": "Inter", "size": 14, "lineHeight": 20, "weight": 600},
    "body": {"font": "Inter", "size": 16, "lineHeight": 24, "weight": 400},
    "title": {"font": "Inter", "size": 20, "lineHeight": 28, "weight": 600}
  },
  "spacing": {"base": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24},
  "radius": {"sm": 6, "md": 10, "lg": 14},
  "elevation": {"card": {"shadow": "0 4 12 0 rgba(0,0,0,0.18)"}}
}
```

## Proposed Flow (align with web tokens)
1. **Source**: Reuse the design tokens from the `ui/` repo (Tailwind/theme config or existing token files).
2. **Export step**: Add a Node script that reads the web token source and overwrites `mobile/shared/design-tokens/tokens/tokens.json`.
3. **Platform transforms**: Keep Style Dictionary emitting Swift/Compose/CSS artifacts; add platform wrappers as needed (e.g., Swift extensions, Compose theme objects).
4. **Versioning**: Commit the neutral JSON in `mobile/shared/design-tokens/`; rebuild artifacts when `ui/` tokens change.
5. **Dark/Light**: Support multiple themes by adding a top-level key per theme, e.g., `themes.default`, `themes.dark`.

## Next Steps
- Point the export script at the canonical `ui/` tokens to replace the stub data.
- Add CI to lint/build the package and publish generated artifacts for iOS/Android consumption.
- Document platform-specific wrappers (Swift/Compose) that consume the generated outputs.
