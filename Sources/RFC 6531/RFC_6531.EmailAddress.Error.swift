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

    /// Errors that can occur when converting to ASCII-only formats
    public enum ConversionError: Swift.Error, Sendable, Equatable {
        case nonASCIICharacters

        /// The ASCII components were rejected by the RFC 5321 grammar
        ///
        /// The RFC 5321 initializer validates more than the ASCII range —
        /// notably it rejects display names containing bare CR/LF bytes
        /// (header-injection hardening). Such input passes this package's
        /// ASCII pre-check but is not representable as RFC 5321.
        case notRepresentableAsRFC5321(_ underlying: RFC_5321.EmailAddress.Error)

        /// The ASCII components were rejected by the RFC 5322 grammar
        ///
        /// The RFC 5322 initializer validates more than the ASCII range —
        /// notably it rejects display names containing bare CR/LF bytes
        /// (header-injection hardening). Such input passes this package's
        /// ASCII pre-check but is not representable as RFC 5322.
        case notRepresentableAsRFC5322(_ underlying: RFC_5322.EmailAddress.Error)
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
        case .notRepresentableAsRFC5321(let underlying):
            return "Cannot convert email address to RFC 5321: \(underlying)"
        case .notRepresentableAsRFC5322(let underlying):
            return "Cannot convert email address to RFC 5322: \(underlying)"
        }
    }
}
