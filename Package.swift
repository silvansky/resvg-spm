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
            url: "https://github.com/silvansky/resvg-spm/releases/download/0.47.0-universal/resvg.xcframework.zip",
            checksum: "4ca01dbe988a749b75d4f99f984bcefe1875ecb6928e49ed8c2f85a18ef56507"
        ),
        .target(
            name: "ResvgSwift",
            dependencies: ["CResvg"]
        )
    ]
)
