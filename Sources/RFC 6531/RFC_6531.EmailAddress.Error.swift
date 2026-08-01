// RFC_6531.EmailAddress.Error.swift
// swift-rfc-6531
//
// Error types for RFC 6531 email address parsing

public import RFC_5321
public import RFC_5322

extension RFC_6531.EmailAddress {
    /// Errors that can occur when parsing an RFC 6531 email address
    public enum Error: Swift.Error, Sendable, Equatable {
        case missingAtSign
        case invalidLocalPart(_ underlying: LocalPart.Error)
        case invalidDomain(_ description: String)
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

