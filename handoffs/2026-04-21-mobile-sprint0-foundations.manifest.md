# Mobile Prototype — Sprint 0: Workspace & Methodology Foundations

<contract>
**Role:** Executor
**Planner model:** Claude Sonnet 4.6
**Manifest version:** 1
**Estimated scope:** L
**Repos touched:** mobile
</contract>

## Goal

Stand up a fully-configured `mobile/app/` Expo SDK 51 project so that any developer can clone and
reach "Hello I4G" on both iOS Simulator and Android Emulator by following `developer-guide.md`
alone. CI must be green before Sprint 1 begins.

## Context

- Source plan: `planning/proposals/mobile-prototype/implementation-plan.md` — Sprint 0 (S0.1–S0.5)
- TDD (stack choices, directory layout, env schema, app.config.ts): `planning/proposals/mobile-prototype/tdd.md` §1–3
- Architecture: `planning/proposals/mobile-prototype/architecture.md`
- Developer guide (document what actually happened in S0.5): `planning/proposals/mobile-prototype/developer-guide.md`
- Design tokens source: `mobile/shared/design-tokens/tokens/tokens.json`
- ESLint/Prettier reference: `ui/` root — mirror version pinning exactly (`prettier@3.2.5`)
- Shared coding standards: `copilot/.github/shared/general-coding.instructions.md`

Do **not** restate the TDD or architecture here — link and implement.

<files>
### Files to create

- `mobile/app/package.json` — Expo SDK 51 app manifest with all Sprint 0 deps + scripts (`dev:ios`, `dev:android`, `lint`, `typecheck`, `test`)
- `mobile/app/app.config.ts` — exact schema from TDD §3.2; reads `.env.<profile>` via `dotenv/config`
- `mobile/app/tsconfig.json` — `strict: true`, path alias `@/*` → `src/*`
- `mobile/app/babel.config.js` — Expo default preset; add `babel-plugin-module-resolver` for `@/*`
- `mobile/app/.eslintrc.js` — mirror `ui/` ESLint rules; extend `expo` config; add the three CI grep rules as ESLint rules where possible
- `mobile/app/.prettierrc.js` — mirror `ui/` Prettier config exactly
- `mobile/app/.gitignore` — standard Expo gitignore; add `.env.local`, `.env.dev`, `.env.prod` (examples are committed, actuals are not)
- `mobile/app/.env.local.example` — exact content from TDD §3.1
- `mobile/app/.env.dev.example` — exact content from TDD §3.1
- `mobile/app/.env.prod.example` — exact content from TDD §3.1 (profile=prod, apiMode=remote, authProvider=google-pkce-iap)
- `mobile/app/eas.json` — three build profiles: `local` (platform: all, distribution: internal, channel: local), `dev` (distribution: internal, channel: dev), `prod` (distribution: store, channel: prod)
- `mobile/app/app/_layout.tsx` — minimal Expo Router root layout (Stack navigator only; no providers yet — providers are Sprint 1)
- `mobile/app/app/index.tsx` — single screen showing "Hello I4G" text; imports color from `useTheme()` (theme.color.surface as background)
- `mobile/app/src/config/index.ts` — exact `config` export from TDD §3.3 (Zod-validated); also exports `config.profile` as a string
- `mobile/app/src/config/types.ts` — `Profile`, `AuthProviderKey`, `ApiMode` as Zod enum types extracted from TDD §3.3 Schema
- `mobile/app/src/design/theme.ts` — imports the built TS token output from `mobile/shared/design-tokens/dist/tokens.ts`; exports `useTheme()` returning typed theme object
- `.github/workflows/mobile-ci.yml` — workflow triggered on push/PR; jobs: `lint-typecheck-test` (install pnpm, `pnpm -C mobile/app install`, `pnpm -C mobile/app lint`, `pnpm -C mobile/app typecheck`, `pnpm -C mobile/app test`); plus a grep job running the three security rules (see Step 5)

