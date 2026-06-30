//
//  EmailAddressSerializationEquivalenceTests.swift
//  swift-rfc-6531
//
//  [FAM-012] composite re-cut guard. The EmailAddress `ASCII.Serializable` verb
//  (direct same-format composition over the `ASCII.Code` substrate) MUST emit
//  byte-identical output to the `Binary.Serializable` witness (`serializeBytes`)
//  for the display-name quoting path AND for the RFC 6531 (SMTPUTF8) non-ASCII
//  path — where each UTF-8 byte is lifted losslessly via `ASCII.Code(unchecked:)`.
//  Asserts the refactor invariant directly (ASCII output == Binary output), so no
//  expected string is hand-derived.
//

import RFC_1123
import RFC_6531
import Testing

@Suite
struct `EmailAddress Serialization Equivalence` {

    @Test
    func `ASCII verb output equals Binary witness output for the quoting path`() throws {
        // A display name containing a `"` forces the quoting wrapper — exactly the
        // branch transcribed into the ASCII verb.
        let email = RFC_6531.EmailAddress(
            displayName: "Doe \"JD\" John",
            localPart: try RFC_6531.EmailAddress.LocalPart("jd"),
            domain: try RFC_1123.Domain("example.com")
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = email.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_6531.EmailAddress.serialize(email, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }

    @Test
    func `ASCII verb output equals Binary witness output for the non-ASCII UTF-8 path`() throws {
        // Non-ASCII display name AND non-ASCII local-part exercise the lossless
        // `ASCII.Code(unchecked: Byte($0))` lift on bytes >= 0x80 — the distinguishing
        // RFC 6531 (SMTPUTF8) behaviour the re-expression must preserve.
        let email = RFC_6531.EmailAddress(
            displayName: "张三",
            localPart: try RFC_6531.EmailAddress.LocalPart("用户"),
            domain: try RFC_1123.Domain("example.com")
        )

        // ASCII.Serializable verb output, projected to bytes.
        let viaASCII: [Byte] = email.serialized

        // Binary.Serializable witness output.
        var viaBinary: [Byte] = []
        RFC_6531.EmailAddress.serialize(email, into: &viaBinary)

        #expect(viaASCII == viaBinary)
    }
}
