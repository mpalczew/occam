/// Carbon virtual key codes used by the local key monitor.
/// Raw values from Events.h / HIToolbox.
enum KeyCode: UInt16 {
    case escape    = 53
    case returnKey = 36
    case downArrow = 125
    case upArrow   = 126
    case q         = 12
    case digit1    = 18
    case digit2    = 19
    case digit3    = 20
    case digit4    = 21
    case digit5    = 23
    case digit6    = 22
    case digit7    = 26
    case digit8    = 28
    case digit9    = 25

    /// Returns the digit (1-9) for Cmd+N shortcuts, or nil if not a digit key.
    var digit: Int? {
        switch self {
        case .digit1: return 1
        case .digit2: return 2
        case .digit3: return 3
        case .digit4: return 4
        case .digit5: return 5
        case .digit6: return 6
        case .digit7: return 7
        case .digit8: return 8
        case .digit9: return 9
        default: return nil
        }
    }
}
