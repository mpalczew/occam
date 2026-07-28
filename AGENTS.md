# Agents

## How to Work With the User
- Present options and be opinionated. Lead with your recommendation, explain trade-offs briefly, let the user decide.
- Zero external dependencies. Do not introduce third-party packages.
- One class/protocol/struct per file.

## Constants & Magic Numbers
- Extract behavioral constants (timing, limits, scoring) as `static let` on the owning type — no global Constants.swift.
- Leave UI styling (font sizes, padding, opacity) inline in SwiftUI views.
- Define key codes as a `UInt16` raw-value enum (`KeyCode`).
- Extract values that appear in multiple files to avoid divergence.

## Don'ts
- Do NOT use `NSEvent.addGlobalMonitorForEvents` for hotkeys — use Carbon `RegisterEventHotKey`.
- Do NOT use `mdfind`, `NSMetadataQuery`, or background indexing for app discovery.
- Do NOT prompt for Accessibility permission. Carbon hotkeys don't need it, and rebuilds invalidate the binary hash.

## Build & Run
- `make build` compiles + assembles the `.app` bundle. `make clean` removes artifacts.
- `make run` builds + launches the app. Do NOT use `swift run` — this is a macOS GUI app that requires the `.app` bundle.

- Screenshot tests: if UI changes, run `make screenshot` and commit the updated `assets/screenshot.png`.

## Procedure
- test locally
- release a new version once verified
- let autoupgrading work
