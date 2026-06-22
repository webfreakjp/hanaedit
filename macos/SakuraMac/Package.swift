// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SakuraMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SakuraMac", targets: ["SakuraMac"])
    ],
    targets: [
        .executableTarget(
            name: "SakuraMac",
            path: "Sources/SakuraMac"
        )
    ]
)
