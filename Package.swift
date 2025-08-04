// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EdiNetworkKit",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(
            name: "EdiNetworkKit",
            targets: ["EdiNetworkKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EdiNetworkKit",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "EdiNetworkKitTests",
            dependencies: ["EdiNetworkKit"]
        )
    ]
)
