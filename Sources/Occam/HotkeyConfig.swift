import AppKit
import Carbon

enum HotkeyConfig {
    static let userDefaultsKey = "occam_hotkey"

    enum Hotkey: String {
        case cmdSpace = "cmd_space"
        case optionSpace = "option_space"

        var carbonKeyCode: UInt32 { UInt32(kVK_Space) }

        var carbonModifiers: UInt32 {
            switch self {
            case .cmdSpace: return UInt32(cmdKey)
            case .optionSpace: return UInt32(optionKey)
            }
        }

        var modifierFlag: NSEvent.ModifierFlags {
            switch self {
            case .cmdSpace: return .command
            case .optionSpace: return .option
            }
        }

        var displayName: String {
            switch self {
            case .cmdSpace: return "Cmd+Space"
            case .optionSpace: return "Option+Space"
            }
        }
    }

    static var current: Hotkey {
        if let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
           let hotkey = Hotkey(rawValue: raw) {
            return hotkey
        }
        return .cmdSpace
    }

    static func save(_ hotkey: Hotkey) {
        UserDefaults.standard.set(hotkey.rawValue, forKey: userDefaultsKey)
    }
}
