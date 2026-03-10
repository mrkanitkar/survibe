// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVSocial",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVSocial", targets: ["SVSocial"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(path: "../SVAudio"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVSocial",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "SVAudio", package: "SVAudio"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVSocialTests",
            dependencies: ["SVSocial"]
        ),
    ]
)
