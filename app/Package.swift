// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "EverkeyEngine",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "EverkeyEngine", targets: ["EverkeyEngine"]),
    ],
    targets: [
        .target(name: "EverkeyEngine"),
        .testTarget(name: "EverkeyEngineTests", dependencies: ["EverkeyEngine"]),
    ]
)
