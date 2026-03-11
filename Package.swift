// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "UpTo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "UpTo",
            dependencies: ["SwiftSoup"],
            path: "UpTo",
            exclude: ["Resources"]
        )
    ]
)
