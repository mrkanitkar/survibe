// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVLearning",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVLearning", targets: ["SVLearning"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(path: "../SVAudio")
    ],
    targets: [
        .target(
            name: "SVLearning",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SVLearningTests",
            dependencies: ["SVLearning"]
        ),
    ]
)
