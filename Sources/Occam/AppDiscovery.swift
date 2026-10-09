import Foundation
import AppKit

enum AppDiscovery {
    static let foldersConfigPath = "~/.config/occam/folders"

    private static let builtInRoots = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Library/CoreServices/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    static func customFolders(from text: String) -> [URL] {
        text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
            .filter { isDirectory($0) }
    }

    private static func configuredFolders() -> [URL] {
        let path = (foldersConfigPath as NSString).expandingTildeInPath
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else { return [] }
        return customFolders(from: text)
    }

    static func scanApplications() -> [LaunchItem] {
        var found: [LaunchItem] = []
        for dir in builtInRoots + configuredFolders() {
            scanDirectory(dir, into: &found)
        }
        var seen = Set<String>()
        let items = found.filter { seen.insert($0.url.path).inserted }
        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func scanDirectory(_ directory: URL, into items: inout [LaunchItem]) {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsPackageDescendants]
        ) else { return }

        for url in contents {
            if url.pathExtension == "app" {
                let resolved = url.resolvingSymlinksInPath()
                let name = displayName(for: resolved)
                items.append(LaunchItem(name: name, url: resolved, kind: .application))
            } else if isDirectory(url) {
                // Recurse into regular directories, but not .app bundles
                scanDirectory(url, into: &items)
            }
        }
    }

    private static func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }

    private static func displayName(for url: URL) -> String {
        if let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
               ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return url.deletingPathExtension().lastPathComponent
    }
}
