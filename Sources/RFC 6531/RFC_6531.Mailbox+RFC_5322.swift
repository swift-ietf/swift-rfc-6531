public import RFC_5322

extension RFC_5322.Mailbox {

    public init(_ mailbox: RFC_6531.Mailbox) throws(RFC_6531.Mailbox.ConversionError) {
        guard mailbox.isASCII else {
            throw RFC_6531.Mailbox.ConversionError.nonASCIICharacters
        }
        let localPart: RFC_5322.Mailbox.LocalPart
        do throws(RFC_5322.Mailbox.LocalPart.Error) {
            localPart = try RFC_5322.Mailbox.LocalPart(mailbox.localPart.description)
        } catch {
            throw RFC_6531.Mailbox.ConversionError.notRepresentableAsRFC5322(
                .localPart(error)
            )
        }
        do throws(RFC_5322.Mailbox.Error) {
            self = try RFC_5322.Mailbox(
                displayName: mailbox.displayName,
                localPart: localPart,
                domain: mailbox.domain
            )
        } catch {
            throw RFC_6531.Mailbox.ConversionError.notRepresentableAsRFC5322(error)
        }
    }
}
