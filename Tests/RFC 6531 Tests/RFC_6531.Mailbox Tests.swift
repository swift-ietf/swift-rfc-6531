import RFC_1123
import RFC_5321
import RFC_5322
import RFC_6531
import Testing

@Suite
struct `RFC_6531.Mailbox Tests` {

    @Test
    func `a mailbox builds from its local part and domain`() throws {
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.displayName == nil)
        #expect(mailbox.localPart.description == "user")
        #expect(mailbox.domain.name == "example.com")
        #expect(mailbox.address == "user@example.com")
    }

    @Test
    func `a mailbox builds with an internationalized local part`() throws {
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("用户"),
            domain: try .init("example.com")
        )
        #expect(mailbox.address == "用户@example.com")
        #expect(mailbox.isASCII == false)
    }

    @Test
    func `a mailbox builds with an internationalized display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "田中太郎",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.displayName == "田中太郎")
        #expect(mailbox.address == "user@example.com")
        #expect(mailbox.isASCII == false)
    }

    @Test
    func `a mailbox trims the whitespace around a display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "  John Doe  ",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.displayName == "John Doe")
    }

    @Test
    func `a blank display name becomes nil`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "   ",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.displayName == nil)
    }

    @Test
    func `an ASCII-only mailbox is ASCII`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "John Doe",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.isASCII)
    }

    @Test
    func `the text form is the bare address without a display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.description == "user@example.com")
    }

    @Test
    func `the text form wraps the address in angle brackets after a display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "John Doe",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.description == "John Doe <user@example.com>")
    }

    @Test
    func `the text form quotes a display name with specials`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "Doe, John",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.description == "\"Doe, John\" <user@example.com>")
    }

    @Test
    func `the text form quotes an internationalized display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "张三",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.description == "\"张三\" <user@example.com>")
    }

    @Test
    func `the text form escapes quotes inside a quoted display name`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "Doe \"JD\" John",
            localPart: try .init("jd"),
            domain: try .init("example.com")
        )
        #expect(mailbox.description == "\"Doe \\\"JD\\\" John\" <jd@example.com>")
    }

    @Test
    func `a mailbox reads a bare address`() throws {
        let mailbox = try RFC_6531.Mailbox("user@example.com")
        #expect(mailbox.displayName == nil)
        #expect(mailbox.localPart.description == "user")
        #expect(mailbox.domain.name == "example.com")
    }

    @Test
    func `a mailbox reads an internationalized address`() throws {
        let mailbox = try RFC_6531.Mailbox("用户@example.com")
        #expect(mailbox.localPart.description == "用户")
        #expect(mailbox.domain.name == "example.com")
        #expect(mailbox.isASCII == false)
    }

    @Test
    func `a mailbox reads a display name with an angle-addr`() throws {
        let mailbox = try RFC_6531.Mailbox("张三 <user@example.com>")
        #expect(mailbox.displayName == "张三")
        #expect(mailbox.address == "user@example.com")
    }

    @Test
    func `a mailbox reads a quoted display name`() throws {
        let mailbox = try RFC_6531.Mailbox("\"Doe \\\"JD\\\" John\" <jd@example.com>")
        #expect(mailbox.displayName == "Doe \"JD\" John")
        #expect(mailbox.address == "jd@example.com")
    }

    @Test
    func `a mailbox reads a quoted local part containing an at sign`() throws {
        let mailbox = try RFC_6531.Mailbox("\"a@b\"@example.com")
        #expect(mailbox.localPart.description == "\"a@b\"")
        #expect(mailbox.localPart.isQuoted)
        #expect(mailbox.domain.name == "example.com")
    }

    @Test(arguments: ["no-at-sign", "", "userexample.com", "用户example.com", "<>"])
    func `a mailbox without an at sign is refused`(text: String) throws {
        #expect(throws: RFC_6531.Mailbox.Error.missingAtSign) {
            try RFC_6531.Mailbox(text)
        }
    }

    @Test(
        arguments: [
            ("user..name@example.com", RFC_6531.Mailbox.LocalPart.Error.consecutiveDots("user..name")),
            (".user@example.com", RFC_6531.Mailbox.LocalPart.Error.leadingOrTrailingDot(".user")),
            ("user.@example.com", RFC_6531.Mailbox.LocalPart.Error.leadingOrTrailingDot("user.")),
            ("John Doe user@example.com>", RFC_6531.Mailbox.LocalPart.Error.invalidUTF8Atom("John Doe user")),
            ("John Doe <user@example.com", RFC_6531.Mailbox.LocalPart.Error.invalidUTF8Atom("John Doe <user")),
        ]
    )
    func `a local part error surfaces from the mailbox`(
        text: String,
        error: RFC_6531.Mailbox.LocalPart.Error
    ) throws {
        #expect(throws: RFC_6531.Mailbox.Error.invalidLocalPart(error)) {
            try RFC_6531.Mailbox(text)
        }
    }

    @Test(arguments: ["-example.com", "example-.com"])
    func `a domain error surfaces from the mailbox`(domain: String) throws {
        let error = try #require(throws: RFC_1123.Domain.Error.self) {
            try RFC_1123.Domain(domain)
        }
        #expect(throws: RFC_6531.Mailbox.Error.invalidDomain(error)) {
            try RFC_6531.Mailbox("user@\(domain)")
        }
    }

    @Test
    func `a mailbox with an empty local part is refused`() throws {
        #expect(throws: RFC_6531.Mailbox.Error.invalidLocalPart(.empty)) {
            try RFC_6531.Mailbox("@example.com")
        }
    }

    @Test
    func `a mailbox with an invalid domain is refused`() throws {
        #expect(throws: RFC_6531.Mailbox.Error.self) {
            try RFC_6531.Mailbox("user@")
        }
    }

    @Test(
        arguments: [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "\"quoted\"@example.com",
            "用户@example.com",
            "用户.名@example.com",
            "ユーザー@example.com",
            "John Doe <user@example.com>",
            "张三 <user@example.com>",
            "\"Doe, John\" <user@example.com>",
        ]
    )
    func `a mailbox round-trips through its text form`(text: String) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        let reread = try RFC_6531.Mailbox(mailbox.description)
        #expect(reread.displayName == mailbox.displayName)
        #expect(reread.localPart.description == mailbox.localPart.description)
        #expect(reread.domain.name == mailbox.domain.name)
    }

    @Test
    func `an ASCII mailbox converts to RFC 5321`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "John Doe",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        let converted = try RFC_5321.EmailAddress(mailbox)
        #expect(converted.address == "user@example.com")
        #expect(converted.displayName == "John Doe")
    }

    @Test
    func `an ASCII mailbox converts to RFC 5322`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "John Doe",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        let converted = try RFC_5322.Mailbox(mailbox)
        #expect(converted.address == "user@example.com")
        #expect(converted.displayName == "John Doe")
    }

    @Test
    func `an internationalized local part refuses both conversions`() throws {
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("用户"),
            domain: try .init("example.com")
        )
        #expect(throws: RFC_6531.Mailbox.ConversionError.nonASCIICharacters) {
            try RFC_5321.EmailAddress(mailbox)
        }
        #expect(throws: RFC_6531.Mailbox.ConversionError.nonASCIICharacters) {
            try RFC_5322.Mailbox(mailbox)
        }
    }

    @Test
    func `an internationalized display name refuses conversion to RFC 5321`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "张三",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(throws: RFC_6531.Mailbox.ConversionError.nonASCIICharacters) {
            try RFC_5321.EmailAddress(mailbox)
        }
    }

    @Test
    func `an address beyond the RFC 5321 total length refuses conversion without trapping`() throws {
        let label = String(repeating: "a", count: 61)
        let mailbox = RFC_6531.Mailbox(
            localPart: try .init("user"),
            domain: try .init("\(label).\(label).\(label).\(label).com")
        )
        #expect(mailbox.isASCII)
        #expect(throws: RFC_6531.Mailbox.ConversionError.self) {
            try RFC_5321.EmailAddress(mailbox)
        }
    }

    @Test(arguments: ["Bad\rName", "Bad\nName"])
    func `a display name with a bare line break refuses conversion to RFC 5322 without trapping`(
        displayName: String
    ) throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: displayName,
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(mailbox.isASCII)
        #expect(throws: RFC_6531.Mailbox.ConversionError.self) {
            try RFC_5322.Mailbox(mailbox)
        }
    }

    @Test(
        arguments: [
            "user@example.com",
            "USER@EXAMPLE.COM",
            "user@sub.example.com",
            "user@a.b.c.d.example.com",
            "a@b.co",
            "user@a.b.c",
            "user@123.example.com",
        ]
    )
    func `a mailbox keeps the address it reads`(text: String) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        #expect(mailbox.displayName == nil)
        #expect(mailbox.address == text)
        #expect(mailbox.description == text)
    }

    @Test(
        arguments: [
            ("John Doe <user@example.com>", "John Doe", "user@example.com"),
            ("A B C <abc@example.com>", "A B C", "abc@example.com"),
            ("\"John Doe\" <user@example.com>", "John Doe", "user@example.com"),
            ("\"Doe, John\" <user@example.com>", "Doe, John", "user@example.com"),
            ("田中太郎 <user@example.com>", "田中太郎", "user@example.com"),
            ("Müller <user@example.com>", "Müller", "user@example.com"),
            ("Владимир <user@example.com>", "Владимир", "user@example.com"),
            ("  John Doe  <user@example.com>", "John Doe", "user@example.com"),
            ("张三 <用户@example.com>", "张三", "用户@example.com"),
        ]
    )
    func `a mailbox reads the display name before its angle-addr`(
        text: String,
        displayName: String,
        address: String
    ) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        #expect(mailbox.displayName == displayName)
        #expect(mailbox.address == address)
    }

    @Test(arguments: ["<user@example.com>", "<用户@example.com>", "   <user@example.com>"])
    func `an angle-addr without a display name has no display name`(text: String) throws {
        #expect(try RFC_6531.Mailbox(text).displayName == nil)
    }

    @Test
    func `a read internationalized display name is not ASCII`() throws {
        #expect(try RFC_6531.Mailbox("张三 <user@example.com>").isASCII == false)
        #expect(try RFC_6531.Mailbox("user@example.com").isASCII)
    }

    @Test(
        arguments: [
            "café@example.com",
            "naïve@example.com",
            "Ångström@example.com",
            "日本語@example.com",
            "한국어@example.com",
            "עברית@example.com",
            "العربية@example.com",
            "имя.фамилия@example.com",
            "🎉party@example.com",
            "test🔥@example.com",
            "user🙂@example.com",
            "\"user🙂\"@example.com",
        ]
    )
    func `a mailbox reads UTF-8 sequences of every width`(text: String) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        #expect(mailbox.address == text)
        #expect(mailbox.isASCII == false)
    }

    @Test(arguments: ["\"user name\"@example.com", "\"..\"@example.com", "\".user\"@example.com"])
    func `a mailbox reads a quoted local part an atom would refuse`(text: String) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        #expect(mailbox.localPart.isQuoted)
        #expect(mailbox.address == text)
    }

    @Test
    func `equal mailboxes hash equally and collapse in a set`() throws {
        let first = try RFC_6531.Mailbox("user1@example.com")
        let second = try RFC_6531.Mailbox("user2@example.com")
        let again = try RFC_6531.Mailbox("user1@example.com")
        #expect(first == again)
        #expect(first.hashValue == again.hashValue)
        #expect(first != second)
        #expect(Set([first, second, again]).count == 2)
    }

    @Test
    func `mailboxes with different display names are not equal`() throws {
        #expect(try RFC_6531.Mailbox("John <user@example.com>") != RFC_6531.Mailbox("Jane <user@example.com>"))
    }

    @Test(arguments: ["user@example.com", "用户.名@example.com", "\"quoted\"@example.com", "张三 <用户@example.com>"])
    func `a mailbox equals itself read back from its text form`(text: String) throws {
        let mailbox = try RFC_6531.Mailbox(text)
        #expect(try RFC_6531.Mailbox(mailbox.description) == mailbox)
    }
}
