// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVSocial",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVSocial", targets: ["SVSocial"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(path: "../SVAudio")
    ],
    targets: [
        .target(
            name: "SVSocial",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SVSocialTests",
            dependencies: ["SVSocial"]
        ),
    ]
)