### Files to modify

- `mobile/shared/design-tokens/scripts/build.js` — verify it outputs a `dist/tokens.ts` typed ES module; if not, add a `typescript` formatter using Style Dictionary's built-in formatter; do not change the JSON token source
- `planning/proposals/mobile-prototype/developer-guide.md` — fill in the "Zero to Hello" section under Part 3 (Day-one walkthrough) with the exact commands that worked; update Appendix B (Gotchas) with any friction encountered
- `planning/proposals/mobile-prototype/implementation-plan.md` — check off all completed S0.x tasks (`- [x]`)

### Files NOT to touch

- `mobile/shared/design-tokens/tokens/tokens.json` — token source of truth; never edit during Sprint 0
- `mobile/shared/design-tokens/wrappers/` — platform wrappers are pre-existing; do not regenerate or delete them
- `ui/` — read-only reference for ESLint/Prettier versions; do not edit
- `core/`, `ssi/`, `infra/`, `planning/` (except implementation-plan.md and developer-guide.md)
- Any file in `mobile/app/app/` except `index.tsx` and `_layout.tsx` — do not create Sprint 1+ screens
  </files>

## Step-by-step

### Step 1 — Scaffold the Expo app

```bash
cd /path/to/mobile
pnpm create expo-app@latest app --template tabs-typescript
```

After scaffolding:

- Pin `"expo": "~51.0.0"` in `mobile/app/package.json` (the template may install a newer SDK; pin it explicitly).
- Verify `pnpm -C mobile/app start` prints a QR code and exits cleanly with Ctrl-C.
- Delete the generated example screens under `app/app/(tabs)/` — keep only the router shell (`_layout.tsx`).
- Replace `app/app/index.tsx` (or create it) with the "Hello I4G" screen (see Step 4).

**Checkpoint:** `pnpm -C mobile/app start` exits without error.

### Step 2 — ESLint, Prettier, TypeScript

1. Open `ui/package.json` and note the pinned `prettier` version (`3.2.5`). Mirror this exactly in `mobile/app/package.json`.
2. Copy (do not symlink) the Prettier config from `ui/.prettierrc.js` (or equivalent) into `mobile/app/.prettierrc.js`. If `ui/` uses a config key in `package.json`, create a separate `.prettierrc.js` file in `mobile/app/`.
3. Create `mobile/app/.eslintrc.js` extending `expo` and applying the same rule severity as `ui/`.
4. Create `mobile/app/tsconfig.json`:
   ```json
   {
     "extends": "expo/tsconfig.base",
     "compilerOptions": {
       "strict": true,
       "baseUrl": ".",
       "paths": { "@/*": ["src/*"] }
     }
   }
   ```
5. Add `babel-plugin-module-resolver` to resolve `@/*` at runtime (Expo Router needs this alongside tsconfig paths).
6. Run `pnpm -C mobile/app lint` — must pass on the template/cleaned-up code.
7. Run `pnpm -C mobile/app typecheck` — must pass.

**Checkpoint:** Both commands exit 0.

### Step 3 — EAS + env files

1. Create `mobile/app/eas.json` with exactly three profiles: `local`, `dev`, `prod`. Use `distribution: "internal"` for `local` and `dev`; `distribution: "store"` for `prod`. Set `channel` names to match the profile name.
2. Create the three `.env.*.example` files using the exact variable names and example values from TDD §3.1. Commit all three.
3. Add `.env.local`, `.env.dev`, `.env.prod` (no `.example`) to `mobile/app/.gitignore`.
4. Create `mobile/app/app.config.ts` using the exact structure from TDD §3.2. Install `dotenv` as a dev dependency.
5. Create `mobile/app/src/config/index.ts` and `src/config/types.ts` using the exact Zod schema from TDD §3.3. Install `expo-constants` and `zod`.

**Checkpoint:** `node -e "require('./app.config.ts')"` does not throw (use ts-node or the Expo config evaluator).

