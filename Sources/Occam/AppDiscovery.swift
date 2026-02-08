import Foundation
import AppKit

enum AppDiscovery {
    private static let rootDirectories = [
        URL(fileURLWithPath: "/Applications"),
        URL(fileURLWithPath: "/System/Applications"),
        URL(fileURLWithPath: "/System/Library/CoreServices/Applications"),
    ]

    static func scanApplications() -> [LaunchItem] {
        var items: [LaunchItem] = []
        for dir in rootDirectories {
            scanDirectory(dir, into: &items)
        }
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
