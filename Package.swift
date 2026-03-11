// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "UpTo",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "UpTo",
            dependencies: [],
            path: "UpTo",
            exclude: ["Resources"]
        )
    ]
)
