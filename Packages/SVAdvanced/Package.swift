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
        .package(path: "../SVAI"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVAdvanced",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
                .product(name: "SVAI", package: "SVAI"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVAdvancedTests",
            dependencies: ["SVAdvanced"]
        ),
    ]
)
