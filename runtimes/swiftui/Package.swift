// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OwlKit",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "OwlKit", targets: ["OwlKit"]),
        .executable(name: "OwlBoard", targets: ["OwlBoard"]),
    ],
    targets: [
        // The language is ../quickshell/Owl.js, run by JavaScriptCore: Resources/Owl.js is a copy of it, which
        // test/run.sh and the tests hold to the original.
        .target(name: "OwlKit", resources: [.copy("Resources/Owl.js")]),
        // test/run.sh's walk.js under JavaScriptCore instead of node, for the parity check.
        .executableTarget(name: "owl-walk", dependencies: ["OwlKit"]),
        .executableTarget(name: "OwlBoard", dependencies: ["OwlKit"]),
        // One widget drawn offscreen to a PNG, for snapshots and for looking without a window.
        .executableTarget(name: "owl-render", dependencies: ["OwlKit"]),
        .testTarget(name: "OwlKitTests", dependencies: ["OwlKit"]),
    ]
)
