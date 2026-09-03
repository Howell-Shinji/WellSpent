// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WellSpent",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "WellSpent",
            path: "WellSpent/src"
        )
    ]
)
