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
        .target(name: "HumanizeShared", path: "shared/Sources"),
        .target(name: "HumanizeTestSupport", dependencies: ["HumanizeShared"], path: "shared/Tests/HumanizeTestSupport"),
        .executableTarget(
            name: "HumanizeBar",
            dependencies: ["HumanizeShared"],
            path: "macos/Sources"
        ),
        .executableTarget(
            name: "HumanizeMobile",
            dependencies: ["HumanizeShared"],
            path: "ios/Sources"
        ),
        .testTarget(name: "HumanizeSharedTests", dependencies: ["HumanizeShared", "HumanizeTestSupport"], path: "shared/Tests/HumanizeSharedTests"),
        .testTarget(name: "HumanizeBarTests", dependencies: ["HumanizeBar", "HumanizeShared", "HumanizeTestSupport"], path: "macos/Tests"),
        .testTarget(name: "HumanizeMobileTests", dependencies: ["HumanizeMobile", "HumanizeShared", "HumanizeTestSupport"], path: "ios/Tests"),
    ]
)
