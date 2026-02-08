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

### For agents: step-by-step release procedure
When the user asks to release a new version:

1. Determine the version number. Check `git tag --sort=-v:refname | head -1` for the latest tag and bump accordingly (semver).
2. Add a new section to `CHANGELOG.md` above the previous version:
   ```
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added/Changed/Fixed
   - Description of changes
   ```
3. Commit and push:
   ```
   git add CHANGELOG.md
   git commit -m "Release vX.Y.Z"
   git push origin master
   ```
4. Tag and push the tag:
   ```
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```
5. Watch CI complete: `gh run watch` — all steps must pass including "Update Homebrew tap".
6. Verify the upgrade works:
   ```
   brew update && brew upgrade --cask occam
   codesign --verify --verbose=2 /Applications/Occam.app
   spctl --assess --type exec --verbose=2 /Applications/Occam.app
   ```
   The `spctl` output must say `source=Notarized Developer ID`.

The human can also use `scripts/release.sh X.Y.Z` which does steps 1-4 interactively.

Do NOT manually update `Resources/Info.plist` version — CI does this automatically from the tag.
Do NOT manually update `Casks/occam.rb` or `mpalczew/homebrew-occam` — CI does this automatically.

### What CI does on tag push
1. Builds a universal arm64+x86_64 binary.
2. Signs with Developer ID Application certificate (hardened runtime).
3. Notarizes with Apple and staples the ticket.
4. Verifies with `codesign --verify` and `spctl --assess`.
5. Creates a GitHub Release with `Occam-{version}-universal.zip`.
6. Updates the Homebrew tap repo (`mpalczew/homebrew-occam`) with the new version and SHA256.

### Homebrew Cask
Users install via `brew tap mpalczew/occam && brew install --cask occam`.

The canonical cask formula lives in the separate repo [`mpalczew/homebrew-occam`](https://github.com/mpalczew/homebrew-occam) at `Casks/occam.rb`. CI auto-updates it on each release. The copy in this repo at `Casks/occam.rb` is for reference only — Homebrew reads from `homebrew-occam`.

### CI Secrets
The release job requires these GitHub secrets (already configured):
- `DEVELOPER_ID_CERTIFICATE_P12_BASE64` — signing certificate (.p12 base64)
- `DEVELOPER_ID_CERTIFICATE_PASSWORD` — password for the .p12
- `NOTARIZE_APPLE_ID` — Apple ID email for notarization
- `NOTARIZE_PASSWORD` — app-specific password for notarization
- `NOTARIZE_TEAM_ID` — Apple Developer Team ID (FS3CWH8867)
- `HOMEBREW_TAP_TOKEN` — fine-grained PAT with contents:write on `mpalczew/homebrew-occam`

### Screenshot Tests
- CI runs `--screenshot` mode which produces a deterministic screenshot using mock system apps.
- Compared against the checked-in `assets/screenshot.png` via ImageMagick RMSE.
- If the UI changes, CI fails. Run `make screenshot` locally and commit the updated `assets/screenshot.png`.
- The checked-in screenshot is also the README image — always in sync with the UI.
