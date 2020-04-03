// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CloudSync",
    platforms: [
        .iOS(.v11),
        .watchOS(.v2),
        .tvOS(.v11),
        .macOS(.v10_13),
    ],
    products: [
        .library(
            name: "CloudSync",
            targets: ["CloudSync"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/ashleymills/Reachability.swift",
            from: "5.0.0"
        ),
    ],
    targets: [
        .target(
            name: "CloudSync",
            dependencies: ["Reachability"]
        ),
    ]
)
