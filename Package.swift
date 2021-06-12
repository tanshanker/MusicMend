// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicMend",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/chicio/ID3TagEditor", from: "4.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "MusicMend",
            dependencies: ["ID3TagEditor"],
            path: "MusicMend",
            exclude: ["Resources/Assets.xcassets"]
        ),
    ]
)
