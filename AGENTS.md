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
- Do NOT manually update `Info.plist` version, `Casks/occam.rb`, or `mpalczew/homebrew-occam` — CI handles these.

## Build
- `make build` compiles + assembles. `make run` builds + launches. `make clean` removes artifacts.

## Releasing
1. Update `CHANGELOG.md` → commit → `git tag vX.Y.Z && git push origin master vX.Y.Z`
2. CI builds, signs, notarizes, creates GitHub Release, updates Homebrew tap.
3. Verify: `gh run watch`, then `brew update && brew upgrade --cask occam`
4. Or use `scripts/release.sh X.Y.Z` interactively.
- Screenshot tests: if UI changes, run `make screenshot` and commit the updated `assets/screenshot.png`.
