// swift-tools-version:6.2

import PackageDescription

extension String {
    static let rfc6531: Self = "RFC 6531"
}

extension Target.Dependency {
    static var rfc6531: Self { .target(name: .rfc6531) }
    static var incits41986: Self { .product(name: "INCITS 4 1986", package: "swift-incits-4-1986") }
    static var rfc1123: Self { .product(name: "RFC 1123", package: "swift-rfc-1123") }
    static var rfc5321: Self { .product(name: "RFC 5321", package: "swift-rfc-5321") }
    static var rfc5322: Self { .product(name: "RFC 5322", package: "swift-rfc-5322") }
}

let package = Package(
    name: "swift-rfc-6531",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: .rfc6531, targets: [.rfc6531]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.1.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5321.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc6531,
            dependencies: [
                .incits41986,
                .rfc1123,
                .rfc5321,
                .rfc5322
            ]
        ),
        .testTarget(
            name: .rfc6531.tests,
            dependencies: [
                .rfc6531
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
