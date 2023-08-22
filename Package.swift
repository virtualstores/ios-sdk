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
        .package(url: "https://github.com/virtualstores/ios-foundation.git", .branchItem("development")),
        //.package(url: "https://github.com/virtualstores/ios-foundation.git", .exact("1.0.0")),
        .package(url: "https://github.com/virtualstores/ios-sensor-fusion.git", .exact("1.0.0")),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.13.1")),
        .package(url: "https://github.com/aws-amplify/aws-sdk-ios-spm.git", .exact("2.27.4")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .exactItem("0.9.16")),
    ],
    targets: [
        .target(
            name: "VSTT2",
            dependencies: [
                .target(name: "VPS"),
                .target(name: "VSPostionKit"),
                .product(name: "VSFoundation", package: "ios-foundation"),
                .product(name: "VSSensorFusion", package: "ios-sensor-fusion"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "AWSS3", package: "aws-sdk-ios-spm"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation"),
            ]),
        //.testTarget(name: "VSTT2Tests", dependencies: ["VSTT2"]),
        .binaryTarget(name: "VPS", path: "vps.xcframework"),
        .binaryTarget(name: "VSPostionKit", path: "VSPositionKit.xcframework")
    ]
)
