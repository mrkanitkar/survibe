// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SVBilling",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SVBilling", targets: ["SVBilling"]),
    ],
    dependencies: [
        .package(path: "../SVCore")
    ],
    targets: [
        .target(
            name: "SVBilling",
            dependencies: [
                .product(name: "SVCore", package: "SVCore"),
            ]
        ),
        .testTarget(
            name: "SVBillingTests",
            dependencies: ["SVBilling"]
        ),
    ]
)
