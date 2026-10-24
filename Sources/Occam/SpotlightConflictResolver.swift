import AppKit

enum SpotlightConflictResolver {
    private static let dialogVersionKey = "occam_spotlight_dialog_version"

    static func resolveIfNeeded() {
        let hotkey = HotkeyConfig.current
        guard hotkey == .cmdSpace else { return }
        guard isSpotlightUsingCmdSpace() else { return }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        if UserDefaults.standard.string(forKey: Self.dialogVersionKey) == currentVersion {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Cmd+Space is assigned to Spotlight"
        alert.informativeText = "Spotlight currently owns Cmd+Space. Occam can disable Spotlight's shortcut for you (takes effect immediately), or you can use Option+Space instead."
        alert.alertStyle = .informational

        alert.addButton(withTitle: "Disable Spotlight Shortcut")
        alert.addButton(withTitle: "Open Keyboard Settings")
        alert.addButton(withTitle: "Use Option+Space")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            disableSpotlightShortcut()
        case .alertSecondButtonReturn:
            openKeyboardSettings()
        case .alertThirdButtonReturn:
            HotkeyConfig.save(.optionSpace)
        default:
            break
        }

        UserDefaults.standard.set(currentVersion, forKey: Self.dialogVersionKey)
    }

    private static func isSpotlightUsingCmdSpace() -> Bool {
        guard let prefs = UserDefaults(suiteName: "com.apple.symbolichotkeys"),
              let hotkeys = prefs.dictionary(forKey: "AppleSymbolicHotKeys"),
              let entry = hotkeys["64"] as? [String: Any],
              let enabled = entry["enabled"] as? Bool else {
            return true
        }
        return enabled
    }

    private static func disableSpotlightShortcut() {
        let defaults = Process()
        defaults.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        defaults.arguments = [
            "write", "com.apple.symbolichotkeys",
            "AppleSymbolicHotKeys", "-dict-add", "64",
            "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
        ]
        try? defaults.run()
        defaults.waitUntilExit()

        let activate = Process()
        activate.executableURL = URL(fileURLWithPath: "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings")
        activate.arguments = ["-u"]
        try? activate.run()
        activate.waitUntilExit()

        let info = NSAlert()
        info.messageText = "Spotlight shortcut disabled"
        info.informativeText = "Cmd+Space is now available for Occam. You can re-enable Spotlight's shortcut in System Settings > Keyboard > Keyboard Shortcuts > Spotlight."
        info.alertStyle = .informational
        info.runModal()
    }

    private static func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
