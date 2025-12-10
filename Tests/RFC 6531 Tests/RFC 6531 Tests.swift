//
//  RFC 6531 Tests.swift
//  swift-rfc-6531
//
//  Exhaustive RFC 6531 compliance tests for internationalized email addresses
//

import Foundation
import RFC_5321
import RFC_5322
import RFC_6531
import Testing

// MARK: - LocalPart Valid Cases

@Suite("RFC 6531 LocalPart - Valid Cases")
struct LocalPartValidTests {

    // MARK: ASCII Atoms

    @Test(
        "Valid ASCII single character local parts",
        arguments: [
            "a", "A", "z", "Z", "0", "9",
        ]
    )
    func validSingleChar(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    @Test(
        "Valid ASCII atoms",
        arguments: [
            "user",
            "USER",
            "user123",
            "user_name",
            "user-name",
            "user+tag",
            "user!important",
            "user#hash",
            "user$dollar",
            "user%percent",
            "user&ampersand",
            "user'apostrophe",
            "user*star",
            "user/slash",
            "user=equals",
            "user?question",
            "user^caret",
            "user`backtick",
            "user{brace",
            "user|pipe",
            "user}brace",
            "user~tilde",
        ]
    )
    func validASCIIAtoms(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    // MARK: Dot-atoms

    @Test(
        "Valid dot-atom local parts",
        arguments: [
            "user.name",
            "first.last",
            "a.b.c",
            "user.name.extra",
            "first.middle.last",
            "a.b.c.d.e.f",
        ]
    )
    func validDotAtoms(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    // MARK: UTF-8 Local Parts (RFC 6531 extension)

    @Test(
        "Valid UTF-8 single characters",
        arguments: [
            "用",  // Chinese (3-byte UTF-8)
            "ユ",  // Japanese Katakana (3-byte)
            "한",  // Korean (3-byte)
            "ä",  // German umlaut (2-byte)
            "é",  // French accent (2-byte)
            "ñ",  // Spanish tilde (2-byte)
            "ß",  // German eszett (2-byte)
            "θ",  // Greek theta (2-byte)
            "ж",  // Cyrillic (2-byte)
            "א",  // Hebrew (2-byte)
            "م",  // Arabic (2-byte)
            "🙂",  // Emoji (4-byte UTF-8) - allowed per RFC 6531 UTF8-non-ascii
        ]
    )
    func validUTF8SingleChar(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    @Test(
        "Valid UTF-8 words",
        arguments: [
            "用户",  // Chinese: "user"
            "用户名",  // Chinese: "username"
            "ユーザー",  // Japanese: "user"
            "사용자",  // Korean: "user"
            "benutzér",  // Mixed: ASCII + accent
            "пользователь",  // Russian: "user"
            "משתמש",  // Hebrew: "user"
            "مستخدم",  // Arabic: "user"
        ]
    )
    func validUTF8Words(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    @Test(
        "Valid UTF-8 dot-atoms",
        arguments: [
            "用户.名",
            "first.用户",
            "用户.last",
            "田中.太郎",
            "имя.фамилия",
        ]
    )
    func validUTF8DotAtoms(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    @Test(
        "Valid mixed ASCII and UTF-8",
        arguments: [
            "user用户",
            "用户user",
            "user123用户456",
            "田中taro",
        ]
    )
    func validMixedASCIIUTF8(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    // MARK: Quoted Strings

    @Test(
        "Valid quoted strings",
        arguments: [
            "\"user\"",
            "\"user name\"",
            "\"user@domain\"",
            "\"user.name\"",
            "\"..\"",
            "\".user\"",
            "\"user.\"",
            "\"user\\\"quote\"",
            "\"user\\\\backslash\"",
        ]
    )
    func validQuotedStrings(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    @Test(
        "Valid quoted UTF-8 strings",
        arguments: [
            "\"用户\"",
            "\"田中 太郎\"",
            "\"用户@域名\"",
        ]
    )
    func validQuotedUTF8Strings(localPart: String) throws {
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
    }

    // MARK: Length Boundary (64 UTF-8 bytes max)

    @Test("Maximum length ASCII local part (64 bytes)")
    func maxLengthASCII() throws {
        let localPart = String(repeating: "a", count: 64)
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
        #expect(lp.rawValue.utf8.count == 64)
    }

    @Test("Maximum length UTF-8 local part (64 bytes with 3-byte chars)")
    func maxLengthUTF8() throws {
        // 用 is 3 bytes in UTF-8, so 21 chars = 63 bytes + 1 ASCII = 64
        let localPart = String(repeating: "用", count: 21) + "a"
        let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
        #expect(lp.rawValue == localPart)
        #expect(lp.rawValue.utf8.count == 64)
    }
}

// MARK: - LocalPart Invalid Cases

@Suite("RFC 6531 LocalPart - Invalid Cases")
struct LocalPartInvalidTests {

    @Test("Empty local part")
    func empty() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.empty) {
            _ = try RFC_6531.EmailAddress.LocalPart("")
        }
    }

    // MARK: Length Violations

    @Test("Local part too long (65 ASCII bytes)")
    func tooLongASCII() throws {
        let localPart = String(repeating: "a", count: 65)
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.tooLong(65)) {
            _ = try RFC_6531.EmailAddress.LocalPart(localPart)
        }
    }

    @Test("Local part too long (66 UTF-8 bytes)")
    func tooLongUTF8() throws {
        // 用 is 3 bytes, 22 chars = 66 bytes
        let localPart = String(repeating: "用", count: 22)
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.tooLong(66)) {
            _ = try RFC_6531.EmailAddress.LocalPart(localPart)
        }
    }

    // MARK: Dot Violations

    @Test("Leading dot")
    func leadingDot() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart(".user")
        }
    }

    @Test("Trailing dot")
    func trailingDot() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart("user.")
        }
    }

