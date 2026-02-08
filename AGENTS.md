# Agents

## Architecture
- Hybrid AppKit + SwiftUI. NSPanel for window management, SwiftUI via NSHostingView for UI.
- Zero external dependencies. Pure Swift/AppKit/SwiftUI only.
- Explicit `main.swift` entry point (not `@main`).
- One class/protocol/struct per file. No exceptions — extract helpers into separate files.

## Build
- SPM with `Package.swift`. Makefile wraps `swift build` and assembles `.app` bundle.
- `make build` compiles + assembles. `make run` builds + launches. `make clean` removes artifacts.
- `.app` bundle requires `Info.plist` with `LSUIElement=true` (no dock icon).

## Hotkey
- Carbon `RegisterEventHotKey` for global hotkey (not `NSEvent.addGlobalMonitorForEvents`).
- Cmd+Space default. Detect Spotlight conflict on first launch; offer alternatives.

## Panel
- Borderless `NSPanel` with `.nonactivatingPanel`, `isFloatingPanel=true`, `level=.floating`.
- `hidePanel()` must call `NSApp.hide(nil)` to return focus to previous app.
- Focus text field by walking view hierarchy to find editable `NSTextField`, not the NSHostingView.

## Search & Ranking
- FuzzyMatcher.swift scores results with bonuses for consecutive, prefix, and word-start matches.
- RecentApps.swift boosts recently launched apps. Stored in UserDefaults as JSON.
- SystemSettings.swift contains a hardcoded list of Settings pane URLs — not discovered dynamically. Add new panes here manually.
- Three LaunchItem kinds: `.application`, `.systemSetting`, `.action`.

## App Discovery
- `FileManager.contentsOfDirectory` on `/Applications` and `/System/Applications`.
- Recurse into regular directories, stop at `.app` bundles.
- No `mdfind`, no `NSMetadataQuery`, no background indexing.

## Permissions
- Do NOT prompt for Accessibility. Carbon hotkeys don't need it, and rebuilds invalidate the binary hash.
- Explain App Management permission to user before triggering login item registration.
- Only ask once (track in UserDefaults).

## Releasing a New Version

1. Update `CHANGELOG.md` with a new `## [X.Y.Z] - YYYY-MM-DD` section.
2. Commit: `git commit -am "Release vX.Y.Z"`
3. Tag and push: `git tag vX.Y.Z && git push origin master vX.Y.Z`
4. Wait for CI: `gh run watch`
5. Upgrade locally: `brew update && brew upgrade --cask occam`

Or use `scripts/release.sh X.Y.Z` which does steps 1-3 interactively.

CI automatically builds, signs, notarizes, creates the GitHub Release, and updates the Homebrew tap. Do NOT manually update `Info.plist` version, `Casks/occam.rb`, or `mpalczew/homebrew-occam`.

### Homebrew
- Install: `brew tap mpalczew/occam && brew install --cask occam`
- Canonical cask lives in [`mpalczew/homebrew-occam`](https://github.com/mpalczew/homebrew-occam). The copy in this repo is for reference only.

### CI Secrets (already configured)
`DEVELOPER_ID_CERTIFICATE_P12_BASE64`, `DEVELOPER_ID_CERTIFICATE_PASSWORD`, `NOTARIZE_APPLE_ID`, `NOTARIZE_PASSWORD`, `NOTARIZE_TEAM_ID`, `HOMEBREW_TAP_TOKEN`

### Screenshot Tests
- CI compares `--screenshot` output against `assets/screenshot.png` via ImageMagick RMSE.
- If UI changes, run `make screenshot` locally and commit the updated image.
