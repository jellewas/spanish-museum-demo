// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PronunciationCore",
    products: [
        .library(name: "PronunciationCore", targets: ["PronunciationCore"]),
    ],
    targets: [
        .target(name: "PronunciationCore"),
        .testTarget(name: "PronunciationCoreTests", dependencies: ["PronunciationCore"]),
    ]
)
