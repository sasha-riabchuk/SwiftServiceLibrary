// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServiceLibrary",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ServiceLibrary",
            targets: ["ServiceLibrary"]),
        .library(
            name: "ServiceAuthorizable",
            targets: ["ServiceAuthorizable"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ServiceLibrary",
            dependencies: ["ServiceLibraryMacros"]),
        .target(
            name: "ServiceAuthorizable",
            dependencies: []),
        .macro(
            name: "ServiceLibraryMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]),
        .testTarget(
            name: "ServiceLibraryTests",
            dependencies: ["ServiceLibrary"])
    ])
