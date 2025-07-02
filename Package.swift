// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "ServiceLibrary",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ServiceLibrary",
            targets: ["ServiceLibrary"]
        ),
        .library(
            name: "ServiceAuthorizable",
            targets: ["ServiceAuthorizable"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ServiceLibrary",
            dependencies: ["ServiceLibraryMacros"]
        ),
        .target(
            name: "ServiceAuthorizable",
            dependencies: []
        ),
        .macro(
            name: "ServiceLibraryMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "ServiceLibraryTests",
            dependencies: ["ServiceLibrary"]
        )
    ]
)
