// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVCore",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVCore", targets: ["SVCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/PostHog/posthog-ios", from: "3.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVCore",
            dependencies: [
                .product(name: "PostHog", package: "posthog-ios"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVCoreTests",
            dependencies: ["SVCore"]
        ),
    ]
)
