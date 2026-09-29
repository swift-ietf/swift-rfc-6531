import RFC_1123
import RFC_1123_Foundation_Integration
public import RFC_6531

extension RFC_6531.Mailbox: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case displayName
        case localPart
        case domain
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            displayName: try container.decodeIfPresent(String.self, forKey: .displayName),
            localPart: try container.decode(LocalPart.self, forKey: .localPart),
            domain: try container.decode(RFC_1123.Domain.self, forKey: .domain)
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(localPart, forKey: .localPart)
        try container.encode(domain, forKey: .domain)
    }
}
