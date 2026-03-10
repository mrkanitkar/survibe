// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVLearning",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVLearning", targets: ["SVLearning"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(path: "../SVAudio"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVLearning",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVLearningTests",
            dependencies: ["SVLearning"]
        ),
    ]
)
