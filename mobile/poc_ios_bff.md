# iOS BFF PoC (Local Sandbox)

Goal: Stand up a minimal local flow where the iOS app hits a BFF (Next.js) instead of the raw FastAPI service. This avoids public DNS/IAP blockers and proves the client architecture.

## What We’ll Do
1. Run the existing Next.js app (ui/) locally as the BFF (Dev mode).
2. Point the iOS simulator at the BFF via `http://localhost:3000` (or `http://127.0.0.1:3000`).
3. Use a single static page/route that returns stubbed JSON (no auth) to validate networking, tokens, and DTO parsing.

## Minimal BFF Endpoint (suggested)
In `ui/` add a dev-only route:
- `pages/api/mobile/ping.ts` (or App Router equivalent):
  ```ts
  export default function handler(req, res) {
    res.status(200).json({ ok: true, message: "mobile-bff-alive", ts: Date.now() });
  }
  ```
- Later, mirror real BFF calls (e.g., `/api/mobile/cases`) by proxying to FastAPI with server-side secrets.

## iOS Client PoC (Simulator)
- Stack: SwiftUI + URLSession.
- Hit `http://127.0.0.1:3000/api/mobile/ping` from the simulator.
- Disable ATS for `localhost` only (Info.plist) or use `https://localhost:3000` with a local cert if you prefer.

Example Swift snippet:
```swift
import SwiftUI

struct ContentView: View {
    @State private var status = ""
    var body: some View {
        VStack {
            Text(status.isEmpty ? "Loading..." : status)
                .padding()
                .multilineTextAlignment(.center)
        }
        .task {
            await load()
        }
    }

    func load() async {
        guard let url = URL(string: "http://127.0.0.1:3000/api/mobile/ping") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                status = "BFF OK: \(json)"
            }
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
    }
}
```

## Running the PoC
1. In `ui/`: `pnpm install` then `pnpm dev` (starts on `localhost:3000`).
2. Launch iOS Simulator.
3. Run the SwiftUI app; it should display the JSON from `/api/mobile/ping`.

## Next Steps (when DNS/IAP ready)
- Switch the base URL to the LB domain (`https://app.intelligenceforgood.org`) and use PKCE + AppAuth to obtain Google tokens; rely on the BFF to inject service auth to FastAPI.
- Move from stub ping to real BFF proxied endpoints (cases, case detail, evidence thumbnails).
- Re-enable ATS with proper TLS once certs are live.
