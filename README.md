# Occam

A minimalist macOS app launcher. No Spotlight bloat, no persistent indexing, no file leakage. Just apps.

## Install

```bash
make build
```

The app bundle is at `.build/Occam.app`. Move it to `/Applications` if you want, or run it from anywhere.

## Run

```bash
make run          # build + launch
open .build/Occam.app  # launch directly
```

## Usage

**Cmd+Space** opens the search panel (Occam will offer to disable Spotlight's shortcut on first launch).

| Key | Action |
|-----|--------|
| Cmd+Space | Toggle panel |
| Type | Fuzzy search |
| Up/Down | Navigate results |
| Enter | Launch selected |
| Cmd+1-9 | Launch by position |
| Esc | Dismiss |
| Cmd+Q | Quit Occam |

Results are sorted by most recently launched. Type "quit" or "restart" to manage Occam itself.

## What it searches

- All `.app` bundles under `/Applications` and `/System/Applications` (recursive into subdirectories, stops at `.app` bundles)
- 25 hardcoded System Settings panes (Wi-Fi, Bluetooth, Display, Sound, Keyboard, etc.)

No `mdfind`, no `NSMetadataQuery`, no background indexing. It runs a fresh `FileManager` scan each time you open the panel (~50ms for ~200 apps).

## Architecture

```
Sources/Occam/
  main.swift          # NSApplication entry point
  AppDelegate.swift   # Panel management, hotkey registration, launch logic
  SearchPanel.swift   # Borderless floating NSPanel
  SearchView.swift    # SwiftUI search UI (text field + results list)
  SearchState.swift   # Observable state, recency sorting, built-in commands
  AppDiscovery.swift  # Recursive FileManager scan of /Applications
  FuzzyMatcher.swift  # Subsequence scoring (consecutive, word-start, prefix bonuses)
  SystemSettings.swift # Hardcoded x-apple.systempreferences URLs
  HotkeyConfig.swift  # Cmd+Space / Option+Space config
  RecentApps.swift    # Launch history in UserDefaults
  LaunchItem.swift    # Data model
```

Zero external dependencies. Hybrid AppKit (NSPanel) + SwiftUI (search UI). Global hotkey via Carbon `RegisterEventHotKey`.

## How it works

- **No dock icon** (`LSUIElement = true`). Runs as a background agent.
- **Borderless floating panel** using `NSPanel` with `.nonactivatingPanel` style, vibrancy blur background.
- **Fuzzy matching** scores consecutive character runs, word-start matches, and prefix matches.
- **Recency sorting** when the search field is empty. Launches are recorded in UserDefaults.
- **Spotlight conflict** detected and resolved on first launch (disable Spotlight's shortcut or switch to Option+Space).
- **Login item** offered on first launch via `SMAppService` (requires App Management permission).

## Uninstall

```bash
make clean          # remove build artifacts
killall Occam       # stop the running process
```

To remove the login item: System Settings > General > Login Items > remove Occam.

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+
- Xcode Command Line Tools (`xcode-select --install`)
