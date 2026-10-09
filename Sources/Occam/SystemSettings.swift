import Foundation

enum SystemSettings {
    static let extensionsDirectory = URL(fileURLWithPath: "/System/Library/ExtensionKit/Extensions")

    static let allItems: [LaunchItem] = {
        let discovered = discover()
        return discovered.isEmpty ? SystemSettingsFallback.items : discovered
    }()

    static func discover() -> [LaunchItem] {
        let fm = FileManager.default
        guard let appexes = try? fm.contentsOfDirectory(at: extensionsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        var subPages: [LaunchItem] = []
        var panes: [LaunchItem] = []
        for url in appexes where url.pathExtension == "appex" {
            guard let bundle = Bundle(url: url),
                  let info = bundle.infoDictionary,
                  SettingsSearchTermsParser.isSettingsPane(info: info),
                  let bundleId = bundle.bundleIdentifier else { continue }
            for terms in searchTerms(in: bundle) {
                subPages += SettingsSearchTermsParser.items(bundleId: bundleId, searchTerms: terms)
            }
            if let pane = paneItem(bundle: bundle, info: info, bundleId: bundleId) { panes.append(pane) }
        }
        let titles = Set(subPages.map { $0.name.lowercased() })
        let uniquePanes = panes.filter { !titles.contains($0.name.lowercased()) }
        return SettingsSearchTermsParser.deduped(subPages + uniquePanes)
    }

    private static func searchTerms(in bundle: Bundle) -> [[String: Any]] {
        (bundle.urls(forResourcesWithExtension: "searchTerms", subdirectory: nil) ?? []).compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: Any]
        }
    }

    private static func paneItem(bundle: Bundle, info: [String: Any], bundleId: String) -> LaunchItem? {
        let name = SettingsSearchTermsParser.paneName(
            info: info,
            localize: { key in
                let value = bundle.localizedString(forKey: key, value: nil, table: "InfoPlist")
                return value == key ? nil : value
            },
            localizedInfo: bundle.localizedInfoDictionary
        )
        return name.flatMap { SettingsSearchTermsParser.paneItem(bundleId: bundleId, name: $0) }
    }
}