    @Test(
        "Consecutive dots",
        arguments: [
            "user..name",
            "a..b",
            "user...name",
            "a....b",
            "用户..名",
        ]
    )
    func consecutiveDots(localPart: String) throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart(localPart)
        }
    }

    // MARK: Invalid Characters in Unquoted Atoms

    @Test(
        "Invalid characters in unquoted atom",
        arguments: [
            "user name",  // space
            "user(paren",  // parenthesis
            "user)paren",
            "user<angle",  // angle brackets
            "user>angle",
            "user[bracket",  // brackets
            "user]bracket",
            "user:colon",  // colon
            "user;semicolon",  // semicolon
            "user,comma",  // comma
            "user\"quote",  // unescaped quote
            "user\\backslash",  // unescaped backslash
        ]
    )
    func invalidCharsInAtom(localPart: String) throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart(localPart)
        }
    }

    // MARK: Invalid Quoted Strings

    @Test("Unclosed quoted string")
    func unclosedQuote() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart("\"user")
        }
    }

    @Test("Empty quoted string")
    func emptyQuotedString() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart("\"\"")
        }
    }

    @Test("Unescaped quote in quoted string")
    func unescapedQuoteInQuotedString() throws {
        #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
            _ = try RFC_6531.EmailAddress.LocalPart("\"user\"name\"")
        }
    }
}

// MARK: - EmailAddress Valid Cases

@Suite("RFC 6531 EmailAddress - Valid Cases")
struct EmailAddressValidTests {

    // MARK: Basic Formats

