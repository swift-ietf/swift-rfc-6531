// RFC_6531.EmailAddress.Error.swift
// swift-rfc-6531
//
// Error types for RFC 6531 email address parsing

extension RFC_6531.EmailAddress {
    /// Errors that can occur when parsing an RFC 6531 email address
    public enum Error: Swift.Error, Sendable, Equatable {
        case missingAtSign
        case invalidLocalPart(_ underlying: LocalPart.Error)
        case invalidDomain(_ description: String)
    }

    /// Errors that can occur when converting to ASCII-only formats
    public enum ConversionError: Swift.Error, Sendable, Equatable {
        case nonASCIICharacters
    }
}

extension RFC_6531.EmailAddress.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingAtSign:
            return "Email address must contain @"
        case .invalidLocalPart(let error):
            return "Invalid local-part: \(error)"
        case .invalidDomain(let description):
            return "Invalid domain: \(description)"
        }
    }
}

extension RFC_6531.EmailAddress.ConversionError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nonASCIICharacters:
            return "Cannot convert internationalized email address to ASCII-only format"
        }
    }
}
