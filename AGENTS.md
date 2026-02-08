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

Run `scripts/release.sh X.Y.Z` (e.g. `scripts/release.sh 1.3.0`). It will:
1. Update `CHANGELOG.md` with a new version header (you fill in the entries).
2. Commit and push to master.
3. Tag `vX.Y.Z` and push the tag.

CI handles everything else automatically:
- Builds a universal arm64+x86_64 binary.
- Signs with Developer ID Application certificate (hardened runtime).
- Notarizes with Apple and staples the ticket.
- Creates a GitHub Release with `Occam-{version}-universal.zip`.
- Updates the Homebrew tap (`mpalczew/homebrew-occam`) with the new version and SHA256.

### Homebrew Cask
Users install via `brew tap mpalczew/occam && brew install --cask occam`.

The cask formula lives in [`mpalczew/homebrew-occam`](https://github.com/mpalczew/homebrew-occam) at `Casks/occam.rb`. CI auto-updates it on each release. A copy in this repo at `Casks/occam.rb` is kept for reference but is not canonical.

### CI Secrets
The release job requires these GitHub secrets (already configured):
- `DEVELOPER_ID_CERTIFICATE_P12_BASE64` — signing certificate
- `DEVELOPER_ID_CERTIFICATE_PASSWORD` — certificate password
- `NOTARIZE_APPLE_ID` — Apple ID for notarization
- `NOTARIZE_PASSWORD` — app-specific password for notarization
- `NOTARIZE_TEAM_ID` — Apple Developer Team ID
- `HOMEBREW_TAP_TOKEN` — PAT with write access to `mpalczew/homebrew-occam`

### Screenshot Tests
- CI runs `--screenshot` mode which produces a deterministic screenshot using mock system apps.
- Compared against the checked-in `assets/screenshot.png` via ImageMagick RMSE.
- If the UI changes, CI fails. Run `make screenshot` locally and commit the updated `assets/screenshot.png`.
- The checked-in screenshot is also the README image — always in sync with the UI.