### Step 4 — "Hello I4G" screen (uses theme)

1. In `mobile/app/src/design/theme.ts`, import from `../../shared/design-tokens/dist/tokens.ts` using a relative path. Export `useTheme()` that returns the typed token object. (At this stage `useTheme` can be a plain function, not a React hook — a hook wrapper is fine but not required.)
2. In `mobile/app/app/index.tsx`, implement a screen that:
   - Sets the view background to `theme.color.surface` (or the equivalent top-level token key present in the generated output).
   - Renders a centred `<Text>Hello I4G</Text>`.
   - Imports `config` from `@/config` and renders `config.profile` as a subtitle (proves env wiring works).
3. Run the app on iOS Simulator: `pnpm -C mobile/app dev:ios` (or the equivalent Expo script). Verify "Hello I4G" and a profile label appear.
4. Run on Android Emulator: `pnpm -C mobile/app dev:android`. Same check.

**Checkpoint:** Screenshot or manual observation confirms "Hello I4G" on both simulators.

### Step 5 — CI workflow

Create `.github/workflows/mobile-ci.yml` with the following structure:

```yaml
name: Mobile CI
on:
  push:
    paths: ["mobile/**", ".github/workflows/mobile-ci.yml"]
  pull_request:
    paths: ["mobile/**", ".github/workflows/mobile-ci.yml"]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm
      - run: pnpm -C mobile/app install --frozen-lockfile
      - run: pnpm -C mobile/app lint
      - run: pnpm -C mobile/app typecheck
      - run: pnpm -C mobile/app test

  security-grep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Forbid console.log of tokens/PII
        run: |
          ! grep -r 'console\.log' mobile/app/src/ \
            | grep -E 'token|password|secret|email|Bearer'
      - name: Forbid raw fetch() outside src/api/
        run: |
          ! grep -rn '\bfetch(' mobile/app/src/ \
            | grep -v '^mobile/app/src/api/'
      - name: Forbid AsyncStorage
        run: |
          ! grep -rn 'AsyncStorage' mobile/app/src/
```

**Checkpoint:** Push a no-op PR; both jobs must pass in under 10 minutes.

To verify the grep rules catch violations, create a temporary branch with one deliberate `AsyncStorage` import in `src/features/` — confirm `security-grep` turns red — then delete the branch.

### Step 6 — Build design tokens (TypeScript output)

1. Inspect `mobile/shared/design-tokens/scripts/build.js` for whether it already emits a `dist/tokens.ts` ES-module with TypeScript types.
2. If `dist/tokens.ts` does not exist or is not typed: add a `typescript` output platform to `build.js` using Style Dictionary's `javascript/es6` format (or a custom formatter that wraps the output in `export const tokens = ... as const`).
3. Run `node mobile/shared/design-tokens/scripts/build.js` from the repo root. Verify `dist/tokens.ts` is generated and exports a typed object.
4. Import this file from `mobile/app/src/design/theme.ts` (relative path `../../shared/design-tokens/dist/tokens.ts`) and confirm TypeScript resolves the import without error.

**Checkpoint:** `pnpm -C mobile/app typecheck` still passes after adding the import.

### Step 7 — Dev Client scripts

Add to `mobile/app/package.json` `scripts`:

```json
{
  "dev:ios": "expo start --dev-client --ios",
  "dev:android": "expo start --dev-client --android",
  "lint": "eslint . --ext .ts,.tsx --max-warnings 0",
  "typecheck": "tsc --noEmit",
  "test": "vitest run"
}
```

If Vitest causes friction with Expo RN after 30 minutes of troubleshooting, switch to `jest --preset jest-expo` and update the `test` script accordingly. Document the choice in `developer-guide.md` Appendix B.

**Checkpoint:** `pnpm -C mobile/app test` exits 0 (even if no test files exist yet — Vitest/Jest exits 0 on no tests by default with the `--passWithNoTests` flag; add it if needed).