    @Test(
        "Valid simple email addresses",
        arguments: [
            "user@example.com",
            "USER@EXAMPLE.COM",
            "user@sub.example.com",
            "user@a.b.c.d.example.com",
            "a@b.co",
            "user123@example.com",
            "user-name@example.com",
            "user_name@example.com",
            "user+tag@example.com",
        ]
    )
    func validSimpleAddresses(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == nil)
        #expect(addr.rawValue == email)
    }

    @Test(
        "Valid dot-atom local parts in addresses",
        arguments: [
            "user.name@example.com",
            "first.last@example.com",
            "a.b.c@example.com",
            "first.middle.last@example.com",
        ]
    )
    func validDotAtomAddresses(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == nil)
    }

    // MARK: UTF-8 Email Addresses (RFC 6531)

    @Test(
        "Valid UTF-8 local parts",
        arguments: [
            "用户@example.com",
            "用户名@example.com",
            "ユーザー@example.com",
            "사용자@example.com",
            "пользователь@example.com",
            "משתמש@example.com",
            "مستخدم@example.com",
        ]
    )
    func validUTF8LocalParts(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == nil)
        #expect(addr.isASCII == false)
    }

    @Test(
        "Valid UTF-8 dot-atom addresses",
        arguments: [
            "用户.名@example.com",
            "田中.太郎@example.com",
            "имя.фамилия@example.com",
        ]
    )
    func validUTF8DotAtomAddresses(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.isASCII == false)
    }

    // MARK: Display Name Formats

    @Test(
        "Valid display names (unquoted)",
        arguments: [
            ("John Doe <user@example.com>", "John Doe", "user@example.com"),
            ("Jane <jane@example.com>", "Jane", "jane@example.com"),
            ("A B C <abc@example.com>", "A B C", "abc@example.com"),
        ]
    )
    func validUnquotedDisplayNames(
        email: String,
        expectedName: String,
        expectedAddress: String
    ) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == expectedName)
        #expect(addr.address == expectedAddress)
    }

    @Test(
        "Valid display names (quoted)",
        arguments: [
            ("\"John Doe\" <user@example.com>", "John Doe", "user@example.com"),
            ("\"Doe, John\" <user@example.com>", "Doe, John", "user@example.com"),
        ]
    )
    func validQuotedDisplayNames(
        email: String,
        expectedName: String,
        expectedAddress: String
    ) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == expectedName)
        #expect(addr.address == expectedAddress)
    }

    @Test(
        "Valid UTF-8 display names",
        arguments: [
            ("张三 <user@example.com>", "张三", "user@example.com"),
            ("田中太郎 <user@example.com>", "田中太郎", "user@example.com"),
            ("Müller <user@example.com>", "Müller", "user@example.com"),
            ("Владимир <user@example.com>", "Владимир", "user@example.com"),
        ]
    )
    func validUTF8DisplayNames(email: String, expectedName: String, expectedAddress: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == expectedName)
        #expect(addr.address == expectedAddress)
    }

    @Test(
        "Valid angle bracket format without display name",
        arguments: [
            "<user@example.com>",
            "<用户@example.com>",
        ]
    )
    func validAngleBracketNoDisplayName(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.displayName == nil)
    }

    // MARK: Quoted Local Parts in Addresses

    @Test(
        "Valid quoted local parts in addresses",
        arguments: [
            "\"user name\"@example.com",
            "\"user@domain\"@example.com",
            "\"..\"@example.com",
        ]
    )
    func validQuotedLocalParts(email: String) throws {
        _ = try RFC_6531.EmailAddress(email)
    }

    // MARK: isASCII Property

    @Test("isASCII is true for ASCII-only addresses")
    func isASCIITrue() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr.isASCII == true)
    }

    @Test("isASCII is false for UTF-8 local part")
    func isASCIIFalseLocalPart() throws {
        let addr = try RFC_6531.EmailAddress("用户@example.com")
        #expect(addr.isASCII == false)
    }

    @Test("isASCII is false for UTF-8 display name")
    func isASCIIFalseDisplayName() throws {
        let addr = try RFC_6531.EmailAddress("张三 <user@example.com>")
        #expect(addr.isASCII == false)
    }
}

// MARK: - EmailAddress Invalid Cases

@Suite("RFC 6531 EmailAddress - Invalid Cases")
struct EmailAddressInvalidTests {

    @Test(
        "Missing @ sign",
        arguments: [
            "userexample.com",
            "user",
            "用户example.com",
        ]
    )
    func missingAtSign(email: String) throws {
        #expect(throws: RFC_6531.EmailAddress.Error.missingAtSign) {
            _ = try RFC_6531.EmailAddress(email)
        }
    }

    @Test("Empty email")
    func emptyEmail() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.missingAtSign) {
            _ = try RFC_6531.EmailAddress("")
        }
    }

    @Test("Empty local part")
    func emptyLocalPart() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            _ = try RFC_6531.EmailAddress("@example.com")
        }
    }

    @Test("Empty domain")
    func emptyDomain() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            _ = try RFC_6531.EmailAddress("user@")
        }
    }

    @Test(
        "Invalid local part errors propagate",
        arguments: [
            "user..name@example.com",
            ".user@example.com",
            "user.@example.com",
        ]
    )
    func invalidLocalPartPropagates(email: String) throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            _ = try RFC_6531.EmailAddress(email)
        }
    }

    @Test(
        "Invalid domain errors propagate",
        arguments: [
            "user@-example.com",
            "user@example-.com",
        ]
    )
    func invalidDomainPropagates(email: String) throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            _ = try RFC_6531.EmailAddress(email)
        }
    }

    @Test(
        "Malformed angle brackets",
        arguments: [
            "John Doe user@example.com>",
            "John Doe <user@example.com",
            "<>",
        ]
    )
    func malformedAngleBrackets(email: String) throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            _ = try RFC_6531.EmailAddress(email)
        }
    }
}

