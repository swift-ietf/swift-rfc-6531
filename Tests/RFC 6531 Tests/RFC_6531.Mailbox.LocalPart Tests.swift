import RFC_6531
import Testing

@Suite
struct `RFC_6531.Mailbox.LocalPart Tests` {

    @Test(arguments: ["user", "USER", "user123", "user_name", "user-name", "user+tag", "a", "9"])
    func `an ASCII atom is a local part`(text: String) throws {
        let localPart = try RFC_6531.Mailbox.LocalPart(text)
        #expect(localPart.description == text)
        #expect(localPart.isASCII)
        #expect(localPart.isQuoted == false)
    }

    @Test
    func `every atext special is accepted`() throws {
        let localPart = try RFC_6531.Mailbox.LocalPart("a!#$%&'*+-/=?^_`{|}~b")
        #expect(localPart.description == "a!#$%&'*+-/=?^_`{|}~b")
    }

    @Test(arguments: ["user.name", "first.middle.last", "a.b.c.d.e.f"])
    func `dots separate the atoms`(text: String) throws {
        let localPart = try RFC_6531.Mailbox.LocalPart(text)
        #expect(localPart.description == text)
    }

    @Test(
        arguments: [
            "用户", "ユーザー", "사용자", "пользователь", "müller", "user🙂", "用户.名",
            "🙂", "ß", "משתמש", "مستخدم", "user用户", "田中taro", "user123用户456", "first.用户",
        ]
    )
    func `an internationalized atom is a local part`(text: String) throws {
        let localPart = try RFC_6531.Mailbox.LocalPart(text)
        #expect(localPart.description == text)
        #expect(localPart.isASCII == false)
    }

    @Test(
        arguments: [
            "\"john doe\"", "\"a\\\"b\"", "\"用 户\"", "\"user🙂\"",
            "\"user@domain\"", "\"..\"", "\".user\"", "\"user.\"", "\"user\\\\backslash\"", "\"用户@域名\"",
        ]
    )
    func `a quoted string is a local part`(text: String) throws {
        let localPart = try RFC_6531.Mailbox.LocalPart(text)
        #expect(localPart.description == text)
        #expect(localPart.isQuoted)
    }

    @Test
    func `the length limit counts UTF-8 bytes`() throws {
        #expect(try RFC_6531.Mailbox.LocalPart(String(repeating: "a", count: 64)).description.count == 64)
        #expect(try RFC_6531.Mailbox.LocalPart(String(repeating: "用", count: 21)).description.count == 21)
        #expect(try RFC_6531.Mailbox.LocalPart(String(repeating: "用", count: 21) + "a").description.utf8.count == 64)
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.tooLong(65)) {
            try RFC_6531.Mailbox.LocalPart(String(repeating: "a", count: 65))
        }
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.tooLong(66)) {
            try RFC_6531.Mailbox.LocalPart(String(repeating: "用", count: 22))
        }
    }

    @Test
    func `an empty local part is refused`() {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.empty) {
            try RFC_6531.Mailbox.LocalPart("")
        }
    }

    @Test(arguments: [".user", "user.", "."])
    func `a leading or trailing dot is refused`(text: String) {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.leadingOrTrailingDot(text)) {
            try RFC_6531.Mailbox.LocalPart(text)
        }
    }

    @Test(arguments: ["user..name", "a...b", "用户..名"])
    func `consecutive dots are refused`(text: String) {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.consecutiveDots(text)) {
            try RFC_6531.Mailbox.LocalPart(text)
        }
    }

    @Test(
        arguments: [
            "user name", "user@name", "user(name)", "user,name", "user<name>", "user\\name",
            "user[bracket", "user]bracket", "user:colon", "user;semicolon", "user\"quote",
        ]
    )
    func `an ASCII special outside atext is refused`(text: String) {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.invalidUTF8Atom(text)) {
            try RFC_6531.Mailbox.LocalPart(text)
        }
    }

    @Test(arguments: ["\"unclosed", "\"\"", "\"a\"b\"", "\"line\nbreak\""])
    func `a malformed quoted string is refused`(text: String) {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.invalidQuotedString(text)) {
            try RFC_6531.Mailbox.LocalPart(text)
        }
    }
}
