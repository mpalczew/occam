# Changelog

All notable changes to Occam will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-02-08

### Added
- Automatic self-updating: checks GitHub Releases every 24h, downloads, verifies code signature, and silently updates when the search panel is hidden
- Combined onboarding dialog for login item and auto-update preferences
- "Disable Auto-Update" / "Enable Auto-Update" built-in action
- `--check-update` CLI flag for CI testing

### Fixed
- Zombie screenshot processes not exiting cleanly

## [1.3.0] - 2026-02-08

### Added
- Show panel when app is relaunched from dock or Finder

## [1.2.0] - 2026-02-08

### Fixed
- Safari and other hidden-symlink apps not appearing in launcher
- Safari icon showing alias arrow overlay instead of proper icon
- Keychain Access and other CoreServices apps not discoverable

## [1.1.0] - 2026-02-08

### Fixed
- Safari and other hidden-symlink apps not appearing in launcher

## [1.0.0] - 2025-02-07

### Added
- Minimalist app launcher with Cmd+Space / Option+Space global hotkey
- Fuzzy search across all applications in /Applications and /System/Applications
- 25 built-in System Settings panes (Wi-Fi, Bluetooth, Display, Sound, etc.)
- Recency-based sorting when search field is empty
- Cmd+1 through Cmd+9 quick launch shortcuts
- Spotlight conflict detection and automatic resolution
- Login item support via SMAppService
- Built-in "Quit Occam" and "Restart Occam" commands
- Vibrancy blur floating panel with rounded corners
