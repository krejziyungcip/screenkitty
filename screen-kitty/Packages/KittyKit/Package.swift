// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KittyKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KittyKit", targets: ["KittyKit"])
    ],
    targets: [
        .target(name: "KittyKit"),
        .testTarget(name: "KittyKitTests", dependencies: ["KittyKit"])
    ]
)
