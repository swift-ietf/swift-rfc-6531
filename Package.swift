// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc6531: Self = "RFC_6531"
}

extension Target.Dependency {
    static var rfc6531: Self { .target(name: .rfc6531) }
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
        // Add RFC dependencies here as needed
        // .package(url: "https://github.com/swift-web-standards/swift-rfc-1123.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .rfc6531,
            dependencies: [
                // Add target dependencies here
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