// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WarpBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WarpBar", targets: ["WarpBar"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WarpBar",
            dependencies: [],
            path: "Sources/WarpBar"
        )
    ]
)

