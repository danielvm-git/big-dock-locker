// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DockLock",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DockLock",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "DockLockTests",
            dependencies: ["DockLock"]
        ),
    ]
)
