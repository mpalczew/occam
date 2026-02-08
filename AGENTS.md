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

### Steps
1. Update `CHANGELOG.md` — add a new `## [X.Y.Z] - YYYY-MM-DD` section above the previous version with `### Added`, `### Changed`, `### Fixed`, etc. subsections as appropriate. Follow the [Keep a Changelog](https://keepachangelog.com/) format already used in the file.
2. Update `CFBundleVersion` and `CFBundleShortVersionString` in `Resources/Info.plist` to the new version (e.g. `1.1.0`). Use semver.
3. Commit and push to master.
4. Tag and push: `git tag v1.1.0 && git push origin v1.1.0`
5. CI (`.github/workflows/ci.yml`) automatically builds a universal arm64+x86_64 binary and creates a GitHub Release with `Occam-{version}-universal.zip` attached.
6. Update the Homebrew cask (see below).

### Homebrew Cask
Users install via `brew tap mpalczew/occam && brew install --cask occam`.

The cask formula lives in a **separate repo**: [`mpalczew/homebrew-occam`](https://github.com/mpalczew/homebrew-occam) at `Casks/occam.rb`. A copy is also kept in this repo at `Casks/occam.rb` for reference.

After a new release is published, update the cask:
1. Download the new release zip and get its SHA256: `shasum -a 256 Occam-X.Y.Z-universal.zip`
2. Edit `Casks/occam.rb` in **both** repos — update `version` and `sha256`.
3. Commit and push to `mpalczew/homebrew-occam`.
4. Commit and push to this repo.

The URL pattern is `https://github.com/mpalczew/occam/releases/download/v{version}/Occam-{version}-universal.zip` — the version in `Info.plist`, the git tag, and the cask `version` must all match.

### Screenshot Tests
- CI runs `--screenshot` mode which produces a deterministic screenshot using mock system apps.
- Compared against the checked-in `assets/screenshot.png` via ImageMagick RMSE.
- If the UI changes, CI fails. Run `make screenshot` locally and commit the updated `assets/screenshot.png`.
- The checked-in screenshot is also the README image — always in sync with the UI.