// MARK: - Conversion Tests

@Suite("RFC 6531 EmailAddress - Conversions")
struct EmailAddressConversionTests {

    @Test("ASCII address converts to RFC 5321")
    func convertToRFC5321ASCII() throws {
        let addr6531 = try RFC_6531.EmailAddress("user@example.com")
        let addr5321 = try RFC_5321.EmailAddress(addr6531)
        #expect(addr5321.address == "user@example.com")
    }

    @Test("ASCII address with display name converts to RFC 5321")
    func convertToRFC5321WithDisplayName() throws {
        let addr6531 = try RFC_6531.EmailAddress("John Doe <user@example.com>")
        let addr5321 = try RFC_5321.EmailAddress(addr6531)
        #expect(addr5321.address == "user@example.com")
    }

    @Test("UTF-8 address fails to convert to RFC 5321")
    func convertToRFC5321UTF8Fails() throws {
        let addr6531 = try RFC_6531.EmailAddress("用户@example.com")
        #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
            _ = try RFC_5321.EmailAddress(addr6531)
        }
    }

    @Test("UTF-8 display name fails to convert to RFC 5321")
    func convertToRFC5321UTF8DisplayNameFails() throws {
        let addr6531 = try RFC_6531.EmailAddress("张三 <user@example.com>")
        #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
            _ = try RFC_5321.EmailAddress(addr6531)
        }
    }

    @Test("ASCII address converts to RFC 5322")
    func convertToRFC5322ASCII() throws {
        let addr6531 = try RFC_6531.EmailAddress("user@example.com")
        let addr5322 = try RFC_5322.EmailAddress(addr6531)
        #expect(addr5322.address == "user@example.com")
    }

    @Test("UTF-8 address fails to convert to RFC 5322")
    func convertToRFC5322UTF8Fails() throws {
        let addr6531 = try RFC_6531.EmailAddress("用户@example.com")
        #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
            _ = try RFC_5322.EmailAddress(addr6531)
        }
    }
}

// MARK: - Round-Trip Tests

@Suite("RFC 6531 EmailAddress - Round-Trip")
struct EmailAddressRoundTripTests {

    @Test(
        "Round-trip ASCII addresses",
        arguments: [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "\"quoted\"@example.com",
        ]
    )
    func roundTripASCII(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        let serialized = addr.rawValue
        let reparsed = try RFC_6531.EmailAddress(serialized)
        #expect(addr == reparsed)
    }

    @Test(
        "Round-trip UTF-8 addresses",
        arguments: [
            "用户@example.com",
            "用户.名@example.com",
            "ユーザー@example.com",
        ]
    )
    func roundTripUTF8(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        let serialized = addr.rawValue
        let reparsed = try RFC_6531.EmailAddress(serialized)
        #expect(addr == reparsed)
    }

    @Test(
        "Round-trip with display names",
        arguments: [
            "John Doe <user@example.com>",
            "张三 <user@example.com>",
        ]
    )
    func roundTripWithDisplayName(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        let serialized = addr.rawValue
        let reparsed = try RFC_6531.EmailAddress(serialized)
        #expect(addr.displayName == reparsed.displayName)
        #expect(addr.localPart == reparsed.localPart)
        #expect(addr.domain == reparsed.domain)
    }
}

// MARK: - Codable Tests

@Suite("RFC 6531 EmailAddress - Codable")
struct EmailAddressCodableTests {

    @Test("Encode and decode ASCII address")
    func codableASCII() throws {
        let original = try RFC_6531.EmailAddress("user@example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Encode and decode UTF-8 address")
    func codableUTF8() throws {
        let original = try RFC_6531.EmailAddress("用户@example.com")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
        #expect(original == decoded)
    }

    @Test("Encode and decode with display name")
    func codableWithDisplayName() throws {
        let original = try RFC_6531.EmailAddress("张三 <user@example.com>")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
        #expect(original == decoded)
    }
}

// MARK: - Hashable & Equatable Tests

@Suite("RFC 6531 EmailAddress - Hashable & Equatable")
struct EmailAddressHashableTests {

    @Test("Equal addresses have equal hashes")
    func equalHashCodes() throws {
        let addr1 = try RFC_6531.EmailAddress("user@example.com")
        let addr2 = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr1 == addr2)
        #expect(addr1.hashValue == addr2.hashValue)
    }

