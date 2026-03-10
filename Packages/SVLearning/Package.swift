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
        .package(path: "../SVAudio")
    ],
    targets: [
        .target(
            name: "SVLearning",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
            ]
        ),
        .testTarget(
            name: "SVLearningTests",
            dependencies: ["SVLearning"]
        ),
    ]
)
