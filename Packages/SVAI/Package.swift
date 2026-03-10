// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVAI",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVAI", targets: ["SVAI"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVAI",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVAITests",
            dependencies: ["SVAI"]
        ),
    ]
)
