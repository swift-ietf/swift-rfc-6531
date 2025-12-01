// RFC_6531.EmailAddress.LocalPart.Error.swift
// swift-rfc-6531
//
// Error types for RFC 6531 local-part parsing

extension RFC_6531.EmailAddress.LocalPart {
    /// Errors that can occur when parsing an RFC 6531 local-part
    public enum Error: Swift.Error, Sendable, Equatable {
        case empty
        case tooLong(_ length: Int)
        case invalidUTF8Atom(_ value: String)
        case invalidQuotedString(_ value: String)
        case consecutiveDots(_ value: String)
        case leadingOrTrailingDot(_ value: String)
    }
}

extension RFC_6531.EmailAddress.LocalPart.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Local-part cannot be empty"
        case .tooLong(let length):
            return
                "Local-part UTF-8 byte length \(length) exceeds maximum of \(RFC_6531.EmailAddress.LocalPart.Limits.maxUTF8Length)"
        case .invalidUTF8Atom(let value):
            return "Invalid UTF-8 atom format: '\(value)'"
        case .invalidQuotedString(let value):
            return "Invalid quoted string format: '\(value)'"
        case .consecutiveDots(let value):
            return "Local-part cannot contain consecutive dots: '\(value)'"
        case .leadingOrTrailingDot(let value):
            return "Local-part cannot begin or end with a dot: '\(value)'"
        }
    }
}
