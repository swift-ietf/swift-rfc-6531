# Swift RFC 6531

[![CI](https://github.com/swift-standards/swift-rfc-6531/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-rfc-6531/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Swift implementation of RFC 6531: SMTP Extension for Internationalized Email (SMTPUTF8) - internationalized email address standard.

## Overview

RFC 6531 defines SMTPUTF8, an extension to SMTP that allows email addresses to contain Unicode characters. This package provides a pure Swift implementation of RFC 6531-compliant internationalized email address validation, supporting UTF-8 characters in local-parts and display names while maintaining backward compatibility with ASCII-only formats.

The package enables email addresses like `用户@example.com` or `user@例え.com`, handles UTF-8 length validation in bytes (not characters), and provides conversion utilities to downgrade to ASCII-only RFC 5321/5322 formats when needed.

## Features

- **Unicode Support**: Full UTF-8 character support in local-parts and display names
- **RFC 6531 Compliant**: Proper validation per SMTPUTF8 specification
- **UTF-8 Length Validation**: Validates length in bytes (max 64 bytes) not characters
- **Backward Compatibility**: Convert to ASCII-only RFC 5321/5322 when possible
- **Type-Safe API**: Structured components with compile-time safety
- **Display Name Support**: Parse and format addresses with internationalized display names
- **ASCII Detection**: Check if an address can be represented in ASCII-only format
- **Codable Support**: Seamless JSON encoding/decoding

## Installation

Add swift-rfc-6531 to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-rfc-6531.git", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 6531", package: "swift-rfc-6531")
    ]
)
```

## Quick Start

### Internationalized Email Addresses

```swift
import RFC_6531

// Parse internationalized email address
let email = try RFC_6531.EmailAddress("用户@example.com")
print(email.localPart.stringValue) // "用户"
print(email.domain.name) // "example.com"

// Parse with internationalized display name
let named = try RFC_6531.EmailAddress("张三 <user@example.com>")
print(named.displayName) // "张三"
print(named.address) // "user@example.com"

// Create from components
let addr = try RFC_6531.EmailAddress(
    displayName: "田中太郎",
    localPart: .init("user"),
    domain: .init("example.com")
)
print(addr.stringValue) // "田中太郎 <user@example.com>"
```

### ASCII Detection and Conversion

```swift
// Check if address is ASCII-only
let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
print(asciiEmail.isASCII) // true

let utf8Email = try RFC_6531.EmailAddress("用户@example.com")
print(utf8Email.isASCII) // false

// Convert to RFC 5321 format (ASCII-only)
do {
    let rfc5321 = try asciiEmail.toRFC5321()
    print(rfc5321.address) // "user@example.com"
} catch {
    print("Cannot convert: contains non-ASCII characters")
}

// Convert to RFC 5322 format (ASCII-only)
do {
    let rfc5322 = try asciiEmail.toRFC5322()
    print(rfc5322.address) // "user@example.com"
} catch {
    print("Cannot convert: contains non-ASCII characters")
}
```

### UTF-8 Length Validation

```swift
// Local-part limited to 64 UTF-8 bytes (not characters)
// Multi-byte characters count as multiple bytes
let chinese = "用户名"  // 9 bytes in UTF-8 (3 chars × 3 bytes each)
let email = try RFC_6531.EmailAddress("\(chinese)@example.com")

// This will throw if local-part exceeds 64 bytes
do {
    let longLocal = String(repeating: "用", count: 22) // 66 bytes
    let tooLong = try RFC_6531.EmailAddress("\(longLocal)@example.com")
} catch RFC_6531.EmailAddress.ValidationError.localPartTooLong(let bytes) {
    print("Local part too long: \(bytes) bytes")
}
```

### Validation Rules

```swift
// Valid internationalized addresses
let valid1 = try RFC_6531.EmailAddress("user@example.com")
let valid2 = try RFC_6531.EmailAddress("用户@example.com")
let valid3 = try RFC_6531.EmailAddress("user.name@example.com")

// Invalid addresses throw errors
do {
    let invalid = try RFC_6531.EmailAddress("no-at-sign")
} catch RFC_6531.EmailAddress.ValidationError.missingAtSign {
    print("Missing @ symbol")
}

do {
    let dots = try RFC_6531.EmailAddress("user..name@example.com")
} catch RFC_6531.EmailAddress.ValidationError.consecutiveDots {
    print("Cannot contain consecutive dots")
}
```

## Usage

### EmailAddress Type

Internationalized email address per RFC 6531:

```swift
public struct EmailAddress: Hashable, Sendable {
    public let displayName: String?
    public let localPart: LocalPart
    public let domain: Domain

    public init(displayName: String?, localPart: LocalPart, domain: Domain)
    public init(_ string: String) throws

    public var stringValue: String      // Full format with display name
    public var address: String     // Just the email address part
    public var isASCII: Bool           // True if ASCII-only

    public func toRFC5321() throws -> RFC_5321.EmailAddress
    public func toRFC5322() throws -> RFC_5322.EmailAddress
}
```

### LocalPart Type

UTF-8 compliant local-part:

```swift
public struct LocalPart: Hashable, Sendable {
    public init(_ string: String) throws
    public var stringValue: String
}
```

Key features:
- Supports Unicode letters and numbers via `\p{L}` and `\p{N}`
- Length validated in UTF-8 bytes (max 64 bytes)
- Allows dots between atoms (no consecutive dots)
- Supports quoted strings with UTF-8 characters

### Validation Errors

```swift
public enum ValidationError: Error {
    case missingAtSign
    case invalidUTF8Atom(String)
    case invalidQuotedString
    case localPartTooLong(Int)  // bytes, not characters
    case consecutiveDots
    case leadingOrTrailingDot
}

public enum ConversionError: Error {
    case nonASCIICharacters
}
```

## Related Packages

### Dependencies
- [swift-rfc-1123](https://github.com/swift-standards/swift-rfc-1123) - Domain name validation
- [swift-rfc-5321](https://github.com/swift-standards/swift-rfc-5321) - SMTP email address format (ASCII-only)
- [swift-rfc-5322](https://github.com/swift-standards/swift-rfc-5322) - Internet Message Format (ASCII-only)

### Used By
- Email clients supporting internationalized addresses
- Mail servers with SMTPUTF8 support
- Contact management systems

## Requirements

- Swift 6.0+
- macOS 13.0+ / iOS 16.0+

## License

This library is released under the Apache License 2.0. See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
