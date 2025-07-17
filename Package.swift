// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSAppSyncEvents",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13)],
    products: [
        .library(
            name: "AWSAppSyncEvents",
            targets: ["AWSAppSyncEvents"]),
    ],
    targets: [
        .target(
            name: "AWSAppSyncEvents"),
        .testTarget(name: "AWSAppSyncEventsTests",
                    dependencies: ["AWSAppSyncEvents"])

    ]
)
