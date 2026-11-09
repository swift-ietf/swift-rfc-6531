# swift-rfc-6531

Use this package when you need an email address whose local part may contain non-ASCII text, as SMTPUTF8 allows, such as `用户@example.com`. Start from `RFC_6531.Mailbox`. The domain is an `RFC_1123.Domain`: an internationalized domain given in text as U-labels, such as `用户@例子.广告`, is converted to its A-labels (RFC 5890), so `domain` and `address` hold the `xn--` form. If you need one address type across the email standards, use `EmailAddress` from swift-emailaddress-standard. For ASCII-only addresses under one standard, use `RFC_5321.EmailAddress` from swift-rfc-5321 or `RFC_5322.Mailbox` from swift-rfc-5322. For `Codable`, add the `RFC 6531 Foundation Integration` product.

## Laws

- A local part may be at most 64 UTF-8 bytes. The limit counts bytes, not characters, so 21 CJK characters fit and 22 do not.
- An unquoted local part is a series of atoms separated by single dots, with no dot at either end. Any non-ASCII character is allowed in an atom. An ASCII character must be one RFC 5322 allows in an atom.
- A quoted local part keeps its quotes and escapes as written. Inside the quotes it may hold spaces, `@`, dots in any position and non-ASCII text. Control characters, including tab, are refused, and a backslash may escape any printable ASCII character.
- Text is read as `local@domain` or `display-name <local@domain>`. The address is split at its last `@`, so a quoted local part may contain `@`. A display name in double quotes has its quotes removed and `\"` and `\\` unescaped.
- The display name is trimmed of surrounding whitespace, and a blank one becomes nil.
- `RFC_6531.Mailbox.description` writes a display name bare only when it holds nothing but ASCII letters, digits and whitespace. Any other name, including every non-ASCII name, is quoted with `"` and `\` escaped. Reading the result back gives an equal mailbox.
- Two mailboxes are equal only if their display names are equal too.
- `RFC_6531.Mailbox.isASCII` also checks the display name. A mailbox with a non-ASCII display name therefore can't become an `RFC_5321.EmailAddress` or an `RFC_5322.Mailbox`, even when its address is ASCII, and fails with `RFC_6531.Mailbox.ConversionError.nonASCIICharacters`. An ASCII mailbox that breaks the target standard's own rules, such as its total length limit or a line break in the display name, fails with that standard's error instead.
- With `RFC 6531 Foundation Integration`, a mailbox encodes as an object with `displayName`, `localPart` and `domain`, leaving out `displayName` when it is nil. A local part encodes as its text. A local part or domain that isn't valid fails to decode with a `DecodingError`.
