# Developer Guide — I4G Mobile Prototype (for a mobile-novice developer)

> **Audience:** You've written TypeScript / React before (or can read it) but have **never** built
> a mobile app, never opened Xcode, never touched Android Studio.
> **Promise:** If you follow this guide end-to-end, you will go from a cold laptop to an app running
> on your iPhone **and** your Android phone, hitting the local I4G backend, **in under one working
> day**. If you exceed that budget, stop and log the blocker in the Risk register of the
> [implementation-plan](./implementation-plan.md).

This guide has five parts:

1. **Mental model** — what you're about to learn, in plain language.
2. **Tools setup** — one-time install, copy-paste-able.
3. **Day-one walkthrough** — the first code you run, end-to-end.
4. **Day-in-the-life** — your daily workflow, loop, and debugging playbook.
5. **Shipping paths** — from simulator to your own phone to an internal test to (someday) the stores.

If a step fails, search the **[Gotchas table](#appendix-b--gotchas-and-fixes)** first.

## Part 1 · Mental model (read once)

You're going to write **one TypeScript codebase** that compiles into **two native apps** (one iOS,
one Android). The tools we use are:

- **Expo** — a managed wrapper around React Native that hides 90% of the platform-specific build
  complexity. You'll rarely open Xcode or Android Studio.
- **Expo Dev Client** — a custom version of the "Expo Go" app that you install once on your phone.
  After that, your code changes show up in seconds without rebuilding the native app.
- **Expo Router** — file-based navigation. Dropping a file at `app/case/[id].tsx` creates a route
  `/case/123`. Exactly like Next.js's app router.
- **EAS (Expo Application Services)** — Expo's cloud build service. Free tier is enough for the
  prototype.

What you will **not** do in the prototype:

- Edit `Info.plist` by hand (Expo config plugins do it for you).
- Edit `build.gradle` by hand (same).
- Sign up for Apple Developer Program or Google Play Console (sideload is enough).
- Learn Swift or Kotlin (maybe later, not now).

The app talks to the **same HTTP API** the web console talks to. The only thing "mobile" about the
networking is how you get an auth token on a phone. That's covered in Part 3.

## Part 2 · Tools setup (one-time, ~60 min)

> **Checkpoint after each section:** the command in the _Verify_ line must succeed. If it doesn't,
> stop and fix it before continuing.

### 2.1 OS + Node

Tested on **macOS 14** and **Ubuntu 22.04**. Windows via WSL2 works but isn't exercised in CI.

```bash
# Node 20 via nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# restart shell, then:
nvm install 20 && nvm use 20

# pnpm (matches the rest of the i4g workspace)
corepack enable
corepack prepare pnpm@latest --activate
```

_Verify:_ `node -v` prints `v20.x`, `pnpm -v` prints `9.x`.

### 2.2 Expo CLI & EAS CLI

```bash
pnpm add -g expo@latest eas-cli@latest
```

_Verify:_ `expo --version` and `eas --version` both print a number.

### 2.3 iOS toolchain (macOS only)

```bash
# Xcode from the App Store (free). ~40 GB download. Accept the license:
sudo xcodebuild -license accept
# Install Command Line Tools + iOS Simulator runtime:
xcode-select --install
open -a Simulator
```

_Verify:_ `xcrun simctl list devices | grep iPhone` lists at least one simulator. `open -a
Simulator` shows a simulator window.

> **If you're on Linux/Windows:** you can't run the iOS Simulator. Work on Android only until you
> get access to a Mac. Everything else below still works.

### 2.4 Android toolchain (all OSes)

Install **Android Studio** → first-launch wizard → accept all SDK licenses. Then:

```bash
# macOS/Linux shell rc (add to ~/.zshrc or ~/.bashrc):
export ANDROID_HOME="$HOME/Library/Android/sdk"   # macOS
# export ANDROID_HOME="$HOME/Android/Sdk"          # Linux
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"
```

In Android Studio → **More Actions → Virtual Device Manager** → create a Pixel 7 with the latest
stable system image → launch it once so it boots.

_Verify:_ `adb devices` lists your emulator (may say "unauthorized" briefly — tap "allow" on the
emulator).

### 2.5 Watchman (macOS/Linux, recommended)

```bash
brew install watchman      # macOS
# Linux: follow https://facebook.github.io/watchman/docs/install
```

_Verify:_ `watchman --version` prints a version.

### 2.6 Docker (for the I4G backend)

