public import RFC_5321

extension RFC_5321.EmailAddress {

    public init(_ mailbox: RFC_6531.Mailbox) throws(RFC_6531.Mailbox.ConversionError) {
        guard mailbox.isASCII else {
            throw RFC_6531.Mailbox.ConversionError.nonASCIICharacters
        }
        let localPart: RFC_5321.EmailAddress.LocalPart
        do throws(RFC_5321.EmailAddress.LocalPart.Error) {
            localPart = try RFC_5321.EmailAddress.LocalPart(mailbox.localPart.description)
        } catch {
            throw RFC_6531.Mailbox.ConversionError.notRepresentableAsRFC5321(
                .invalidLocalPart(error)
            )
        }
        do throws(RFC_5321.EmailAddress.Error) {
            self = try RFC_5321.EmailAddress(
                displayName: mailbox.displayName,
                localPart: localPart,
                domain: mailbox.domain
            )
        } catch {
            throw RFC_6531.Mailbox.ConversionError.notRepresentableAsRFC5321(error)
        }
    }
}