    @Test("Different addresses are not equal")
    func notEqual() throws {
        let addr1 = try RFC_6531.EmailAddress("user1@example.com")
        let addr2 = try RFC_6531.EmailAddress("user2@example.com")
        #expect(addr1 != addr2)
    }

    @Test("Same address with different display names are not equal")
    func displayNameAffectsEquality() throws {
        let addr1 = try RFC_6531.EmailAddress("John <user@example.com>")
        let addr2 = try RFC_6531.EmailAddress("Jane <user@example.com>")
        #expect(addr1 != addr2)
    }

    @Test("Can be used in Set")
    func usableInSet() throws {
        let addr1 = try RFC_6531.EmailAddress("user1@example.com")
        let addr2 = try RFC_6531.EmailAddress("user2@example.com")
        let addr3 = try RFC_6531.EmailAddress("user1@example.com")

        let set: Set<RFC_6531.EmailAddress> = [addr1, addr2, addr3]
        #expect(set.count == 2)
    }
}

// MARK: - Component Access Tests

@Suite("RFC 6531 EmailAddress - Component Access")
struct EmailAddressComponentTests {

    @Test("Access local part")
    func accessLocalPart() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr.localPart.rawValue == "user")
    }

    @Test("Access domain")
    func accessDomain() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr.domain.name == "example.com")
    }

    @Test("Access display name when present")
    func accessDisplayNamePresent() throws {
        let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
        #expect(addr.displayName == "John Doe")
    }

    @Test("Display name is nil when absent")
    func displayNameNilWhenAbsent() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr.displayName == nil)
    }

    @Test("Address property excludes display name")
    func addressExcludesDisplayName() throws {
        let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
        #expect(addr.address == "user@example.com")
    }
}

// MARK: - Serialization Tests

@Suite("RFC 6531 EmailAddress - Serialization")
struct EmailAddressSerializationTests {

    @Test("Serialize simple address")
    func serializeSimple() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(String(addr) == "user@example.com")
    }

    @Test("Serialize with unquoted display name")
    func serializeUnquotedDisplayName() throws {
        let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
        #expect(String(addr) == "John Doe <user@example.com>")
    }

    @Test("Serialize with special characters quotes display name")
    func serializeQuotedDisplayName() throws {
        let addr = try RFC_6531.EmailAddress(
            displayName: "Doe, John",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        #expect(String(addr) == "\"Doe, John\" <user@example.com>")
    }

    @Test("Serialize UTF-8 address")
    func serializeUTF8() throws {
        let addr = try RFC_6531.EmailAddress("用户@example.com")
        #expect(String(addr) == "用户@example.com")
    }

    @Test("Serialize UTF-8 display name quotes when has special chars")
    func serializeUTF8DisplayNameQuoted() throws {
        let addr = try RFC_6531.EmailAddress(
            displayName: "张,三",
            localPart: try .init("user"),
            domain: try .init("example.com")
        )
        let serialized = String(addr)
        #expect(serialized.contains("\""))
    }
}

// MARK: - Edge Cases and Boundary Tests

@Suite("RFC 6531 - Edge Cases")
struct EdgeCaseTests {

    @Test("Single character domain labels")
    func singleCharDomainLabels() throws {
        let addr = try RFC_6531.EmailAddress("user@a.b.c")
        #expect(addr.domain.name == "a.b.c")
    }

    @Test("Numbers in domain")
    func numbersInDomain() throws {
        let addr = try RFC_6531.EmailAddress("user@123.example.com")
        #expect(addr.domain.name == "123.example.com")
    }

    @Test("All allowed special characters in local part")
    func allSpecialCharsInLocalPart() throws {
        // Per RFC 5321/6531, these are allowed in atoms: !#$%&'*+\-/=?^_`{|}~
        let addr = try RFC_6531.EmailAddress("a!#$%&'*+-/=?^_`{|}~b@example.com")
        #expect(addr.localPart.rawValue == "a!#$%&'*+-/=?^_`{|}~b")
    }

    @Test("Whitespace trimmed from display name")
    func whitespaceTrimmedFromDisplayName() throws {
        let addr = try RFC_6531.EmailAddress("  John Doe  <user@example.com>")
        #expect(addr.displayName == "John Doe")
    }

    @Test("Empty display name becomes nil")
    func emptyDisplayNameBecomesNil() throws {
        let addr = try RFC_6531.EmailAddress("   <user@example.com>")
        #expect(addr.displayName == nil)
    }

