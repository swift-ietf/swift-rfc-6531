// RFC_6531.EmailAddress.swift
// swift-rfc-6531
//
// Internationalized email address per RFC 6531

public import INCITS_4_1986
public import RFC_1123
public import RFC_5321
public import RFC_5322

extension RFC_6531 {
    /// RFC 6531 compliant internationalized email address (SMTPUTF8)
    ///
    /// Supports UTF-8 characters in the local-part and display name.
    ///
    /// ## Constraints
    ///
    /// Per RFC 6531:
    /// - Local-part may contain UTF-8 characters
    /// - Local-part maximum 64 UTF-8 bytes
    /// - Domain must be ASCII (per RFC 1123)
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try RFC_6531.EmailAddress("用户@example.com")
    /// print(email.localPart)  // "用户"
    /// print(email.domain)     // "example.com"
    /// ```
    public struct EmailAddress: Sendable, Codable {
        /// The display name, if present
        public let displayName: String?

        /// The local part (before @)
        public let localPart: LocalPart

        /// The domain part (after @)
        public let domain: RFC_1123.Domain

        /// Creates value WITHOUT validation
        ///
        /// Private to ensure all public construction goes through validation.
        private init(
            __unchecked: Void,
            displayName: String?,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) {
            self.displayName = displayName
            self.localPart = localPart
            self.domain = domain
        }

        /// Creates an email address from pre-validated components
        ///
        /// - Parameters:
        ///   - displayName: Optional display name
        ///   - localPart: The local part (before @)
        ///   - domain: The domain part (after @)
        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) {
            let trimmedDisplayName: String?
            if let name = displayName {
                // Use trimming on utf8 view (zero-copy slice)
                let trimmed = name.utf8.ascii.trimming(.ascii.whitespaces)
                trimmedDisplayName =
                    trimmed.isEmpty ? nil : String(decoding: trimmed, as: UTF8.self)
            } else {
                trimmedDisplayName = nil
            }
            self.init(
                __unchecked: (),
                displayName: trimmedDisplayName,
                localPart: localPart,
                domain: domain
            )
        }
    }
}

// MARK: - Computed Properties

extension RFC_6531.EmailAddress {
    /// Just the email address part without display name
    public var address: String {
        "\(localPart)@\(domain.name)"
    }

    /// Returns true if this is an ASCII-only email address
    public var isASCII: Bool {
        localPart.rawValue.utf8.allSatisfy { $0 < 128 }
            && (displayName?.utf8.allSatisfy { $0 < 128 } ?? true)
    }

    /// The raw string value
    public var rawValue: String { String(self) }
}

// MARK: - UInt8.ASCII.Serializable

extension RFC_6531.EmailAddress: UInt8.ASCII.Serializable {
    /// Serialize to byte buffer
    ///
    /// ## Category Theory
    ///
    /// Serialization (natural transformation):
    /// - **Domain**: RFC_6531.EmailAddress (structured data)
    /// - **Codomain**: [UInt8] (UTF-8 bytes)
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        let estimatedCapacity =
            (value.displayName?.utf8.count ?? 0)
            + value.localPart.rawValue.utf8.count
            + value.domain.name.utf8.count + 10
        buffer.reserveCapacity(buffer.count + estimatedCapacity)

        if let displayName = value.displayName {
            // Check if needs quoting (non-ASCII or special chars)
            let needsQuoting = displayName.utf8.contains(where: { byte in
                !(byte.ascii.isLetter || byte.ascii.isDigit || byte.ascii.isWhitespace)
            })

            if needsQuoting {
                buffer.append(UInt8.ascii.quotationMark)
                buffer.append(contentsOf: displayName.utf8)
                buffer.append(UInt8.ascii.quotationMark)
            } else {
                buffer.append(contentsOf: displayName.utf8)
            }

            buffer.append(UInt8.ascii.space)
            buffer.append(UInt8.ascii.lessThanSign)
        }

        buffer.append(contentsOf: value.localPart.rawValue.utf8)
        buffer.append(UInt8.ascii.commercialAt)
        buffer.append(contentsOf: value.domain.name.utf8)

