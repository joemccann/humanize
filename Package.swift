// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Humanize",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "HumanizeShared", targets: ["HumanizeShared"]),
        .library(name: "HumanizeTestSupport", targets: ["HumanizeTestSupport"]),
    ],
    targets: [
        .target(name: "HumanizeShared", path: "Sources/HumanizeShared"),
        .target(name: "HumanizeTestSupport", dependencies: ["HumanizeShared"], path: "Tests/HumanizeTestSupport"),
        .executableTarget(name: "HumanizeBar", dependencies: ["HumanizeShared"], path: "Sources/HumanizeBar"),
        .testTarget(name: "HumanizeSharedTests", dependencies: ["HumanizeShared", "HumanizeTestSupport"], path: "Tests/HumanizeSharedTests"),
        .testTarget(name: "HumanizeBarTests", dependencies: ["HumanizeBar", "HumanizeShared", "HumanizeTestSupport"], path: "Tests/HumanizeBarTests"),
    ]
)
