import Foundation

/// Pure parsing of Apple's `*.searchTerms` plists and pane Info.plist data.
enum SettingsSearchTermsParser {
    static let urlPrefix = "x-apple.systempreferences:"

    static func items(bundleId: String, searchTerms: [String: Any]) -> [LaunchItem] {
        var result: [LaunchItem] = []
        for anchor in searchTerms.keys.sorted() {
            guard let entry = searchTerms[anchor] as? [String: Any],
                  let strings = entry["localizableStrings"] as? [[String: Any]],
                  let url = anchorURL(bundleId: bundleId, anchor: anchor) else { continue }
            for string in strings {
                guard let title = (string["title"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else { continue }
                result.append(LaunchItem(
                    name: "Settings: \(normalized(title))",
                    url: url,
                    kind: .systemSetting,
                    keywords: keywords(from: string["index"] as? String)
                ))
            }
        }
        return result
    }

    static func isSettingsPane(info: [String: Any]) -> Bool {
        guard let attrs = info["EXAppExtensionAttributes"] as? [String: Any],
              attrs["EXExtensionPointIdentifier"] as? String == "com.apple.Settings.extension.ui" else {
            return false
        }
        let settings = attrs["SettingsExtensionAttributes"] as? [String: Any]
        return settings?["allowsXAppleSystemPreferencesURLScheme"] as? Bool != false
    }

    /// `localize` maps a string key to its localized value, or nil when missing.
    static func paneName(info: [String: Any], localize: (String) -> String?, localizedInfo: [String: Any]?) -> String? {
        let attrs = (info["EXAppExtensionAttributes"] as? [String: Any])?["SettingsExtensionAttributes"] as? [String: Any]
        let reps = attrs?["representations"] as? [[String: Any]] ?? []
        for key in reps.compactMap({ $0["sidebar-name"] as? String }) {
            if let name = localize(key), !name.isEmpty { return name }
        }
        for source in [localizedInfo, info] {
            for key in ["CFBundleDisplayName", "CFBundleName"] {
                if let name = source?[key] as? String, !name.isEmpty { return humanized(name) }
            }
        }
        return nil
    }

    /// Turns code-style names ("HeadphoneSettingsExtension") into words ("Headphone").
    static func humanized(_ name: String) -> String {
        guard name.allSatisfy(\.isLetter) else { return name }
        var words = name.unicodeScalars.reduce(into: [String]()) { acc, scalar in
            let char = Character(scalar)
            if char.isUppercase || acc.isEmpty { acc.append(String(char)) } else { acc[acc.count - 1].append(char) }
        }
        while words.count > 1, ["Preferences", "Settings", "Extension"].contains(words[words.count - 1]) {
            words.removeLast()
        }
        return words.joined(separator: " ")
    }

    static func paneItem(bundleId: String, name: String) -> LaunchItem? {
        guard let url = URL(string: urlPrefix + bundleId) else { return nil }
        return LaunchItem(name: "Settings: \(normalized(name))", url: url, kind: .systemSetting)
    }

    /// Dedupe by name (case-insensitive), keeping the first item and merging keywords.
    static func deduped(_ items: [LaunchItem]) -> [LaunchItem] {
        var order: [String] = []
        var byName: [String: LaunchItem] = [:]
        for item in items {
            let key = item.name.lowercased()
            if let existing = byName[key] {
                var merged = existing.keywords
                for word in item.keywords where !merged.contains(word) { merged.append(word) }
                byName[key] = LaunchItem(name: existing.name, url: existing.url, kind: existing.kind, keywords: merged)
            } else {
                byName[key] = item
                order.append(key)
            }
        }
        return order.compactMap { byName[$0] }
    }

    private static func normalized(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2011}", with: "-")
    }

    private static func keywords(from index: String?) -> [String] {
        (index ?? "").split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func anchorURL(bundleId: String, anchor: String) -> URL? {
        guard let encoded = anchor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "\(urlPrefix)\(bundleId)?\(encoded)")
    }
}
