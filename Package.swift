// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Occam",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Occam",
            path: "Sources/Occam"
        )
    ]
)
