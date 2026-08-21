extension RFC_6531.EmailAddress.LocalPart {
    enum Storage: Hashable, Sendable, Codable {
        case utf8DotAtom
        case quoted
    }
}
