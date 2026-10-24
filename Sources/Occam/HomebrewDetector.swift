import Foundation

enum HomebrewDetector {
    static var isHomebrewManaged: Bool {
        let bundlePath = Bundle.main.bundlePath
        let caskroomPaths = [
            "/opt/homebrew/Caskroom/occam",
            "/usr/local/Caskroom/occam",
        ]

        let fm = FileManager.default
        for caskroom in caskroomPaths {
            guard fm.fileExists(atPath: caskroom),
                  let versions = try? fm.contentsOfDirectory(atPath: caskroom) else { continue }
            for version in versions where version != ".metadata" {
                let symlinkPath = "\(caskroom)/\(version)/Occam.app"
                if let dest = try? fm.destinationOfSymbolicLink(atPath: symlinkPath),
                   dest == bundlePath {
                    return true
                }
            }
        }
        return false
    }
}
