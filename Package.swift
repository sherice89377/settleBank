// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "settleBank",
    products: [
        .library(name: "SettleBankCore", targets: ["SettleBankCore"]),
        .executable(name: "settleBank", targets: ["settleBank"]),
    ],
    targets: [
        .target(name: "SettleBankCore"),
        .executableTarget(name: "settleBank", dependencies: ["SettleBankCore"]),
        .testTarget(name: "SettleBankCoreTests", dependencies: ["SettleBankCore"]),
    ]
)
