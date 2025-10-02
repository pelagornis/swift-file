// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-file",
    platforms: [
        .iOS(.v13), 
        .macOS(.v10_15), 
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "File",
            targets: ["File"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.3")
    ],
    targets: [
        .target(
            name: "File",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "FileTests",
            dependencies: ["File"]
        )
    ]
)
