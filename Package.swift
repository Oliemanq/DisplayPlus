import PackageDescription

let package = Package(
    name: "ExamplePackage",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "ExamplePackage",
            targets: ["ExamplePackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/open-meteo/sdk.git", from: "1.5.0")
    ],
    targets: [
        .target(name: "Oliemanq.DisplayPlus", dependencies: [
            .product(name: "OpenMeteoSdk", package: "sdk"),
        ])
    ]
)
