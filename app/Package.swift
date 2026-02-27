// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Everkey",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "EverkeyEngine", targets: ["EverkeyEngine"]),
        .executable(name: "Everkey", targets: ["Everkey"]),
    ],
    targets: [
        .target(name: "EverkeyEngine"),
        .executableTarget(name: "Everkey", dependencies: ["EverkeyEngine"]),
        .testTarget(name: "EverkeyEngineTests", dependencies: ["EverkeyEngine"]),
    ]
)
