public import RFC_5321
public import RFC_5322

extension RFC_6531.EmailAddress {

    public enum ConversionError: Swift.Error, Sendable, Equatable {
        case nonASCIICharacters

        case notRepresentableAsRFC5321(_ underlying: RFC_5321.EmailAddress.Error)

        case notRepresentableAsRFC5322(_ underlying: RFC_5322.EmailAddress.Error)
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
