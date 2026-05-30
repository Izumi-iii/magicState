// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MagicStateCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MagicStateCore", targets: ["MagicStateCore"])
    ],
    targets: [
        .target(
            name: "MagicStateCore",
            path: "magicState/Core"
        ),
        .testTarget(
            name: "MagicStateCoreTests",
            dependencies: ["MagicStateCore"],
            path: "magicStateCoreTests"
        )
    ]
)