        if value.displayName != nil {
            buffer.append(UInt8.ascii.greaterThanSign)
        }
    }

    /// Parse from UTF-8 bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (UTF-8 bytes)
    /// - **Codomain**: RFC_6531.EmailAddress (structured data)
    ///
    /// ## Performance
    ///
    /// - Zero intermediate Array allocations
    /// - Uses zero-copy slices for all byte ranges
    /// - Single String allocation only for display name (when present)
    ///
    /// Supports formats:
    /// - `local@domain`
    /// - `Display Name <local@domain>`
    /// - `"Quoted Name" <local@domain>`
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        // Find key positions at byte level (single pass)
        var lessThanIndex: Bytes.Index?
        var greaterThanIndex: Bytes.Index?
        var lastAtIndex: Bytes.Index?

        for index in bytes.indices {
            switch bytes[index] {
            case UInt8.ascii.lessThanSign:
                lessThanIndex = index
            case UInt8.ascii.greaterThanSign:
                greaterThanIndex = index
            case UInt8.ascii.commercialAt:
                lastAtIndex = index
            default:
                break
            }
        }

        // Check for angle bracket format: Display Name <local@domain>
        if let lt = lessThanIndex, let gt = greaterThanIndex, lt < gt {
            // Extract display name bytes (everything before <) - zero-copy slice
            let displayNameBytes = bytes[..<lt].ascii.trimming(.ascii.whitespaces)

            let displayName: String?
            if displayNameBytes.isEmpty {
                displayName = nil
            } else {
                // Get first/last bytes by iteration (avoids Array allocation)
                var firstByte: UInt8?
                var lastByte: UInt8?
                var byteCount = 0
                for byte in displayNameBytes {
                    if firstByte == nil { firstByte = byte }
                    lastByte = byte
                    byteCount += 1
                }

                if let first = firstByte,
                    let last = lastByte,
                    first == UInt8.ascii.quotationMark,
                    last == UInt8.ascii.quotationMark,
                    byteCount >= 2 {
                    // Quoted display name - remove quotes and unescape
                    let unquotedBytes = displayNameBytes.dropFirst().dropLast()
                    displayName = Self.unescapeQuotedString(unquotedBytes)
                } else {
                    displayName = String(decoding: displayNameBytes, as: UTF8.self)
                }
            }

            // Extract email part (between < and >) - zero-copy slice
            let emailBytes = bytes[bytes.index(after: lt)..<gt]

            // Find @ in email part
            var emailAtIndex: Bytes.Index?
            for index in emailBytes.indices {
                if emailBytes[index] == UInt8.ascii.commercialAt {
                    emailAtIndex = index
                }
            }

            guard let atIdx = emailAtIndex else {
                throw Error.missingAtSign
            }

            // Zero-copy slices for local and domain parts
            let localBytes = emailBytes[..<atIdx]
            let domainBytes = emailBytes[emailBytes.index(after: atIdx)...]

            do {
                let localPart = try LocalPart(ascii: localBytes)
                let domain = try RFC_1123.Domain(ascii: domainBytes)
                self.init(
                    __unchecked: (),
                    displayName: displayName,
                    localPart: localPart,
                    domain: domain
                )
            } catch let error as LocalPart.Error {
                throw Error.invalidLocalPart(error)
            } catch {
                throw Error.invalidDomain(String(describing: error))
            }
        } else {
            // Bare email address: local@domain
            guard let atIdx = lastAtIndex else {
                throw Error.missingAtSign
            }

            // Zero-copy slices for local and domain parts
            let localBytes = bytes[..<atIdx]
            let domainBytes = bytes[bytes.index(after: atIdx)...]

            do {
                let localPart = try LocalPart(ascii: localBytes)
                let domain = try RFC_1123.Domain(ascii: domainBytes)
                self.init(
                    __unchecked: (),
                    displayName: nil,
                    localPart: localPart,
                    domain: domain
                )
            } catch let error as LocalPart.Error {
                throw Error.invalidLocalPart(error)
            } catch {
                throw Error.invalidDomain(String(describing: error))
            }
        }
    }

    /// Unescapes a quoted string at byte level
    ///
    /// Note: This allocates a result buffer only when escape sequences are present.
    private static func unescapeQuotedString<Bytes: Collection>(
        _ bytes: Bytes
    ) -> String where Bytes.Element == UInt8 {
        // Check if any escapes exist (avoid allocation if not needed)
        var hasEscapes = false
        for byte in bytes where byte == UInt8.ascii.reverseSolidus {
            hasEscapes = true
            break
        }

        if !hasEscapes {
            // No escapes - direct decode (no intermediate allocation)
            return String(decoding: bytes, as: UTF8.self)
        }

        // Has escapes - must allocate result buffer
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count)

        var iterator = bytes.makeIterator()
        while let byte: UInt8 = iterator.next() {
            if byte == UInt8.ascii.reverseSolidus {
                // Escape sequence - take next byte literally
                if let next: UInt8 = iterator.next() {
                    result.append(next)
                }
            } else {
                result.append(byte)
            }
        }
        return String(decoding: result, as: UTF8.self)
    }
}

// MARK: - Required Conformances

extension RFC_6531.EmailAddress: UInt8.ASCII.RawRepresentable {}

extension RFC_6531.EmailAddress: CustomStringConvertible {
    public var description: String { String(self) }
}

extension RFC_6531.EmailAddress: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(localPart)
        hasher.combine(domain)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.displayName == rhs.displayName
            && lhs.localPart == rhs.localPart
            && lhs.domain == rhs.domain
    }
}

extension RFC_6531.EmailAddress: RawRepresentable {
    public init?(rawValue: String) { try? self.init(rawValue) }
}

// MARK: - Conversion to RFC 5321/5322

extension RFC_5321.EmailAddress {
    /// Creates an RFC 5321 email address from an RFC 6531 address
    ///
    /// - Throws: `RFC_6531.EmailAddress.ConversionError.nonASCIICharacters` if the address contains non-ASCII
    public init(_ emailAddress: RFC_6531.EmailAddress) throws {
        guard emailAddress.isASCII else {
            throw RFC_6531.EmailAddress.ConversionError.nonASCIICharacters
        }
        self = try RFC_5321.EmailAddress(
            displayName: emailAddress.displayName,
            localPart: .init(emailAddress.localPart.rawValue),
            domain: emailAddress.domain
        )
    }
}

extension RFC_5322.EmailAddress {
    /// Creates an RFC 5322 email address from an RFC 6531 address
    ///
    /// - Throws: `RFC_6531.EmailAddress.ConversionError.nonASCIICharacters` if the address contains non-ASCII
    public init(_ emailAddress: RFC_6531.EmailAddress) throws {
        guard emailAddress.isASCII else {
            throw RFC_6531.EmailAddress.ConversionError.nonASCIICharacters
        }
        self = try RFC_5322.EmailAddress(
            displayName: emailAddress.displayName,
            localPart: .init(emailAddress.localPart.rawValue),
            domain: emailAddress.domain
        )
    }
}
