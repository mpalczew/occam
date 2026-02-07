import Foundation

struct LaunchItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let kind: Kind

    enum Kind {
        case application
        case systemSetting
        case action(() -> Void)
    }
}
