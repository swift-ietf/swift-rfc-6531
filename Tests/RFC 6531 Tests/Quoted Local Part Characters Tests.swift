import Testing

@testable import RFC_6531

@Suite
struct `Quoted local part characters` {
    @Test(arguments: ["\"a\u{0}b\"", "\"a\tb\"", "\"a\u{7F}b\"", "\"a\u{1B}b\"", "\"\\\u{1}\""])
    func `a control character inside quotes is refused`(_ text: String) {
        #expect(throws: RFC_6531.Mailbox.LocalPart.Error.invalidQuotedString(text)) {
            try RFC_6531.Mailbox.LocalPart(text)
        }
    }

    @Test(arguments: ["\"\\a\"", "\"\\ \"", "\"a\\~b\""])
    func `a backslash may quote any printable ASCII character`(_ text: String) throws {
        #expect(try RFC_6531.Mailbox.LocalPart(text).isQuoted)
    }

    @Test
    func `a space and non-ASCII text are allowed inside quotes`() throws {
        #expect(try RFC_6531.Mailbox.LocalPart("\"john doe 用户\"").isQuoted)
    }
}
