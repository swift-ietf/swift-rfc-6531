//
//  File.swift
//  swift-web
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

import Foundation
import RFC_1123
import RFC_5321
import RFC_5322
import RegexBuilder

/// RFC 6531 compliant email address (SMTPUTF8)
public struct EmailAddress: Hashable, Sendable {
    /// The display name, if present
    public let displayName: String?

    /// The local part (before @)
    public let localPart: LocalPart

    /// The domain part (after @)
    public let domain: RFC_1123.Domain

    /// Initialize with components
    public init(displayName: String? = nil, localPart: LocalPart, domain: RFC_1123.Domain) {
        self.displayName = displayName?.trimmingCharacters(in: .whitespaces)
        self.localPart = localPart
        self.domain = domain
    }

    /// Initialize from string representation ("Name <local@domain>" or "local@domain")
    public init(_ string: String) throws {
        // Address format regex with optional display name and proper space handling
        let displayNameCapture = /((?:\"(?:[^\"\\]|\\.)*\"|[^<]+?))\s*/

        let emailCapture = /<([^@]+)@([^>]+)>/

        let fullRegex = Regex {
            Optionally {
                displayNameCapture
            }
            emailCapture
        }

        // Try matching the full address format first (with angle brackets)
        if let match = try? fullRegex.wholeMatch(in: string) {
            let captures = match.output

            // Extract display name if present and normalize spaces
            let displayName = captures.1.map { name in
                let trimmedName = name.trimmingCharacters(in: .whitespaces)
                if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                    let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                    return withoutQuotes.replacingOccurrences(of: #"\""#, with: "\"")
                        .replacingOccurrences(of: #"\\"#, with: "\\")
                }
                return trimmedName
            }

            let localPart = String(captures.2)
            let domain = String(captures.3)

            try self.init(
                displayName: displayName,
                localPart: LocalPart(localPart),
                domain: RFC_1123.Domain(domain)
            )
        } else {
            // Try parsing as bare email address
            guard let atIndex = string.firstIndex(of: "@") else {
                throw ValidationError.missingAtSign
            }

            let localString = String(string[..<atIndex])
            let domainString = String(string[string.index(after: atIndex)...])

            try self.init(
                displayName: nil,
                localPart: LocalPart(localString),
                domain: RFC_1123.Domain(domainString)
            )
        }
    }
}

// MARK: - Local Part
extension RFC_6531.EmailAddress {
    /// RFC 6531 compliant local-part (UTF-8)
    public struct LocalPart: Hashable, Sendable, CustomStringConvertible {
        private let storage: Storage
        private let utf8Value: String

        /// Initialize with a string
        public init(_ string: String) throws {
            // Check overall length in UTF-8 bytes
            let utf8Bytes = string.utf8.count
            guard utf8Bytes <= Limits.maxUTF8Length else {
                throw ValidationError.localPartTooLong(utf8Bytes)
            }

            // Store UTF-8 value for consistent comparisons
            self.utf8Value = string

            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? RFC_6531.EmailAddress.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle UTF8-dot-atom format
            else {
                // Check for consecutive dots
                guard !string.contains("..") else {
                    throw ValidationError.consecutiveDots
                }

                // Check for leading/trailing dots
                guard !string.hasPrefix(".") && !string.hasSuffix(".") else {
                    throw ValidationError.leadingOrTrailingDot
                }

                // Validate each atom between dots
                let atoms = string.split(separator: ".", omittingEmptySubsequences: true)
                for atom in atoms {
                    guard
                        (try? RFC_6531.EmailAddress.utf8AtomRegex.wholeMatch(in: String(atom)))
                            != nil
                    else {
                        throw ValidationError.invalidUTF8Atom(String(atom))
                    }
                }

                self.storage = .utf8DotAtom(string)
            }
        }

        /// The string representation
        public var description: String {
            switch storage {
            case .utf8DotAtom(let string), .quoted(let string):
                return string
            }
        }

        // swiftlint:disable:next nesting
        private enum Storage: Hashable {
            case utf8DotAtom(String)  // UTF-8 unquoted format
            case quoted(String)  // Quoted string format
        }
    }
}

// MARK: - Constants and Validation
extension RFC_6531.EmailAddress {
    private enum Limits {
        static let maxUTF8Length = 64  // Max length in UTF-8 bytes
    }

    // Address format regex with optional display name
    nonisolated(unsafe) private static let addressRegex =
        /(?:((?:\"[^>]+\"|[^<]+)\s+))?<([^@]+)@([^>]+)>/

    // UTF-8 atom regex: allows Unicode letters and common symbols
    nonisolated(unsafe) private static let utf8AtomRegex =
        /[\p{L}\p{N}!#$%&'\*\+\-\/=\?\^_`\{\|\}~]+/

    // Quoted string regex: allows any printable character except unescaped quotes
    // Also allows UTF-8 characters
    nonisolated(unsafe) private static let quotedRegex =
        /(?:[^"\\\r\n]|\\["\\]|\p{L}|\p{N}|\p{P}|\p{S})+/
}

extension RFC_6531.EmailAddress {
    /// The complete email address string, including display name if present
    public var stringValue: String {
        if let name = displayName {
            // Quote the display name if it contains special characters or non-ASCII
            let needsQuoting = name.contains(where: {
                !$0.isLetter && !$0.isNumber && !$0.isWhitespace || $0.asciiValue == nil
            })
            let quotedName = needsQuoting ? "\"\(name)\"" : name
            return "\(quotedName) <\(localPart)@\(domain.name)>"  // Exactly one space before angle bracket
        }
        return "\(localPart)@\(domain.name)"
    }

    /// Just the email address part without display name
    public var addressValue: String {
        "\(localPart)@\(domain.name)"
    }

    /// Returns true if this is an ASCII-only email address
    public var isASCII: Bool {
        stringValue.utf8.allSatisfy { $0 < 128 }
    }
}

// MARK: - Errors
extension RFC_6531.EmailAddress {
    public enum ValidationError: Error, LocalizedError, Equatable {
        case missingAtSign
        case invalidUTF8Atom(_ atom: String)
        case invalidQuotedString
        case localPartTooLong(_ bytes: Int)
        case consecutiveDots
        case leadingOrTrailingDot

        public var errorDescription: String? {
            switch self {
            case .missingAtSign:
                return "Email address must contain @"
            case .invalidUTF8Atom(let atom):
                return "Invalid UTF-8 atom format: '\(atom)'"
            case .invalidQuotedString:
                return "Invalid quoted string format in local-part"
            case .localPartTooLong(let bytes):
                return
                    "Local-part UTF-8 byte length \(bytes) exceeds maximum of \(Limits.maxUTF8Length)"
            case .consecutiveDots:
                return "Local-part cannot contain consecutive dots"
            case .leadingOrTrailingDot:
                return "Local-part cannot begin or end with a dot"
            }
        }
    }

    public enum ConversionError: Error, LocalizedError, Equatable {
        case nonASCIICharacters

        public var errorDescription: String? {
            switch self {
            case .nonASCIICharacters:
                return "Cannot convert internationalized email address to ASCII-only format"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension RFC_6531.EmailAddress: CustomStringConvertible {
    public var description: String { stringValue }
}

extension RFC_6531.EmailAddress: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension RFC_6531.EmailAddress: RawRepresentable {
    public var rawValue: String { stringValue }
    public init?(rawValue: String) { try? self.init(rawValue) }
}

extension RFC_5321.EmailAddress {
    public init(_ emailAddress: EmailAddress) throws {
        guard emailAddress.isASCII else {
            throw EmailAddress.ConversionError.nonASCIICharacters
        }
        self = try RFC_5321.EmailAddress(
            displayName: emailAddress.displayName,
            localPart: .init(emailAddress.localPart.description),
            domain: emailAddress.domain
        )
    }
}

extension RFC_5322.EmailAddress {
    public init(_ emailAddress: EmailAddress) throws {
        guard emailAddress.isASCII else {
            throw RFC_6531.EmailAddress.ConversionError.nonASCIICharacters
        }
        self = try RFC_5322.EmailAddress(
            displayName: emailAddress.displayName,
            localPart: .init(emailAddress.localPart.description),
            domain: emailAddress.domain
        )
    }
}

