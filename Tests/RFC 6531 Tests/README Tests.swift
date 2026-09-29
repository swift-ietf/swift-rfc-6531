import RFC_1123
import RFC_5321
import RFC_6531
import Testing

@Suite
struct `README Tests` {

    @Test
    func `an internationalized mailbox builds from its parts`() throws {
        let mailbox = RFC_6531.Mailbox(
            displayName: "田中太郎",
            localPart: try .init("用户"),
            domain: try .init("example.com")
        )
        #expect(mailbox.address == "用户@example.com")
        #expect(mailbox.isASCII == false)
        #expect(mailbox.localPart.isQuoted == false)
        #expect(mailbox.description == "\"田中太郎\" <用户@example.com>")
    }

    @Test
    func `a mailbox reads from its text form`() throws {
        let read = try RFC_6531.Mailbox("张三 <用户@example.com>")
        #expect(read.displayName == "张三")
        #expect(read.address == "用户@example.com")
    }

    @Test
    func `an ASCII mailbox downgrades to RFC 5321`() throws {
        let ascii = RFC_6531.Mailbox(
            displayName: "John Doe",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(try RFC_5321.EmailAddress(ascii).address == "user@example.com")
    }
}
