enum KeyCommand: Equatable {
    case quit
    case launchIndex(Int)
    case dismiss
    case launchSelected
    case moveDown
    case moveUp

    static func resolve(key: KeyCode, commandHeld: Bool, panelVisible: Bool) -> KeyCommand? {
        if key == .q && commandHeld { return .quit }
        guard panelVisible else { return nil }
        if commandHeld, let digit = key.digit { return .launchIndex(digit - 1) }
        switch key {
        case .escape: return .dismiss
        case .returnKey: return .launchSelected
        case .downArrow: return .moveDown
        case .upArrow: return .moveUp
        default: return nil
        }
    }
}
