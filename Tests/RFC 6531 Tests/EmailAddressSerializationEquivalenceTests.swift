import RFC_1123
import RFC_6531
import Testing

@Suite
struct `EmailAddress Serialization Equivalence` {

    @Suite
    struct Unit {}

    @Suite
    struct `Edge Case` {}

    @Suite
    struct Integration {

        @Test
        func `ASCII verb output equals Binary witness output for the quoting path`() throws {

            let email = RFC_6531.EmailAddress(
                displayName: "Doe \"JD\" John",
                localPart: try RFC_6531.EmailAddress.LocalPart("jd"),
                domain: try RFC_1123.Domain("example.com")
            )

            let viaASCII: [Byte] = email.serialized

            var viaBinary: [Byte] = []
            RFC_6531.EmailAddress.serialize(email, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }

        @Test
        func `ASCII verb output equals Binary witness output for the non-ASCII UTF-8 path`() throws
        {

            let email = RFC_6531.EmailAddress(
                displayName: "张三",
                localPart: try RFC_6531.EmailAddress.LocalPart("用户"),
                domain: try RFC_1123.Domain("example.com")
            )

            let viaASCII: [Byte] = email.serialized

            var viaBinary: [Byte] = []
            RFC_6531.EmailAddress.serialize(email, into: &viaBinary)

            #expect(viaASCII == viaBinary)
        }
    }
}
