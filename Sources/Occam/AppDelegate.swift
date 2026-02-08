import AppKit
import Carbon
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: SearchPanel!
    private var searchState: SearchState!
    private var hotKeyRef: EventHotKeyRef?
    private var localMonitor: Any?
    private var clickMonitor: Any?
    var screenshotOutputPath: String?

    private var isScreenshotMode: Bool { screenshotOutputPath != nil }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        searchState = SearchState()

        if isScreenshotMode {
            searchState.loadMockItems()
        } else {
            searchState.loadItems()
        }

        let panelRect = NSRect(x: 0, y: 0, width: 680, height: 420)
        panel = SearchPanel(contentRect: panelRect)

        let searchView = SearchView(
            state: searchState,
            onLaunch: { [weak self] item in self?.launch(item) },
            onDismiss: { [weak self] in self?.hidePanel() }
        )
        panel.contentView = NSHostingView(rootView: searchView)
        panel.centerOnScreen()

        if isScreenshotMode {
            // Leave query empty to show all apps with icons
            panel.centerOnScreen()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            captureAndExit(to: screenshotOutputPath!)
            return
        }

        offerLoginItem()
        handleSpotlightConflict()
        registerCarbonHotkey()
        registerLocalMonitor()
        registerClickOutsideMonitor()

        showPanel()
    }

    // MARK: - Panel Management

    private func showPanel() {
        searchState.query = ""
        searchState.loadItems()
        panel.centerOnScreen()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async { [weak self] in
            guard let contentView = self?.panel.contentView else { return }
            if let textField = self?.findTextField(in: contentView) {
                self?.panel.makeFirstResponder(textField)
            }
        }
    }

    private func hidePanel() {
        panel.orderOut(nil)
        NSApp.hide(nil)
    }

    private func findTextField(in view: NSView) -> NSTextField? {
        if let tf = view as? NSTextField, tf.isEditable {
            return tf
        }
        for subview in view.subviews {
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }

    private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // MARK: - Launch

    private func launch(_ item: LaunchItem) {
        switch item.kind {
        case .action(let action):
            hidePanel()
            action()
        default:
            RecentApps.record(item)
            hidePanel()
            NSWorkspace.shared.open(item.url)
        }
    }

    // MARK: - Screenshot Capture

    private func captureAndExit(to path: String) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self,
                  let contentView = self.panel.contentView,
                  let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
            else { exit(1) }

            contentView.cacheDisplay(in: contentView.bounds, to: bitmapRep)

            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else { exit(1) }

            let url = URL(fileURLWithPath: path)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? pngData.write(to: url)
            exit(0)
        }
    }

    // MARK: - Carbon Global Hotkey

    private func registerCarbonHotkey() {
        let hotkey = HotkeyConfig.current

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    delegate.togglePanel()
                }
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            nil
        )

        let hotkeyID = EventHotKeyID(
            signature: OSType(0x4F43414D), // "OCAM"
            id: 1
        )

        let status = RegisterEventHotKey(
            hotkey.carbonKeyCode,
            hotkey.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("Occam: Failed to register hotkey, status: \(status)")
        }
    }

    // MARK: - Local Key Monitor

    private func registerLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Cmd+Q to quit
            if event.keyCode == 12 && event.modifierFlags.contains(.command) {
                NSApp.terminate(nil)
                return nil
            }

            // Cmd+1 through Cmd+9 to launch by position
            if event.modifierFlags.contains(.command) {
                let digit = cmdDigit(for: event.keyCode)
                if let digit = digit, digit >= 1 && digit <= 9 {
                    let index = digit - 1
                    if let item = self.searchState.filteredItems[safe: index] {
                        self.launch(item)
                    }
                    return nil
                }
            }

            switch event.keyCode {
            case 53: // Escape
                self.hidePanel()
                return nil
            case 36: // Enter/Return
                if let item = self.searchState.selectedItem {
                    self.launch(item)
                }
                return nil
            case 125: // Down arrow
                self.searchState.moveSelectionDown()
                return nil
            case 126: // Up arrow
                self.searchState.moveSelectionUp()
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - Click Outside to Dismiss

    private func registerClickOutsideMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return }
            self.hidePanel()
        }
    }

    // MARK: - Spotlight Conflict Resolution

    private func handleSpotlightConflict() {
        let hotkey = HotkeyConfig.current
        guard hotkey == .cmdSpace else { return }
        guard isSpotlightUsingCmdSpace() else { return }

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
    }

    private func isSpotlightUsingCmdSpace() -> Bool {
        guard let prefs = UserDefaults(suiteName: "com.apple.symbolichotkeys"),
              let hotkeys = prefs.dictionary(forKey: "AppleSymbolicHotKeys"),
              let entry = hotkeys["64"] as? [String: Any],
              let enabled = entry["enabled"] as? Bool else {
            return true
        }
        return enabled
    }

    private func disableSpotlightShortcut() {
        let plistPath = NSHomeDirectory() + "/Library/Preferences/com.apple.symbolichotkeys.plist"

        let buddy = Process()
        buddy.executableURL = URL(fileURLWithPath: "/usr/libexec/PlistBuddy")
        buddy.arguments = ["-c", "Set :AppleSymbolicHotKeys:64:enabled false", plistPath]
        try? buddy.run()
        buddy.waitUntilExit()

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

    private func openKeyboardSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Login Item

    private static let loginItemOfferedKey = "occam_login_item_offered"

    private func offerLoginItem() {
        guard !UserDefaults.standard.bool(forKey: Self.loginItemOfferedKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.loginItemOfferedKey)

        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            guard service.status != .enabled else { return }

            let alert = NSAlert()
            alert.messageText = "Start Occam at login?"
            alert.informativeText = "Occam runs in the background to listen for your hotkey. macOS will ask for App Management permission to allow this."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Enable")
            alert.addButton(withTitle: "Not Now")

            if alert.runModal() == .alertFirstButtonReturn {
                try? service.register()
            }
        }
    }
}

// Map key codes to digit values for Cmd+1 through Cmd+9
private func cmdDigit(for keyCode: UInt16) -> Int? {
    switch keyCode {
    case 18: return 1  // 1
    case 19: return 2  // 2
    case 20: return 3  // 3
    case 21: return 4  // 4
    case 23: return 5  // 5
    case 22: return 6  // 6
    case 26: return 7  // 7
    case 28: return 8  // 8
    case 25: return 9  // 9
    default: return nil
    }
}
