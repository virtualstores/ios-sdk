// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VSTT2",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "VSTT2",
            targets: ["VSTT2"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/virtualstores/ios-foundation.git", .branch("sqliteRemove")),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.13.1")),
    ],
    targets: [
        .target(
            name: "VSTT2",
            dependencies: [
                "ios-position-kit-sdk",
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "VSFoundation", package: "ios-foundation"),
            ]),
        .testTarget(
            name: "VSTT2Tests",
            dependencies: ["VSTT2",  "ios-position-kit-sdk"]),
        .binaryTarget(
            name: "ios-position-kit-sdk",
            path: "ios-position-kit-sdk.xcframework"),
    ]
)
