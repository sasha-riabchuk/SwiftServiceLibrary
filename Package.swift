// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServiceLibrary",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(
            name: "ServiceLibrary",
            targets: ["ServiceLibrary"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ServiceLibrary",
            dependencies: [],
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "ServiceLibraryTests",
            dependencies: ["ServiceLibrary"]
        )
    ]
)
