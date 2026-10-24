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
    private let autoUpdater = AutoUpdater()
    private var isActionRunning = false
    var screenshotOutputPath: String?
    var checkUpdateMode = false

    private var isScreenshotMode: Bool { screenshotOutputPath != nil }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if checkUpdateMode {
            runCheckUpdateAndExit()
            return
        }

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
            panel.centerOnScreen()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            captureAndExit(to: screenshotOutputPath!)
            return
        }

        offerOnboarding()
        SpotlightConflictResolver.resolveIfNeeded()
        registerCarbonHotkey()
        registerLocalMonitor()
        registerClickOutsideMonitor()

        autoUpdater.isPanelHidden = { [weak self] in !(self?.panel.isVisible ?? false) }
        autoUpdater.startMonitoring()

        if !CommandLine.arguments.contains("--after-update") {
            showPanel()
        }
    }

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
        guard !isActionRunning else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func launch(_ item: LaunchItem) {
        switch item.kind {
        case .action(let action):
            hidePanel()
            isActionRunning = true
            action()
            isActionRunning = false
        default:
            RecentApps.record(item)
            hidePanel()
            NSWorkspace.shared.open(item.url)
        }
    }

    private func captureAndExit(to path: String) {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self,
                  let contentView = self.panel.contentView,
                  let bitmapRep = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds)
            else { _exit(1) }

            contentView.cacheDisplay(in: contentView.bounds, to: bitmapRep)

            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else { _exit(1) }

            let url = URL(fileURLWithPath: path)
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try? pngData.write(to: url)
            _exit(0)
        }
    }

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
            signature: OSType(0x4F43414D),
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

    private func registerLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            guard let key = KeyCode(rawValue: event.keyCode),
                  let command = KeyCommand.resolve(
                      key: key,
                      commandHeld: event.modifierFlags.contains(.command),
                      panelVisible: self.panel.isVisible
                  )
            else { return event }

            switch command {
            case .quit:
                NSApp.terminate(nil)
            case .launchIndex(let index):
                if let item = self.searchState.filteredItems[safe: index] {
                    self.launch(item)
                }
            case .dismiss:
                self.hidePanel()
            case .launchSelected:
                if let item = self.searchState.selectedItem {
                    self.launch(item)
                }
            case .moveDown:
                self.searchState.moveSelectionDown()
            case .moveUp:
                self.searchState.moveSelectionUp()
            }
            return nil
        }
    }

    private func registerClickOutsideMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.panel.isVisible else { return }
            self.hidePanel()
        }
    }

    private func runCheckUpdateAndExit() {
        autoUpdater.checkNow { message in
            print("Occam: \(message)")
            fflush(stdout)
            _exit(0)
        }
        RunLoop.current.run()
    }

    private static let onboardingOfferedKey = "occam_onboarding_offered"

    private func offerOnboarding() {
        guard !UserDefaults.standard.bool(forKey: Self.onboardingOfferedKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.onboardingOfferedKey)

        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            let loginCheckbox = NSButton(checkboxWithTitle: "Start Occam at login", target: nil, action: nil)
            loginCheckbox.state = .on

            let updateCheckbox = NSButton(checkboxWithTitle: "Keep Occam automatically updated", target: nil, action: nil)
            updateCheckbox.state = .on

            let stack = NSStackView(views: [loginCheckbox, updateCheckbox])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 8
            stack.setFrameSize(NSSize(width: 300, height: 52))

            let alert = NSAlert()
            alert.messageText = "Welcome to Occam"
            alert.informativeText = "Occam runs in the background to listen for your hotkey."
            alert.alertStyle = .informational
            alert.accessoryView = stack
            alert.addButton(withTitle: "Continue")

            alert.runModal()

            if loginCheckbox.state == .on {
                try? service.register()
            }
            AutoUpdater.isEnabled = updateCheckbox.state == .on
        }
    }
}

