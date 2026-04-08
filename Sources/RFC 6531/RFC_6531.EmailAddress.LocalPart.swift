// RFC_6531.EmailAddress.LocalPart.swift
// swift-rfc-6531
//
// Internationalized email local-part per RFC 6531

public import ASCII_Serializer_Primitives
public import INCITS_4_1986

extension RFC_6531.EmailAddress {
    /// RFC 6531 compliant local-part supporting UTF-8 characters
    ///
    /// ## Constraints
    ///
    /// Per RFC 6531:
    /// - Maximum 64 UTF-8 bytes
    /// - No consecutive dots
    /// - Cannot start or end with a dot
    /// - Supports quoted strings
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_6531.EmailAddress.LocalPart("用户")
    /// print(localPart)  // "用户"
    /// ```
    public struct LocalPart: Sendable, Codable {
        public let rawValue: String
        private let storage: Storage

        /// Creates value WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(__unchecked: Void, storage: Storage, rawValue: String) {
            self.storage = storage
            self.rawValue = rawValue
        }

        // MARK: - Storage

        private enum Storage: Hashable, Sendable, Codable {
            case utf8DotAtom
            case quoted
        }
    }
}

// MARK: - Limits

extension RFC_6531.EmailAddress.LocalPart {
    package enum Limits {
        /// Maximum length in UTF-8 bytes per RFC 6531
        static let maxUTF8Length = 64
    }
}

// MARK: - Binary.ASCII.Serializable

extension RFC_6531.EmailAddress.LocalPart: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: value.rawValue.utf8)
    }

    /// Parse from UTF-8 bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 6531 local-parts support UTF-8 characters.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (UTF-8 bytes)
    /// - **Codomain**: RFC_6531.EmailAddress.LocalPart (structured data)
    ///
    /// ## Performance
    ///
    /// - Zero intermediate allocations for structural validation
    /// - Single String allocation for `rawValue` storage (required)
    /// - Atoms validated via String iteration (required for Unicode properties)
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Empty check
        guard let firstByte = bytes.first else { throw Error.empty }

        // Length check
        let byteCount = bytes.count
        guard byteCount <= Limits.maxUTF8Length else { throw Error.tooLong(byteCount) }

        // Get last byte by iteration (avoids Array allocation)
        var lastByte = firstByte
        for byte in bytes { lastByte = byte }

        // Handle quoted string format
        if firstByte == UInt8.ascii.quotationMark {
            guard byteCount >= 2, lastByte == UInt8.ascii.quotationMark else {
                throw Error.invalidQuotedString(String(decoding: bytes, as: UTF8.self))
            }

            // Validate quoted content by iteration (zero-copy)
            guard Self.isValidQuotedContent(bytes.dropFirst().dropLast()) else {
                throw Error.invalidQuotedString(String(decoding: bytes, as: UTF8.self))
            }

            self.init(
                __unchecked: (),
                storage: .quoted,
                rawValue: String(decoding: bytes, as: UTF8.self)
            )
        }
        // Handle UTF8-dot-atom format
        else {
            // Check for leading dot
            if firstByte == UInt8.ascii.period {
                throw Error.leadingOrTrailingDot(String(decoding: bytes, as: UTF8.self))
            }

            // Check for trailing dot
            if lastByte == UInt8.ascii.period {
                throw Error.leadingOrTrailingDot(String(decoding: bytes, as: UTF8.self))
            }

            // Single pass: check for consecutive dots
            var prevWasDot = false
            for byte in bytes {
                if byte == UInt8.ascii.period {
                    if prevWasDot {
                        throw Error.consecutiveDots(String(decoding: bytes, as: UTF8.self))
                    }
                    prevWasDot = true
                } else {
                    prevWasDot = false
                }
            }

            // Validate atoms at byte level - split on dots and validate each
            var atomStart = bytes.startIndex
            for index in bytes.indices {
                if bytes[index] == UInt8.ascii.period {
                    // Validate atom from atomStart to index (zero-copy slice)
                    let atomBytes = bytes[atomStart..<index]
                    guard Self.isValidUTF8Atom(atomBytes) else {
                        throw Error.invalidUTF8Atom(String(decoding: atomBytes, as: UTF8.self))
                    }
                    atomStart = bytes.index(after: index)
                }
            }
            // Validate final atom
            let finalAtomBytes = bytes[atomStart...]
            guard Self.isValidUTF8Atom(finalAtomBytes) else {
                throw Error.invalidUTF8Atom(String(decoding: finalAtomBytes, as: UTF8.self))
            }

            self.init(
                __unchecked: (),
                storage: .utf8DotAtom,
                rawValue: String(decoding: bytes, as: UTF8.self)
            )
        }
    }
}

// MARK: - Validation

extension RFC_6531.EmailAddress.LocalPart {
    /// Validates a UTF-8 atom per RFC 6531
    ///
    /// Per RFC 6531 Section 3.3, atext is extended:
    ///   `atext =/ UTF8-non-ascii`
    ///
    /// Where UTF8-non-ascii is any byte >= 0x80 (per RFC 6532/RFC 3629).
    /// This means ALL non-ASCII UTF-8 characters are allowed, including emojis.
    ///
    /// ASCII bytes must be valid atext per RFC 5322 Section 3.2.3.
    private static func isValidUTF8Atom<Bytes: Collection>(
        _ bytes: Bytes
    ) -> Bool where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { return false }

        for byte in bytes {
            // UTF8-non-ascii: any byte >= 0x80 is allowed (includes all multi-byte UTF-8)
            if byte >= 0x80 {
                continue
            }

            // ASCII bytes must be valid atext per RFC 5322
            guard RFC_5322.isAtext(byte) else {
                return false
            }
        }
        return true
    }

    /// Validates quoted string content at byte level (zero allocation)
    private static func isValidQuotedContent<Bytes: Collection>(
        _ bytes: Bytes
    ) -> Bool where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { return false }

        var iterator = bytes.makeIterator()
        while let byte: UInt8 = iterator.next() {
            if byte == UInt8.ascii.reverseSolidus {
                // Must be followed by " or \
                guard let next: UInt8 = iterator.next(),
                    next == UInt8.ascii.quotationMark || next == UInt8.ascii.reverseSolidus
                else {
                    return false
                }
            } else if byte == UInt8.ascii.quotationMark
                || byte == UInt8.ascii.cr
                || byte == UInt8.ascii.lf {
                // Unescaped quote or CR/LF not allowed
                return false
            }
            // All other bytes (including UTF-8 multi-byte sequences) are allowed
        }
        return true
    }
}

// MARK: - Required Conformances

extension RFC_6531.EmailAddress.LocalPart: Binary.ASCII.RawRepresentable {}

extension RFC_6531.EmailAddress.LocalPart: CustomStringConvertible {
    public var description: String { rawValue }
}

extension RFC_6531.EmailAddress.LocalPart: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
