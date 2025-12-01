// RFC_6531.swift
// swift-rfc-6531
//
// RFC 6531: SMTP Extension for Internationalized Email

/// RFC 6531: SMTP Extension for Internationalized Email
///
/// Extends SMTP to support internationalized email addresses with UTF-8 characters
/// in the local-part and display name.
///
/// ## Key Types
///
/// - ``EmailAddress``: Internationalized email address (SMTPUTF8)
///
/// ## Example
///
/// ```swift
/// let email = try RFC_6531.EmailAddress("用户@example.com")
/// print(email.localPart)  // "用户"
/// print(email.domain)     // "example.com"
/// ```
///
/// ## See Also
///
/// - [RFC 6531](https://www.rfc-editor.org/rfc/rfc6531)
public enum RFC_6531 {}
