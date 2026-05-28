// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Resvg",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Resvg", targets: ["ResvgSwift"])
    ],
    targets: [
        .binaryTarget(
            name: "CResvg",
            url: "https://github.com/silvansky/resvg-spm/releases/download/0.47.0/resvg.xcframework.zip",
            checksum: "89b3d9ca5aed95d29a9f940ee1b92d533e27000b3b2d14ad25835e1ee183b62d"
        ),
        .target(
            name: "ResvgSwift",
            dependencies: ["CResvg"]
        )
    ]
)
