// RFC_6531.EmailAddress.LocalPart.Storage.swift
// swift-rfc-6531
//
// Internal storage discriminator for RFC 6531 local-part

extension RFC_6531.EmailAddress.LocalPart {
    enum Storage: Hashable, Sendable, Codable {
        case utf8DotAtom
        case quoted
    }
}
