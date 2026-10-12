// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "JumpRopeCore",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "JumpRopeCore", targets: ["JumpRopeCore"])],
    targets: [
        .target(name: "JumpRopeCore", path: "Core"),
        .testTarget(name: "JumpRopeCoreTests", dependencies: ["JumpRopeCore"], path: "Tests/JumpRopeCoreTests")
    ]
)
