import Foundation

enum SystemSettings {
    static let allItems: [LaunchItem] = [
        item("Wi-Fi", "x-apple.systempreferences:com.apple.wifi-settings-extension"),
        item("Bluetooth", "x-apple.systempreferences:com.apple.BluetoothSettings"),
        item("Network", "x-apple.systempreferences:com.apple.Network-Settings.extension"),
        item("Notifications", "x-apple.systempreferences:com.apple.Notifications-Settings.extension"),
        item("Sound", "x-apple.systempreferences:com.apple.Sound-Settings.extension"),
        item("Display", "x-apple.systempreferences:com.apple.Displays-Settings.extension"),
        item("Wallpaper", "x-apple.systempreferences:com.apple.Wallpaper-Settings.extension"),
        item("Battery", "x-apple.systempreferences:com.apple.Battery-Settings.extension"),
        item("Keyboard", "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"),
        item("Trackpad", "x-apple.systempreferences:com.apple.Trackpad-Settings.extension"),
        item("Mouse", "x-apple.systempreferences:com.apple.Mouse-Settings.extension"),
        item("Printers & Scanners", "x-apple.systempreferences:com.apple.Print-Scan-Settings.extension"),
        item("Privacy & Security", "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension"),
        item("General", "x-apple.systempreferences:com.apple.General-Settings.extension"),
        item("Appearance", "x-apple.systempreferences:com.apple.Appearance-Settings.extension"),
        item("Accessibility", "x-apple.systempreferences:com.apple.Accessibility-Settings.extension"),
        item("Desktop & Dock", "x-apple.systempreferences:com.apple.Desktop-Settings.extension"),
        item("Lock Screen", "x-apple.systempreferences:com.apple.Lock-Screen-Settings.extension"),
        item("Users & Groups", "x-apple.systempreferences:com.apple.Users-Groups-Settings.extension"),
        item("Passwords", "x-apple.systempreferences:com.apple.Passwords-Settings.extension"),
        item("Apple ID", "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings"),
        item("Focus", "x-apple.systempreferences:com.apple.Focus-Settings.extension"),
        item("Screen Time", "x-apple.systempreferences:com.apple.Screen-Time-Settings.extension"),
        item("Storage", "x-apple.systempreferences:com.apple.settings.Storage"),
        item("Sharing", "x-apple.systempreferences:com.apple.Sharing-Settings.extension"),
    ]

    private static func item(_ name: String, _ urlString: String) -> LaunchItem {
        LaunchItem(
            name: "Settings: \(name)",
            url: URL(string: urlString)!,
            kind: .systemSetting
        )
    }
}
