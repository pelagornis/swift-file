// swift-tools-version: 5.7
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
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        .target(name: "File"),
        .testTarget(
            name: "FileTests",
            dependencies: ["File"]
        )
    ]
)
