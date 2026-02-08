import AppKit
import Foundation

class SearchState: ObservableObject {
    @Published var query: String = "" {
        didSet { updateFilteredResults() }
    }
    @Published var filteredItems: [LaunchItem] = []
    @Published var selectedIndex: Int = 0

    private var allItems: [LaunchItem] = []

    var selectedItem: LaunchItem? {
        filteredItems[safe: selectedIndex]
    }

    private static let builtInActions: [LaunchItem] = [
        LaunchItem(name: "Quit Occam", url: URL(string: "occam://quit")!, kind: .action { NSApp.terminate(nil) }),
        LaunchItem(name: "Restart Occam", url: URL(string: "occam://restart")!, kind: .action {
            let bundlePath = Bundle.main.bundlePath
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = [bundlePath]
            try? task.run()
            NSApp.terminate(nil)
        }),
    ]

    func loadItems() {
        allItems = AppDiscovery.scanApplications() + SystemSettings.allItems + Self.builtInActions
        updateFilteredResults()
    }

    func loadMockItems() {
        let mockPaths = [
            "/Applications/Safari.app",
            "/System/Applications/Calculator.app",
            "/System/Applications/Calendar.app",
            "/System/Applications/FaceTime.app",
            "/System/Applications/Maps.app",
            "/System/Applications/Messages.app",
            "/System/Applications/Music.app",
            "/System/Applications/Notes.app",
            "/System/Applications/Photos.app",
            "/System/Applications/Preview.app",
            "/System/Applications/TextEdit.app",
            "/System/Applications/Utilities/Terminal.app",
        ]
        allItems = mockPaths.compactMap { path -> LaunchItem? in
            let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent
            return LaunchItem(name: name, url: url, kind: .application)
        }
        updateFilteredResults()
    }

    func moveSelectionUp() {
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func moveSelectionDown() {
        let maxIndex = min(filteredItems.count, 50) - 1
        if selectedIndex < maxIndex { selectedIndex += 1 }
    }

    private func updateFilteredResults() {
        if query.isEmpty {
            // Sort by recency: recent apps first, then alphabetical for the rest
            let ranks = RecentApps.recencyRanks()
            filteredItems = allItems.sorted { a, b in
                let rankA = ranks[a.url.absoluteString]
                let rankB = ranks[b.url.absoluteString]
                switch (rankA, rankB) {
                case let (ra?, rb?): return ra < rb
                case (_?, nil): return true
                case (nil, _?): return false
                default: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
        } else {
            filteredItems = FuzzyMatcher.filter(items: allItems, query: query)
        }
        selectedIndex = 0
    }
}
