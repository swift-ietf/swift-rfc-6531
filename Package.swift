// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc6531: Self = "RFC_6531"
}

extension Target.Dependency {
    static var rfc6531: Self { .target(name: .rfc6531) }
    static var rfc1123: Self { .product(name: "RFC_1123", package: "swift-rfc-1123") }
    static var rfc5321: Self { .product(name: "RFC_5321", package: "swift-rfc-5321") }
    static var rfc5322: Self { .product(name: "RFC_5322", package: "swift-rfc-5322") }
}

let package = Package(
    name: "swift-rfc-6531",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc6531, targets: [.rfc6531]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5321.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc6531,
            dependencies: [
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

extension String { var tests: Self { self + " Tests" } }