### Step 8 — Documentation (S0.5)

Fill in the "Zero to Hello" section in `planning/proposals/mobile-prototype/developer-guide.md` under Part 3, using the exact commands that actually worked during Steps 1–7. Include:

- The exact `pnpm create expo-app` command used.
- The iOS Simulator launch command.
- The Android Emulator launch command.
- Any gotchas encountered, added to Appendix B.

Then check off all completed S0.x tasks in `planning/proposals/mobile-prototype/implementation-plan.md`.

<do_not>

- Do not create any Sprint 1+ screens or hooks (`sign-in.tsx`, `ApiClient`, auth providers, TanStack Query, Zustand). Those belong to the Sprint 1 manifest.
- Do not edit `mobile/shared/design-tokens/tokens/tokens.json`.
- Do not edit any file in `ui/`, `core/`, `ssi/`, or `infra/`.
- Do not add providers to `_layout.tsx` beyond what Expo Router requires — providers are Sprint 1.
- Do not commit actual `.env.local`, `.env.dev`, or `.env.prod` files (only `.example` variants).
- Do not add native modules that require a custom dev client build beyond `expo-dev-client` itself — that would break the `local` profile's `eas build --local` flow.
- Do not refactor `mobile/shared/design-tokens/scripts/build.js` beyond adding the TypeScript output; leave the existing outputs intact.
- Do not spend more than 30 minutes on Vitest/Expo friction before switching to Jest — log the decision in developer-guide.md Appendix B.
- Do not introduce any new dependencies not present in the TDD §1 tech stack table without noting the reason in the PR description.
  </do_not>

<verification>
### Acceptance criteria

- [ ] `ls mobile/app/package.json` exits 0.
- [ ] `pnpm -C mobile/app install --frozen-lockfile` exits 0 with lockfile committed.
- [ ] `pnpm -C mobile/app lint` exits 0 with `--max-warnings 0`.
- [ ] `pnpm -C mobile/app typecheck` exits 0.
- [ ] `pnpm -C mobile/app test` exits 0 (pass-with-no-tests acceptable for Sprint 0).
- [ ] `node mobile/shared/design-tokens/scripts/build.js` exits 0 and `mobile/shared/design-tokens/dist/tokens.ts` exists.
- [ ] iOS Simulator renders "Hello I4G" with the surface color from design tokens.
- [ ] Android Emulator renders "Hello I4G" with the surface color from design tokens.
- [ ] CI `quality` job passes on a no-op PR in < 10 minutes.
- [ ] CI `security-grep` job turns red on a deliberate `AsyncStorage` violation branch, then green after the violation is removed.
- [ ] `.env.local`, `.env.dev`, `.env.prod` do not appear in git (`git status` shows nothing for those paths after `touch mobile/app/.env.local`).
- [ ] `mobile/app/src/config/index.ts` throws a `ZodError` when `EXPO_PUBLIC_PROFILE` is set to an invalid value (manually verify by editing a local env file).
- [ ] All S0.x checkboxes ticked in `planning/proposals/mobile-prototype/implementation-plan.md`.

### Commands to run

```bash
# Lint + types
pnpm -C mobile/app install --frozen-lockfile
pnpm -C mobile/app lint
pnpm -C mobile/app typecheck
pnpm -C mobile/app test

# Token build
node mobile/shared/design-tokens/scripts/build.js
ls mobile/shared/design-tokens/dist/tokens.ts

# gitignore check
touch mobile/app/.env.local
git status mobile/app/.env.local   # must show: nothing to commit (ignored)
rm mobile/app/.env.local

# Config validation
cd mobile/app
EXPO_PUBLIC_PROFILE=bad_value node -e "require('./src/config')"   # must throw ZodError
cd -

# CI simulation (local)
act push --job quality    # if 'act' is installed; otherwise push a PR
```

</verification>
