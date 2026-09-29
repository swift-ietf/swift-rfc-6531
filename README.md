# swift-rfc-6531

Domain model for RFC 6531, the SMTPUTF8 extension: `RFC_6531.Mailbox` (display name, `Mailbox.LocalPart`, `RFC_1123.Domain`) is the internationalized mailbox, whose local-part admits UTF-8 dot-atoms and quoted strings, validates its length in UTF-8 bytes rather than characters, throwing `Mailbox.LocalPart.Error`, and reports `isASCII` and `isQuoted`. `RFC_6531.Mailbox(_:)` / `init(utf8:)` read the text form (`local@domain` or `display-name <local@domain>`), throwing `Mailbox.Error`, and `description` and `address` render it. `Mailbox.isASCII` reports whether an address is representable without SMTPUTF8, and the downgrading initializers `RFC_5321.EmailAddress(_:)` and `RFC_5322.Mailbox(_:)` convert when it is, throwing `Mailbox.ConversionError` when it is not. The `RFC 6531 Foundation Integration` product bridges `Mailbox` to `Codable` as its parts (`displayName`, `localPart`, `domain`) and `Mailbox.LocalPart` as its text form. The domain target carries no wire coders.

```swift
import RFC_1123
import RFC_5321
import RFC_6531

let mailbox = RFC_6531.Mailbox(
    displayName: "田中太郎",
    localPart: try .init("用户"),
    domain: try .init("example.com")
)
mailbox.address                                      // "用户@example.com"
mailbox.isASCII                                      // false
mailbox.localPart.isQuoted                           // false
mailbox.description                                  // "\"田中太郎\" <用户@example.com>"

let read = try RFC_6531.Mailbox("张三 <用户@example.com>")
read.displayName                                     // "张三"
read.address                                         // "用户@example.com"

let ascii = RFC_6531.Mailbox(
    displayName: "John Doe",
    localPart: try .init("user"),
    domain: try .init("example.com")
)
try RFC_5321.EmailAddress(ascii).address             // "user@example.com"
```
