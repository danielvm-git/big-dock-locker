// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DockLock",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DockLock"),
        .testTarget(
            name: "DockLockTests",
            dependencies: ["DockLock"]
        ),
    ]
)
