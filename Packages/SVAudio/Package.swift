// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVAudio",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVAudio", targets: ["SVAudio"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/Microtonality", branch: "main"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
    ],
    targets: [
        .target(
            name: "SVAudio",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
                .product(name: "AudioKit", package: "AudioKit"),
                .product(name: "SoundpipeAudioKit", package: "SoundpipeAudioKit"),
                .product(name: "Microtonality", package: "Microtonality"),
            ],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "SVAudioTests",
            dependencies: ["SVAudio"]
        ),
    ]
)
