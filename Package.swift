// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HumanizeBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "HumanizeBar",
            path: "Sources/HumanizeBar"
        ),
        .testTarget(
            name: "HumanizeBarTests",
            dependencies: ["HumanizeBar"],
            path: "Tests/HumanizeBarTests"
        ),
    ]
)
