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
        .package(url: "https://github.com/virtualstores/ios-foundation.git", from: "0.0.2-14-SNAPSHOT"),
        .package(url: "https://github.com/virtualstores/ios-sensor-interpreter.git", from: "0.0.1"),
        .package(url: "https://github.com/virtualstores/ios-sensor-fusion.git", branch: "feature/suggested-implementation"),
        .package(url: "https://github.com/virtualstores/ios-engine-wrapper.git", from: "0.0.1"),
        
    ],
    targets: [
        .target(
            name: "VSTT2",
            dependencies: [
                .product(name: "VSFoundation", package: "ios-foundation"),
                .product(name: "VSSensorInterpreter", package: "ios-sensor-interpreter"),
                .product(name: "VSEngineWrapper", package: "ios-engine-wrapper"),
                .product(name: "VSSensorFusion", package: "ios-sensor-fusion"),
            ]),
        .testTarget(
            name: "VSTT2Tests",
            dependencies: ["VSTT2"]),
    ]
)
