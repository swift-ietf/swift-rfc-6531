public import RFC_1123
public import RFC_5890

extension RFC_6531.Mailbox {

    public enum Error: Swift::Error, Sendable, Equatable {
        case missingAtSign
        case invalidLocalPart(_ underlying: LocalPart.Error)
        case invalidDomain(_ underlying: RFC_1123.Domain.Error)
        case invalidInternationalizedDomain(_ underlying: IDNA.Error)
    }
}

extension RFC_6531.Mailbox.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .missingAtSign:
            return "Email address must contain @"

        case .invalidLocalPart(let error):
            return "Invalid local-part: \(error)"

        case .invalidDomain(let error):
            return "Invalid domain: \(error)"

        case .invalidInternationalizedDomain(let error):
            return "Invalid internationalized domain: \(error)"
        }
    }
}
