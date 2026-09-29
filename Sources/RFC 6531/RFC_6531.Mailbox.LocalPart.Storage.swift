extension RFC_6531.Mailbox.LocalPart {

    package enum Storage: Hashable, Sendable {
        case utf8DotAtom(String)
        case quoted(String)
    }
}
