// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "CryptoUtils",
    products: [
        .library(
            name: "CryptoUtils",
            targets: ["CryptoUtils"]
        ),
    ],
    targets: [
        .target(
            name: "CryptoUtils"
        ),
        .testTarget(
            name: "CryptoUtilsTests",
            dependencies: ["CryptoUtils"]
        ),
    ]
)
