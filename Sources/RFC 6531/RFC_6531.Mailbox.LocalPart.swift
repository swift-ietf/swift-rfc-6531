import ASCII
import RFC_5322

extension RFC_6531.Mailbox {

    public struct LocalPart: Hashable, Sendable {
        package let storage: Storage
    }
}

extension RFC_6531.Mailbox.LocalPart {

    public init(_ text: some StringProtocol) throws(Error) {
        let text = String(text)
        let scalars = text.unicodeScalars

        guard let first = scalars.first, let last = scalars.last else { throw Error.empty }

        let byteCount = text.utf8.count
        guard byteCount <= Limits.maxUTF8Length else { throw Error.tooLong(byteCount) }

        if first == "\"" {
            guard scalars.count >= 2, last == "\"" else {
                throw Error.invalidQuotedString(text)
            }

            guard Self.isValidQuotedContent(scalars.dropFirst().dropLast()) else {
                throw Error.invalidQuotedString(text)
            }

            self.storage = .quoted(text)
        } else {

            if first == "." || last == "." {
                throw Error.leadingOrTrailingDot(text)
            }

            var previousWasDot = false
            for scalar in scalars {
                if scalar == "." {
                    if previousWasDot {
                        throw Error.consecutiveDots(text)
                    }
                    previousWasDot = true
                } else {
                    previousWasDot = false
                }
            }

            for atom in scalars.split(separator: ".", omittingEmptySubsequences: false) {
                guard Self.isValidUTF8Atom(atom) else {
                    throw Error.invalidUTF8Atom(String(atom))
                }
            }

            self.storage = .utf8DotAtom(text)
        }
    }
}

extension RFC_6531.Mailbox.LocalPart {

    public var isASCII: Bool {
        description.unicodeScalars.allSatisfy(\.isASCII)
    }

    public var isQuoted: Bool {
        switch storage {
        case .quoted: true
        case .utf8DotAtom: false
        }
    }
}

extension RFC_6531.Mailbox.LocalPart {

    private static func isValidUTF8Atom(_ scalars: some Swift.Collection<Unicode.Scalar>) -> Bool {
        guard !scalars.isEmpty else { return false }

        for scalar in scalars where scalar.isASCII {
            guard RFC_5322.isAtext(ASCII.Code(UInt8(truncatingIfNeeded: scalar.value))) else {
                return false
            }
        }
        return true
    }

    private static func isValidQuotedContent(_ scalars: some Swift.Collection<Unicode.Scalar>) -> Bool {
        guard !scalars.isEmpty else { return false }

        var iterator = scalars.makeIterator()
        while let scalar = iterator.next() {
            if scalar == "\\" {
                guard let next = iterator.next(), (32...126).contains(next.value) else {
                    return false
                }
            } else if scalar.isASCII,
                !(32...33).contains(scalar.value), !(35...91).contains(scalar.value),
                !(93...126).contains(scalar.value)
            {
                return false
            }
        }
        return true
    }
}

extension RFC_6531.Mailbox.LocalPart: CustomStringConvertible {

    public var description: String {
        switch storage {
        case .utf8DotAtom(let text), .quoted(let text):
            text
        }
    }
}
