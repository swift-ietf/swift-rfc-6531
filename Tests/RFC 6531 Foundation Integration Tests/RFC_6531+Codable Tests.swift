import Foundation
import RFC_1123
import RFC_6531
import RFC_6531_Foundation_Integration
import Testing

@Suite
struct `RFC_6531+Codable Tests` {

    @Test
    func `a mailbox codes as its parts`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "张三",
            localPart: try .init("用户"),
            domain: try .init("example.com")
        )

        let encoded = try JSONEncoder().encode(mailbox)

        #expect(try JSONDecoder().decode(RFC_6531.Mailbox.self, from: encoded) == mailbox)
    }

    @Test
    func `a mailbox decodes from its parts`() throws {
        let encoded = Data(#"{"displayName":"John Doe","localPart":"user","domain":"example.com"}"#.utf8)

        let mailbox = try JSONDecoder().decode(RFC_6531.Mailbox.self, from: encoded)

        #expect(mailbox.displayName == "John Doe")
        #expect(mailbox.localPart.description == "user")
        #expect(mailbox.domain.name == "example.com")
    }

    @Test
    func `a mailbox without a display name omits it`() throws {
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("user"),
            domain: try .init("example.com")
        )

        let encoded = try JSONEncoder().encode(mailbox)

        #expect(try JSONDecoder().decode(RFC_6531.Mailbox.self, from: encoded) == mailbox)
        #expect(String(decoding: encoded, as: UTF8.self).contains("displayName") == false)
    }

    @Test
    func `a local part codes as its text form`() throws {
        let localPart = try RFC_6531.Mailbox.LocalPart("用户")

        let encoded = try JSONEncoder().encode(localPart)

        #expect(String(decoding: encoded, as: UTF8.self) == #""用户""#)
        #expect(try JSONDecoder().decode(RFC_6531.Mailbox.LocalPart.self, from: encoded) == localPart)
    }

    @Test
    func `a malformed local part fails to decode`() throws {
        let encoded = Data(#""user..name""#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_6531.Mailbox.LocalPart.self, from: encoded)
        }
    }

    @Test
    func `a malformed domain fails to decode`() throws {
        let encoded = Data(#"{"localPart":"user","domain":"www..com"}"#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_6531.Mailbox.self, from: encoded)
        }
    }
}
