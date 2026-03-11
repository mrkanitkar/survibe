// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVAudio",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVAudio", targets: ["SVAudio"]),
    ],
    dependencies: [
        .package(path: "../SVCore"),
        .package(url: "https://github.com/AudioKit/AudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/Microtonality", from: "5.4.0")
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
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SVAudioTests",
            dependencies: ["SVAudio"]
        ),
    ]
)