Install Docker Desktop. In Settings → Resources, give it ≥ 8 GB RAM. Then follow the first two
sections of [`core/docs/runbooks/local-aio.md`](../../../core/docs/runbooks/local-aio.md) to load
and run `i4g-local`.

_Verify:_ `curl http://localhost:8000/docs` returns Swagger HTML.

### 2.7 Code editor

VS Code with these extensions:

- **Expo Tools** (Expo)
- **ESLint** (Microsoft)
- **Prettier** (Prettier)
- **React Native Tools** (Microsoft)

This workspace already has a multi-root setup — open the whole `i4g` workspace, not just `mobile/`.

### 2.8 Expo account (free)

```bash
eas login
```

Creates a free account. Required for cloud builds. Nothing is billed unless you exceed the free
tier (you won't).

## Part 3 · Day-one walkthrough

Estimated time: **2–3 hours of focused work**, mostly waiting on installers.

### 3.1 Clone and install

```bash
cd ~/Work/project        # or wherever your i4g workspace lives
# The repo already exists; you're just entering it:
cd i4g/mobile/app        # folder created in Sprint 0; see the implementation plan

pnpm install
```

_If `mobile/app/` doesn't exist yet:_ you're at the very start of Sprint 0. Follow the
implementation plan's S0.1 to create it, then come back.

### 3.2 Configure your local env

```bash
cp .env.local.example .env.local
# Find your laptop's LAN IP (for your phone to reach it):
#   macOS:  ipconfig getifaddr en0
#   Linux:  hostname -I | awk '{print $1}'
# Put it into .env.local:
#   EXPO_PUBLIC_API_BASE_URL=http://192.168.1.42:8000
```

**Why the LAN IP and not `localhost`?** A physical phone on your Wi-Fi can't reach
`http://localhost:8000` on your laptop — `localhost` on the phone means the phone itself. An IP on
the LAN works.

> **Corporate Wi-Fi blocks device-to-laptop traffic?** Run `pnpm dev:tunnel` (described below)
> instead of a LAN URL. Slower but always works.

### 3.3 Start the backend

```bash
docker start i4g || docker run -d --name i4g -p 3000:3000 -p 8000:8000 -p 8100:8100 i4g-local
# Verify:
curl http://localhost:8000/docs >/dev/null && echo "core up"
```

### 3.4 Start the app (simulator first — easier)

```bash
pnpm dev:ios       # or: pnpm dev:android
```

The first time, Expo builds a Dev Client binary and installs it into the simulator. This takes
~2–5 minutes. After that, every reload is seconds.

When the simulator shows **"Signed in as Local Analyst"** on a Dashboard, you have everything
working end-to-end. 🎉

### 3.5 Move to a physical phone (most of your real work will happen here)

**iOS:**

1. Install **Expo Go** from the App Store (yes, Go — we'll swap it for Dev Client in a moment).
2. Connect the phone to the **same Wi-Fi** as your laptop.
3. Run `pnpm dev` in `mobile/app/`.
4. Open the Camera app on the phone, scan the QR code in the terminal, tap "Open in Expo Go".
5. The app loads. You now have a dev build on your phone.

Once you need features Expo Go can't provide (native modules, custom schemes for OAuth), replace
Expo Go with **Dev Client**:

```bash
eas build --profile local --platform ios --local   # builds a .ipa locally (requires Xcode)
# install it on the phone via Xcode → Devices and Simulators → + → drag the .ipa
```

This is the one time you open Xcode. After installation, Dev Client behaves like Expo Go but also
supports everything we need.

**Android:**

1. Enable Developer Options on the phone (tap Build Number 7 times in Settings → About).
2. Enable USB Debugging.
3. Connect via USB. Accept the RSA prompt.
4. `adb devices` lists your phone.
5. `pnpm dev:android` — Expo will offer to install Dev Client via `adb install`.

### 3.6 Make your first change

Open `app/(tabs)/dashboard.tsx`, change a string, save. The app **hot-reloads** on both the
simulator and the phone. No rebuild. No menu dancing. This is the main reason we chose Expo.

## Part 4 · Day-in-the-life

### 4.1 The daily loop

```bash
# 1. Start backend (once per day):
docker start i4g

# 2. Start the app:
cd mobile/app
pnpm dev                # metro bundler; pick device from the menu

# 3. Edit code. Save. See change.

# 4. Before you push:
pnpm lint
pnpm typecheck
pnpm test
```

### 4.2 The four-shortcut debugging toolbox

1. **`j` in the metro terminal** — opens Chrome DevTools for the JS context. You get console,
   network, and a debugger. This is your #1 tool. Learn it first.
2. **Shake device / `Cmd+D` in iOS simulator / `Cmd+M` in Android emulator** — the Dev Menu. From
   here: reload the app, toggle element inspector, open performance monitor.
3. **React Native Debugger tab "Elements"** — lets you tap on anything in the app and see the
   component tree. Like browser dev tools for a native view hierarchy.
4. **TanStack Query Devtools** — already wired in development builds. Floating button in bottom-left.
   Shows every query, its cache, its fetch state. If the UI looks wrong, check here first — 80% of
   "weird" bugs are stale caches.

### 4.3 Common tasks, the right way

| Task                    | Do this                                                                                                                                    | Don't do this                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- |
| Add a new screen        | Drop a file in `app/…/name.tsx`. Expo Router picks it up.                                                                                  | Install `@react-navigation` directly.  |
| Fetch data              | Write a hook in `src/features/<feature>/queries.ts` using TanStack Query.                                                                  | Call `fetch` inside a component.       |
| Mutate data             | `useMutation(...)` with optimistic update + invalidate.                                                                                    | Imperative `setState` after a `fetch`. |
| Add a color             | Edit `mobile/shared/design-tokens/tokens/tokens.json`, run `npm run build`, use from `theme`.                                              | Hardcode `#RRGGBB` in a component.     |
| Add a library           | Check if Expo has it (`expo install xyz`). If yes, use that. If no, think twice — a raw native lib may need Dev Client or a config plugin. | `pnpm add` arbitrary native packages.  |
| Change iOS `Info.plist` | Use an Expo **config plugin**. See Expo docs.                                                                                              | Eject to the bare workflow.            |

### 4.4 When things break (a decision tree)

```
Did "pnpm dev" show an error?
├─ Yes → Metro error? Read the bold line. Usually a missing file or a bad import.
│        Native error? Clear caches: `pnpm dev -- --clear` then rebuild Dev Client.
└─ No → App crashed on the phone?
        ├─ Shake → "Debug Remote JS" → check the console for the real JS error.
        └─ Still mysterious? `eas build --profile local ...` shows native logs.

Request failing?
├─ 401 → auth flow broke. Print `config.authProvider` and check token.
├─ 404 → URL typo or backend endpoint doesn't exist. Cross-check TDD §12.
├─ Network error on device but not simulator → LAN IP is wrong or firewall.
└─ ValidationError from Zod → backend returned a shape we didn't expect. Update the schema.
```

A living copy of this tree lives in [Appendix B](#appendix-b--gotchas-and-fixes); add to it when you
find something new.

### 4.5 Hot reloading rules (that might surprise a web dev)

- Editing a React component → **fast refresh**, keeps state.
- Editing a `useEffect` dependency array → state **may not** update; hit `r` in metro to reload.
- Editing `app.config.ts` or `.env.*` → requires a **full restart** (`Ctrl+C`, then `pnpm dev`).
- Editing native deps (anything in `android/` or `ios/`, or adding a native module) → requires a
  **Dev Client rebuild** (`eas build --profile local`).

### 4.6 Git and PR workflow

- One branch per task group in the [implementation plan](./implementation-plan.md).
- PR title starts with the sprint id: `S2.2: Reviews queue filter bar`.
- PR description links the tasks ticked.
- CI must be green before merge.
- Squash-merge to `main`.

## Part 5 · Shipping paths

### 5.1 Simulator → physical device (no accounts, free)

Already covered in §3.5. This is your prototype shipping path.

### 5.2 Share with one teammate (TestFlight-free)

**iOS:** build a Dev Client `.ipa` locally and have them install via Xcode → Devices → +. Requires
the teammate's device UDID in a provisioning profile (free Apple ID signing works for 7-day
profiles — good enough for a dogfood).

**Android:** `eas build --profile preview --platform android` produces a `.apk`. Send it via
AirDrop / email / drive; they install directly. No accounts required.

### 5.3 Internal testing (paid)

When you're ready to move beyond dogfooding, enroll in:

- **Apple Developer Program** ($99/yr) → TestFlight Internal Testing (up to 100 testers, no review).
- **Google Play Console** ($25 one-time) → Internal Testing track (up to 100 testers).

Run:

```bash
eas build --profile preview --platform all
eas submit --profile preview --platform all
```

EAS handles the upload. You've now published to testers.

### 5.4 Store release (out of scope for prototype)

When / if a real release happens: a separate "Release runbook" doc gets written; that's when you
need assets, privacy questionnaires, and a marketing page. Not now.

## Appendix A · One-page cheat sheet

```
SETUP (once)
  nvm install 20 && corepack enable
  pnpm add -g expo eas-cli
  docker load < i4g-local.tar.gz

DAILY
  docker start i4g
  cd mobile/app
  pnpm dev               # pick i | a
  pnpm lint && pnpm typecheck && pnpm test

DEBUG
  j          # open devtools from metro
  Cmd+D      # dev menu (iOS sim)
  Cmd+M      # dev menu (Android em)
  shake      # dev menu (device)

RESET
  pnpm dev -- --clear    # clear metro cache
  rm -rf node_modules .expo && pnpm i

BUILD (local)
  eas build --profile local --platform ios --local
  eas build --profile local --platform android --local

BUILD (cloud, for sharing)
  eas build --profile preview --platform all
```

## Appendix B · Gotchas and fixes

> Keep this table growing. Every gotcha you hit that isn't here, add it in the same PR.

| Symptom                                             | Cause                                        | Fix                                                                     |
| --------------------------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------- |
| `Network request failed` on device but works on sim | Phone can't reach `localhost`.               | Use LAN IP in `.env.local` or `pnpm dev -- --tunnel`.                   |
| `Unable to resolve module` after adding a dep       | Metro cache                                  | `pnpm dev -- --clear`                                                   |
| Dev Client opens old bundle                         | Stale Metro                                  | Shake → "Reload". Still wrong? Reinstall Dev Client.                    |
| Android emulator frozen during install              | RAM starved                                  | Close other emulators; give AVD ≥ 4 GB RAM.                             |
| iOS simulator can't reach backend                   | IPv6 vs IPv4                                 | Use `127.0.0.1` instead of `localhost`.                                 |
| `expo-auth-session` returns `dismiss` on iOS        | Redirect scheme missing from `app.config.ts` | Set `scheme`, rebuild Dev Client (config change = native rebuild).      |
| Zod parse fails after backend update                | Backend drift                                | Update the schema in `src/features/.../types.ts`; add a contract test.  |
| TanStack Query shows stale data after mutation      | Missing `invalidateQueries`                  | Add it in `onSuccess`.                                                  |
| Image on device is blurry then sharp                | `expo-image` placeholder transition          | Fine. If it bothers you, remove `placeholder` prop.                     |
| White screen on launch (release builds)             | Error thrown before Error Boundary mounts    | Wrap root `_layout.tsx` in a top-level `try/catch` that logs to Sentry. |
| `EXPO_PUBLIC_*` not updating                        | Metro has cached `.env`                      | Full restart (`Ctrl+C` + `pnpm dev`).                                   |
| `fetch` works on sim but 401 on real phone          | Phone clock skew vs token `exp`              | Enable automatic time on phone.                                         |
| Corporate Wi-Fi blocks phone↔laptop                 | Network segmentation                         | `pnpm dev -- --tunnel` uses ngrok-like tunnel.                          |
| Xcode signing error on `eas build --local`          | Missing dev cert                             | Run once in Xcode with a free Apple ID to seed the keychain.            |

## Appendix C · Vocabulary cheat sheet for a web dev

| If you hear…                  | Think of it as…                                                          |
| ----------------------------- | ------------------------------------------------------------------------ |
| Metro                         | webpack/vite for RN                                                      |
| Hermes                        | V8 for RN (the JS engine on-device)                                      |
| Bridge / JSI                  | the wire between JS and native UI                                        |
| Native module                 | a Node addon, but in Swift/Kotlin                                        |
| Expo Go                       | runtime with prepackaged native modules (limited set)                    |
| Dev Client                    | your own Expo Go with your own native modules                            |
| EAS                           | GitHub Actions, but for building mobile binaries                         |
| Managed workflow              | Expo owns your `ios/` and `android/` folders                             |
| Bare workflow                 | you own `ios/` and `android/`                                            |
| Config plugin                 | a function that mutates native config at build time (no ejection needed) |
| AppAuth / `expo-auth-session` | NextAuth for a native app                                                |
| `expo-secure-store`           | Keychain / EncryptedSharedPrefs wrapper                                  |
| `expo-image`                  | `next/image` for RN                                                      |

---

You now have everything you need to start. Open [implementation-plan.md](./implementation-plan.md)
and begin Sprint 0.