    @Test("4-byte UTF-8 emoji in local part (allowed per RFC 6531)")
    func emojiInLocalPart() throws {
        let addr = try RFC_6531.EmailAddress("user🙂@example.com")
        #expect(addr.localPart.rawValue == "user🙂")
    }

    @Test("Emoji in quoted local part")
    func emojiInQuotedLocalPart() throws {
        let addr = try RFC_6531.EmailAddress("\"user🙂\"@example.com")
        #expect(addr.localPart.rawValue == "\"user🙂\"")
    }

    @Test("RawRepresentable conformance")
    func rawRepresentable() throws {
        let addr = RFC_6531.EmailAddress(rawValue: "user@example.com")
        #expect(addr != nil)
        #expect(addr?.rawValue == "user@example.com")
    }

    @Test("RawRepresentable returns nil for invalid")
    func rawRepresentableInvalid() throws {
        let addr = RFC_6531.EmailAddress(rawValue: "invalid")
        #expect(addr == nil)
    }

    @Test("CustomStringConvertible")
    func customStringConvertible() throws {
        let addr = try RFC_6531.EmailAddress("user@example.com")
        #expect(addr.description == "user@example.com")
    }
}

// MARK: - UTF-8 Multi-byte Sequence Tests

@Suite("RFC 6531 - UTF-8 Byte Sequences")
struct UTF8ByteSequenceTests {

    @Test(
        "2-byte UTF-8 sequences (Latin Extended, etc.)",
        arguments: [
            "café@example.com",  // é = C3 A9
            "naïve@example.com",  // ï = C3 AF
            "Ångström@example.com",  // Å = C3 85
        ]
    )
    func twoByte(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.isASCII == false)
    }

    @Test(
        "3-byte UTF-8 sequences (CJK, etc.)",
        arguments: [
            "日本語@example.com",  // Japanese
            "한국어@example.com",  // Korean
            "中文@example.com",  // Chinese
            "עברית@example.com",  // Hebrew
            "العربية@example.com",  // Arabic
        ]
    )
    func threeByte(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.isASCII == false)
    }

    @Test(
        "4-byte UTF-8 sequences (Emoji) - allowed per RFC 6531",
        arguments: [
            "🎉party@example.com",
            "test🔥@example.com",
            "emoji👍@example.com",
        ]
    )
    func fourByte(email: String) throws {
        let addr = try RFC_6531.EmailAddress(email)
        #expect(addr.isASCII == false)
    }
}

// MARK: - Constructor Tests

@Suite("RFC 6531 EmailAddress - Constructors")
struct EmailAddressConstructorTests {

    @Test("Constructor from components without display name")
    func constructorWithoutDisplayName() throws {
        let localPart = try RFC_6531.EmailAddress.LocalPart("user")
        let domain = try RFC_1123.Domain("example.com")
        let addr = RFC_6531.EmailAddress(localPart: localPart, domain: domain)

        #expect(addr.displayName == nil)
        #expect(addr.localPart == localPart)
        #expect(addr.domain == domain)
        #expect(addr.address == "user@example.com")
    }

    @Test("Constructor from components with display name")
    func constructorWithDisplayName() throws {
        let localPart = try RFC_6531.EmailAddress.LocalPart("user")
        let domain = try RFC_1123.Domain("example.com")
        let addr = RFC_6531.EmailAddress(
            displayName: "John Doe",
            localPart: localPart,
            domain: domain
        )

        #expect(addr.displayName == "John Doe")
        #expect(addr.localPart == localPart)
        #expect(addr.domain == domain)
    }

    @Test("Constructor trims whitespace from display name")
    func constructorTrimsDisplayName() throws {
        let localPart = try RFC_6531.EmailAddress.LocalPart("user")
        let domain = try RFC_1123.Domain("example.com")
        let addr = RFC_6531.EmailAddress(
            displayName: "  John Doe  ",
            localPart: localPart,
            domain: domain
        )

        #expect(addr.displayName == "John Doe")
    }

    @Test("Constructor with empty display name becomes nil")
    func constructorEmptyDisplayNameBecomesNil() throws {
        let localPart = try RFC_6531.EmailAddress.LocalPart("user")
        let domain = try RFC_1123.Domain("example.com")
        let addr = RFC_6531.EmailAddress(
            displayName: "   ",
            localPart: localPart,
            domain: domain
        )

        #expect(addr.displayName == nil)
    }
}
