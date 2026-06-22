// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HanaEdit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HanaEdit", targets: ["HanaEdit"])
    ],
    targets: [
        .executableTarget(
            name: "HanaEdit",
            path: "Sources/HanaEdit"
        )
    ]
)
