import ASCII
public import Byte
import Byte
import INCITS_4_1986
public import RFC_1123
import Standard_Library_Extensions

extension RFC_6531 {

    public struct Mailbox: Hashable, Sendable {

        public let displayName: String?

        public let localPart: LocalPart

        public let domain: RFC_1123.Domain

        public init(
            displayName: String? = nil,
            localPart: LocalPart,
            domain: RFC_1123.Domain
        ) {
            if let displayName {
                let trimmed = String(displayName.trimming(.ascii.whitespaces))
                self.displayName = trimmed.isEmpty ? nil : trimmed
            } else {
                self.displayName = nil
            }
            self.localPart = localPart
            self.domain = domain
        }
    }
}

extension RFC_6531.Mailbox {

    public init(_ text: some StringProtocol) throws(Error) {
        try self.init(utf8: text.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(utf8 bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else { throw Error.missingAtSign }

        let displayName: String?
        let addressBytes: Bytes.SubSequence

        if let openAngle = bytes.firstIndex(of: ASCII.Code.lessThanSign.byte),
            let closeAngle = bytes[bytes.index(after: openAngle)...]
                .firstIndex(of: ASCII.Code.greaterThanSign.byte)
        {
            var name = String(
                String(decoding: bytes[bytes.startIndex..<openAngle], as: UTF8.self)
                    .trimming(.ascii.whitespaces)
            )
            if name.count >= 2, name.hasPrefix("\""), name.hasSuffix("\"") {
                name = String(name.dropFirst().dropLast())
                    .replacing("\\\"", with: "\"")
                    .replacing("\\\\", with: "\\")
            }
            displayName = name.isEmpty ? nil : name
            addressBytes = bytes[bytes.index(after: openAngle)..<closeAngle]
        } else {
            displayName = nil
            addressBytes = bytes[...]
        }

        var lastAt: Bytes.Index?
        for index in addressBytes.indices where addressBytes[index] == ASCII.Code.commercialAt.byte {
            lastAt = index
        }
        guard let atIndex = lastAt else {
            throw Error.missingAtSign
        }

        let localPart: LocalPart
        do throws(LocalPart.Error) {
            localPart = try LocalPart(
                String(decoding: addressBytes[addressBytes.startIndex..<atIndex], as: UTF8.self)
            )
        } catch {
            throw Error.invalidLocalPart(error)
        }

        let domain: RFC_1123.Domain
        do throws(RFC_1123.Domain.Error) {
            domain = try RFC_1123.Domain(ascii: addressBytes[addressBytes.index(after: atIndex)...])
        } catch {
            throw Error.invalidDomain(error)
        }

        self.init(displayName: displayName, localPart: localPart, domain: domain)
    }
}

extension RFC_6531.Mailbox {

    public var address: String {
        "\(localPart)@\(domain.name)"
    }

    public var isASCII: Bool {
        localPart.isASCII && (displayName?.utf8.allSatisfy { $0 < 0x80 } ?? true)
    }
}

extension RFC_6531.Mailbox: CustomStringConvertible {

    public var description: String {
        guard let displayName else {
            return address
        }

        let needsQuoting = displayName.utf8.contains { byte in
            guard byte < 0x80 else { return true }
            let code = ASCII.Code(byte)
            return !(code.isLetter || code.isDigit || code.isWhitespace)
        }

        let name = needsQuoting ? "\"\(Self.escapedForQuotedString(displayName))\"" : displayName
        return "\(name) <\(address)>"
    }

    private static func escapedForQuotedString(_ displayName: String) -> String {
        displayName
            .replacing("\\", with: "\\\\")
            .replacing("\"", with: "\\\"")
    }
}
