import RFC_5321
import RFC_5322

extension RFC_6531.EmailAddress {

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
