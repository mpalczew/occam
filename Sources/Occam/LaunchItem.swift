import Foundation

struct LaunchItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
    let kind: Kind
    let keywords: [String]

    init(name: String, url: URL, kind: Kind, keywords: [String] = []) {
        self.name = name
        self.url = url
        self.kind = kind
        self.keywords = keywords
    }

    enum Kind {
        case application
        case systemSetting
        case action(() -> Void)
    }
}
