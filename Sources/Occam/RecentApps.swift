import Foundation

enum RecentApps {
    private static let key = "occam_recent_apps"
    private static let maxEntries = 50

    struct Entry: Codable {
        let url: String
        let timestamp: Date
    }

    static func record(_ item: LaunchItem) {
        var entries = load()
        entries.removeAll { $0.url == item.url.absoluteString }
        entries.insert(Entry(url: item.url.absoluteString, timestamp: Date()), at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        save(entries)
    }

    static func recencyRanks() -> [String: Int] {
        let entries = load()
        var ranks: [String: Int] = [:]
        for (index, entry) in entries.enumerated() {
            ranks[entry.url] = index
        }
        return ranks
    }

    private static func load() -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries
    }

    private static func save(_ entries: [Entry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
