// RFC_6531.EmailAddress.LocalPart.swift
// swift-rfc-6531
//
// Internationalized email local-part per RFC 6531

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import INCITS_4_1986
public import Parseable_ASCII_Primitives

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

// MARK: - Serialization (replacement for the retired combined ASCII serializable protocol)

extension RFC_6531.EmailAddress.LocalPart: Swift.RawRepresentable, ASCII.Serializable, Binary
        .Serializable
{
    /// Creates a local-part by validating `rawValue`, or `nil` if it is not valid.
    ///
    /// Re-provides the `Swift.RawRepresentable` requirement (previously inherited
    /// from the retired combined ASCII serializable protocol).
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }

    /// Serializes `value` as ASCII bytes into `buffer` (own `ASCII.Serializable` verb).
    ///
    /// Re-homes the conformer off the retired canonical `Serializable` tier
    /// ([FAM-012] Phase D), replacing the transitional default. Projects the
    /// rawValue's UTF-8 bytes verbatim into the `ASCII.Code` substrate — the
    /// `UInt8` lift wraps each byte without validation, so non-ASCII bytes
    /// (RFC 6531 permits them) are preserved.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    /// Serializes `value` as ASCII bytes into `buffer`.
    ///
    /// Explicit `Binary.Serializable` witness: disambiguates the two
    /// constraint-incomparable `serialize(_:into:)` defaults — a conformer-declared
    /// member out-ranks both. The bytes derive from the free `String`-RawRepresentable
    /// serializer supplied by the umbrella (`.serialized`), which projects the
    /// rawValue's UTF-8 bytes verbatim (RFC 6531 local-parts may be non-ASCII).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

extension RFC_6531.EmailAddress.LocalPart: ASCII.Parseable {
    /// Creates a local-part by validating `string`'s UTF-8 bytes.
    ///
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parse from UTF-8 bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 6531 local-parts support UTF-8 characters.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [Byte] (UTF-8 bytes)
    /// - **Codomain**: RFC_6531.EmailAddress.LocalPart (structured data)
    ///
    /// ## Performance
    ///
    /// - Zero intermediate allocations for structural validation
    /// - Single String allocation for `rawValue` storage (required)
    /// - Atoms validated via String iteration (required for Unicode properties)
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Empty check
        guard let firstByte = bytes.first else { throw Error.empty }

        // Length check
        let byteCount = bytes.count
        guard byteCount <= Limits.maxUTF8Length else { throw Error.tooLong(byteCount) }

        // Get last byte by iteration (avoids Array allocation)
        var lastByte = firstByte
        for byte in bytes { lastByte = byte }

        // Handle quoted string format
        if firstByte == ASCII.Code.quotationMark.byte {
            guard byteCount >= 2, lastByte == ASCII.Code.quotationMark.byte else {
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
            if firstByte == ASCII.Code.period.byte {
                throw Error.leadingOrTrailingDot(String(decoding: bytes, as: UTF8.self))
            }

            // Check for trailing dot
            if lastByte == ASCII.Code.period.byte {
                throw Error.leadingOrTrailingDot(String(decoding: bytes, as: UTF8.self))
            }

            // Single pass: check for consecutive dots
            var prevWasDot = false
            for byte in bytes {
                if byte == ASCII.Code.period.byte {
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
                if bytes[index] == ASCII.Code.period.byte {
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
    ) -> Bool where Bytes.Element == Byte {
        guard !bytes.isEmpty else { return false }

        for byte in bytes {
            // UTF8-non-ascii (byte >= 0x80) is allowed; the lift returns nil there.
            guard let code = try? ASCII.Code(byte) else { continue }

            // ASCII bytes must be valid atext per RFC 5322
            guard RFC_5322.isAtext(code) else {
                return false
            }
        }
        return true
    }

    /// Validates quoted string content at byte level (zero allocation)
    private static func isValidQuotedContent<Bytes: Collection>(
        _ bytes: Bytes
    ) -> Bool where Bytes.Element == Byte {
        guard !bytes.isEmpty else { return false }

        var iterator = bytes.makeIterator()
        while let byte = iterator.next() {
            if byte == ASCII.Code.reverseSolidus.byte {
                // Must be followed by " or \
                guard let next = iterator.next() else { return false }
                guard
                    next == ASCII.Code.quotationMark.byte || next == ASCII.Code.reverseSolidus.byte
                else {
                    return false
                }
            } else if byte == ASCII.Code.quotationMark.byte
                || byte == ASCII.Code.cr.byte
                || byte == ASCII.Code.lf.byte
            {
                // Unescaped quote or CR/LF not allowed
                return false
            }
            // All other bytes (including UTF-8 multi-byte sequences) are allowed
        }
        return true
    }
}

// MARK: - Required Conformances

extension RFC_6531.EmailAddress.LocalPart: CustomStringConvertible {
    /// The local-part's serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_6531.EmailAddress.LocalPart: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
