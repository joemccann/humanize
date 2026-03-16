// swift-tools-version: 6.0
import PackageDescription

var targets: [Target] = [
    .target(name: "HumanizeShared", path: "shared/Sources"),
    .target(name: "HumanizeTestSupport", dependencies: ["HumanizeShared"], path: "shared/Tests/HumanizeTestSupport"),
    .executableTarget(
        name: "HumanizeBar",
        dependencies: ["HumanizeShared"],
        path: "macos/Sources"
    ),
    .executableTarget(
        name: "HumanizeLauncher",
        dependencies: ["HumanizeShared", "KeyboardShortcuts"],
        path: "launcher/Sources"
    ),
    .testTarget(name: "HumanizeSharedTests", dependencies: ["HumanizeShared", "HumanizeTestSupport"], path: "shared/Tests/HumanizeSharedTests"),
    .testTarget(name: "HumanizeBarTests", dependencies: ["HumanizeBar", "HumanizeShared", "HumanizeTestSupport"], path: "macos/Tests"),
    .testTarget(
        name: "HumanizeLauncherTests",
        dependencies: ["HumanizeLauncher", "HumanizeShared", "HumanizeTestSupport", "KeyboardShortcuts"],
        path: "launcher/Tests/HumanizeLauncherTests"
    ),
]

#if os(iOS)
targets += [
    .executableTarget(
        name: "HumanizeMobile",
        dependencies: ["HumanizeShared"],
        path: "ios/Sources"
    ),
    .testTarget(name: "HumanizeMobileTests", dependencies: ["HumanizeMobile", "HumanizeShared", "HumanizeTestSupport"], path: "ios/Tests"),
]
#endif

let package = Package(
    name: "Humanize",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "HumanizeShared", targets: ["HumanizeShared"]),
        .library(name: "HumanizeTestSupport", targets: ["HumanizeTestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.2.0"),
    ],
    targets: targets
)
