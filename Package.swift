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
        .package(url: "https://github.com/virtualstores/ios-foundation.git", .exact("0.0.9")),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.13.1")),
    ],
    targets: [
        .target(
            name: "VSTT2",
            dependencies: [
                "VSPositionKit",
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "VSFoundation", package: "ios-foundation"),
            ]),
        .testTarget(
            name: "VSTT2Tests",
            dependencies: ["VSTT2",  "VSPositionKit"]),
        .binaryTarget(
            name: "VSPositionKit",
            path: "ios-position-kit-sdk.xcframework"),
    ]
)
