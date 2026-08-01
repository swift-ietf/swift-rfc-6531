// RFC_6531.EmailAddress.LocalPart.Limits.swift
// swift-rfc-6531
//
// Length limits for RFC 6531 local-part

extension RFC_6531.EmailAddress.LocalPart {
    package enum Limits {}
}

extension RFC_6531.EmailAddress.LocalPart.Limits {
    /// Maximum length in UTF-8 bytes per RFC 6531
    static let maxUTF8Length = 64
}
