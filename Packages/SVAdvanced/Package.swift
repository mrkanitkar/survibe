// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVAdvanced",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVAdvanced", targets: ["SVAdvanced"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(path: "../SVAudio"),
        .package(path: "../SVAI")
    ],
    targets: [
        .target(
            name: "SVAdvanced",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
                .product(name: "SVAI", package: "SVAI"),
            ]
        ),
        .testTarget(
            name: "SVAdvancedTests",
            dependencies: ["SVAdvanced"]
        ),
    ]
)
