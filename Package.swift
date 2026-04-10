// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swSTL",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "swSTLCore",
            dependencies: []
        ),
        .executableTarget(
            name: "swSTL",
            dependencies: [
                "swSTLCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "swSTLTests",
            dependencies: [
                .target(name: "swSTLCore"),
            ]
        )
    ]
)
