// swift-tools-version:6.2

import PackageDescription

extension String {
    static let rfc6531: Self = "RFC 6531"
}

extension Target.Dependency {
    static var incits41986: Self { .product(name: "ASCII", package: "swift-ascii") }
    static var rfc6531: Self { .target(name: .rfc6531) }
    static var rfc1123: Self { .product(name: "RFC 1123", package: "swift-rfc-1123") }
    static var rfc5321: Self { .product(name: "RFC 5321", package: "swift-rfc-5321") }
    static var rfc5322: Self { .product(name: "RFC 5322", package: "swift-rfc-5322") }
}

let package = Package(
    name: "swift-rfc-6531",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 6531", targets: ["RFC 6531"])
    ],
    dependencies: [
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../swift-rfc-1123"),
        .package(path: "../swift-rfc-5321"),
        .package(path: "../swift-rfc-5322")
    ],
    targets: [
        .target(
            name: "RFC 6531",
            dependencies: [
                .incits41986,
                .rfc1123,
                .rfc5321,
                .rfc5322
            ]
        ),
        .testTarget(
            name: "RFC 6531 Tests",
            dependencies: [
                "RFC 6531",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
