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

extension RFC_6531.EmailAddress.LocalPart {

    @Suite("RFC 6531 LocalPart - Valid Cases")
    struct Test {

        // MARK: ASCII Atoms

        @Test(
            arguments: [
                "a", "A", "z", "Z", "0", "9",
            ]
        )
        func `Valid ASCII single character local parts`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        @Test(
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
        func `Valid ASCII atoms`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        // MARK: Dot-atoms

        @Test(
            arguments: [
                "user.name",
                "first.last",
                "a.b.c",
                "user.name.extra",
                "first.middle.last",
                "a.b.c.d.e.f",
            ]
        )
        func `Valid dot-atom local parts`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        // MARK: UTF-8 Local Parts (RFC 6531 extension)

        @Test(
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
        func `Valid UTF-8 single characters`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        @Test(
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
        func `Valid UTF-8 words`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        @Test(
            arguments: [
                "用户.名",
                "first.用户",
                "用户.last",
                "田中.太郎",
                "имя.фамилия",
            ]
        )
        func `Valid UTF-8 dot-atoms`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        @Test(
            arguments: [
                "user用户",
                "用户user",
                "user123用户456",
                "田中taro",
            ]
        )
        func `Valid mixed ASCII and UTF-8`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        // MARK: Quoted Strings

        @Test(
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
        func `Valid quoted strings`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        @Test(
            arguments: [
                "\"用户\"",
                "\"田中 太郎\"",
                "\"用户@域名\"",
            ]
        )
        func `Valid quoted UTF-8 strings`(localPart: String) throws {
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
        }

        // MARK: Length Boundary (64 UTF-8 bytes max)

        @Test
        func `Maximum length ASCII local part (64 bytes)`() throws {
            let localPart = String(repeating: "a", count: 64)
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
            #expect(lp.rawValue.utf8.count == 64)
        }

        @Test
        func `Maximum length UTF-8 local part (64 bytes with 3-byte chars)`() throws {
            // 用 is 3 bytes in UTF-8, so 21 chars = 63 bytes + 1 ASCII = 64
            let localPart = String(repeating: "用", count: 21) + "a"
            let lp = try RFC_6531.EmailAddress.LocalPart(localPart)
            #expect(lp.rawValue == localPart)
            #expect(lp.rawValue.utf8.count == 64)
        }
    }

}

// MARK: - LocalPart Invalid Cases

extension RFC_6531.EmailAddress.LocalPart.Test {

    @Suite("RFC 6531 LocalPart - Invalid Cases")
    struct Invalid {

        @Test
        func `Empty local part`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.empty) {
                _ = try RFC_6531.EmailAddress.LocalPart("")
            }
        }

        // MARK: Length Violations

        @Test
        func `Local part too long (65 ASCII bytes)`() throws {
            let localPart = String(repeating: "a", count: 65)
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.tooLong(65)) {
                _ = try RFC_6531.EmailAddress.LocalPart(localPart)
            }
        }

        @Test
        func `Local part too long (66 UTF-8 bytes)`() throws {
            // 用 is 3 bytes, 22 chars = 66 bytes
            let localPart = String(repeating: "用", count: 22)
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.tooLong(66)) {
                _ = try RFC_6531.EmailAddress.LocalPart(localPart)
            }
        }

        // MARK: Dot Violations

        @Test
        func `Leading dot`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart(".user")
            }
        }

        @Test
        func `Trailing dot`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart("user.")
            }
        }

        @Test(
            arguments: [
                "user..name",
                "a..b",
                "user...name",
                "a....b",
                "用户..名",
            ]
        )
        func `Consecutive dots`(localPart: String) throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart(localPart)
            }
        }

        // MARK: Invalid Characters in Unquoted Atoms

        @Test(
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
        func `Invalid characters in unquoted atom`(localPart: String) throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart(localPart)
            }
        }

        // MARK: Invalid Quoted Strings

        @Test
        func `Unclosed quoted string`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart("\"user")
            }
        }

        @Test
        func `Empty quoted string`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart("\"\"")
            }
        }

        @Test
        func `Unescaped quote in quoted string`() throws {
            #expect(throws: RFC_6531.EmailAddress.LocalPart.Error.self) {
                _ = try RFC_6531.EmailAddress.LocalPart("\"user\"name\"")
            }
        }
    }

}

// MARK: - EmailAddress Valid Cases

extension RFC_6531.EmailAddress {

    @Suite("RFC 6531 EmailAddress - Valid Cases")
    struct Test {

        // MARK: Basic Formats

        @Test(
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
        func `Valid simple email addresses`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == nil)
            #expect(addr.rawValue == email)
        }

        @Test(
            arguments: [
                "user.name@example.com",
                "first.last@example.com",
                "a.b.c@example.com",
                "first.middle.last@example.com",
            ]
        )
        func `Valid dot-atom local parts in addresses`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == nil)
        }

        // MARK: UTF-8 Email Addresses (RFC 6531)

        @Test(
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
        func `Valid UTF-8 local parts`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == nil)
            #expect(addr.isASCII == false)
        }

        @Test(
            arguments: [
                "用户.名@example.com",
                "田中.太郎@example.com",
                "имя.фамилия@example.com",
            ]
        )
        func `Valid UTF-8 dot-atom addresses`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.isASCII == false)
        }

        // MARK: Display Name Formats

        @Test(
            arguments: [
                ("John Doe <user@example.com>", "John Doe", "user@example.com"),
                ("Jane <jane@example.com>", "Jane", "jane@example.com"),
                ("A B C <abc@example.com>", "A B C", "abc@example.com"),
            ]
        )
        func `Valid display names (unquoted)`(
            email: String,
            expectedName: String,
            expectedAddress: String
        ) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == expectedName)
            #expect(addr.address == expectedAddress)
        }

        @Test(
            arguments: [
                ("\"John Doe\" <user@example.com>", "John Doe", "user@example.com"),
                ("\"Doe, John\" <user@example.com>", "Doe, John", "user@example.com"),
            ]
        )
        func `Valid display names (quoted)`(
            email: String,
            expectedName: String,
            expectedAddress: String
        ) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == expectedName)
            #expect(addr.address == expectedAddress)
        }

        @Test(
            arguments: [
                ("张三 <user@example.com>", "张三", "user@example.com"),
                ("田中太郎 <user@example.com>", "田中太郎", "user@example.com"),
                ("Müller <user@example.com>", "Müller", "user@example.com"),
                ("Владимир <user@example.com>", "Владимир", "user@example.com"),
            ]
        )
        func `Valid UTF-8 display names`(
            email: String,
            expectedName: String,
            expectedAddress: String
        ) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == expectedName)
            #expect(addr.address == expectedAddress)
        }

        @Test(
            arguments: [
                "<user@example.com>",
                "<用户@example.com>",
            ]
        )
        func `Valid angle bracket format without display name`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.displayName == nil)
        }

        // MARK: Quoted Local Parts in Addresses

        @Test(
            arguments: [
                "\"user name\"@example.com",
                "\"user@domain\"@example.com",
                "\"..\"@example.com",
            ]
        )
        func `Valid quoted local parts in addresses`(email: String) throws {
            _ = try RFC_6531.EmailAddress(email)
        }

        // MARK: isASCII Property

        @Test
        func `isASCII is true for ASCII-only addresses`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr.isASCII == true)
        }

        @Test
        func `isASCII is false for UTF-8 local part`() throws {
            let addr = try RFC_6531.EmailAddress("用户@example.com")
            #expect(addr.isASCII == false)
        }

        @Test
        func `isASCII is false for UTF-8 display name`() throws {
            let addr = try RFC_6531.EmailAddress("张三 <user@example.com>")
            #expect(addr.isASCII == false)
        }
    }

}

// MARK: - EmailAddress Invalid Cases

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Invalid Cases")
    struct Invalid {

        @Test(
            arguments: [
                "userexample.com",
                "user",
                "用户example.com",
            ]
        )
        func `Missing @ sign`(email: String) throws {
            #expect(throws: RFC_6531.EmailAddress.Error.missingAtSign) {
                _ = try RFC_6531.EmailAddress(email)
            }
        }

        @Test
        func `Empty email`() throws {
            #expect(throws: RFC_6531.EmailAddress.Error.missingAtSign) {
                _ = try RFC_6531.EmailAddress("")
            }
        }

        @Test
        func `Empty local part`() throws {
            #expect(throws: RFC_6531.EmailAddress.Error.self) {
                _ = try RFC_6531.EmailAddress("@example.com")
            }
        }

        @Test
        func `Empty domain`() throws {
            #expect(throws: RFC_6531.EmailAddress.Error.self) {
                _ = try RFC_6531.EmailAddress("user@")
            }
        }

        @Test(
            arguments: [
                "user..name@example.com",
                ".user@example.com",
                "user.@example.com",
            ]
        )
        func `Invalid local part errors propagate`(email: String) throws {
            #expect(throws: RFC_6531.EmailAddress.Error.self) {
                _ = try RFC_6531.EmailAddress(email)
            }
        }

        @Test(
            arguments: [
                "user@-example.com",
                "user@example-.com",
            ]
        )
        func `Invalid domain errors propagate`(email: String) throws {
            #expect(throws: RFC_6531.EmailAddress.Error.self) {
                _ = try RFC_6531.EmailAddress(email)
            }
        }

        @Test(
            arguments: [
                "John Doe user@example.com>",
                "John Doe <user@example.com",
                "<>",
            ]
        )
        func `Malformed angle brackets`(email: String) throws {
            #expect(throws: RFC_6531.EmailAddress.Error.self) {
                _ = try RFC_6531.EmailAddress(email)
            }
        }
    }

}

// MARK: - Conversion Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Conversions")
    struct Conversion {

        @Test
        func `ASCII address converts to RFC 5321`() throws {
            let addr6531 = try RFC_6531.EmailAddress("user@example.com")
            let addr5321 = try RFC_5321.EmailAddress(addr6531)
            #expect(addr5321.address == "user@example.com")
        }

        @Test
        func `ASCII address with display name converts to RFC 5321`() throws {
            let addr6531 = try RFC_6531.EmailAddress("John Doe <user@example.com>")
            let addr5321 = try RFC_5321.EmailAddress(addr6531)
            #expect(addr5321.address == "user@example.com")
        }

        @Test
        func `UTF-8 address fails to convert to RFC 5321`() throws {
            let addr6531 = try RFC_6531.EmailAddress("用户@example.com")
            #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
                _ = try RFC_5321.EmailAddress(addr6531)
            }
        }

        @Test
        func `UTF-8 display name fails to convert to RFC 5321`() throws {
            let addr6531 = try RFC_6531.EmailAddress("张三 <user@example.com>")
            #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
                _ = try RFC_5321.EmailAddress(addr6531)
            }
        }

        @Test
        func `ASCII address converts to RFC 5322`() throws {
            let addr6531 = try RFC_6531.EmailAddress("user@example.com")
            let addr5322 = try RFC_5322.EmailAddress(addr6531)
            #expect(addr5322.address == "user@example.com")
        }

        @Test
        func `UTF-8 address fails to convert to RFC 5322`() throws {
            let addr6531 = try RFC_6531.EmailAddress("用户@example.com")
            #expect(throws: RFC_6531.EmailAddress.ConversionError.nonASCIICharacters) {
                _ = try RFC_5322.EmailAddress(addr6531)
            }
        }
    }

}

// MARK: - Round-Trip Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Round-Trip")
    struct RoundTrip {

        @Test(
            arguments: [
                "user@example.com",
                "user.name@example.com",
                "user+tag@example.com",
                "\"quoted\"@example.com",
            ]
        )
        func `Round-trip ASCII addresses`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            let serialized = addr.rawValue
            let reparsed = try RFC_6531.EmailAddress(serialized)
            #expect(addr == reparsed)
        }

        @Test(
            arguments: [
                "用户@example.com",
                "用户.名@example.com",
                "ユーザー@example.com",
            ]
        )
        func `Round-trip UTF-8 addresses`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            let serialized = addr.rawValue
            let reparsed = try RFC_6531.EmailAddress(serialized)
            #expect(addr == reparsed)
        }

        @Test(
            arguments: [
                "John Doe <user@example.com>",
                "张三 <user@example.com>",
            ]
        )
        func `Round-trip with display names`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            let serialized = addr.rawValue
            let reparsed = try RFC_6531.EmailAddress(serialized)
            #expect(addr.displayName == reparsed.displayName)
            #expect(addr.localPart == reparsed.localPart)
            #expect(addr.domain == reparsed.domain)
        }
    }

}

// MARK: - Codable Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Codable")
    struct Codable {

        @Test
        func `Encode and decode ASCII address`() throws {
            let original = try RFC_6531.EmailAddress("user@example.com")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
            #expect(original == decoded)
        }

        @Test
        func `Encode and decode UTF-8 address`() throws {
            let original = try RFC_6531.EmailAddress("用户@example.com")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
            #expect(original == decoded)
        }

        @Test
        func `Encode and decode with display name`() throws {
            let original = try RFC_6531.EmailAddress("张三 <user@example.com>")
            let encoded = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(RFC_6531.EmailAddress.self, from: encoded)
            #expect(original == decoded)
        }
    }

}

// MARK: - Hashable & Equatable Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Hashable & Equatable")
    struct Hashable {

        @Test
        func `Equal addresses have equal hashes`() throws {
            let addr1 = try RFC_6531.EmailAddress("user@example.com")
            let addr2 = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr1 == addr2)
            #expect(addr1.hashValue == addr2.hashValue)
        }

        @Test
        func `Different addresses are not equal`() throws {
            let addr1 = try RFC_6531.EmailAddress("user1@example.com")
            let addr2 = try RFC_6531.EmailAddress("user2@example.com")
            #expect(addr1 != addr2)
        }

        @Test
        func `Same address with different display names are not equal`() throws {
            let addr1 = try RFC_6531.EmailAddress("John <user@example.com>")
            let addr2 = try RFC_6531.EmailAddress("Jane <user@example.com>")
            #expect(addr1 != addr2)
        }

        @Test
        func `Can be used in Set`() throws {
            let addr1 = try RFC_6531.EmailAddress("user1@example.com")
            let addr2 = try RFC_6531.EmailAddress("user2@example.com")
            let addr3 = try RFC_6531.EmailAddress("user1@example.com")

            let set: Set<RFC_6531.EmailAddress> = [addr1, addr2, addr3]
            #expect(set.count == 2)
        }
    }

}

// MARK: - Component Access Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Component Access")
    struct Component {

        @Test
        func `Access local part`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr.localPart.rawValue == "user")
        }

        @Test
        func `Access domain`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr.domain.name == "example.com")
        }

        @Test
        func `Access display name when present`() throws {
            let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
            #expect(addr.displayName == "John Doe")
        }

        @Test
        func `Display name is nil when absent`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr.displayName == nil)
        }

        @Test
        func `Address property excludes display name`() throws {
            let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
            #expect(addr.address == "user@example.com")
        }
    }

}

// MARK: - Serialization Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Serialization")
    struct Serialization {

        @Test
        func `Serialize simple address`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(String(addr) == "user@example.com")
        }

        @Test
        func `Serialize with unquoted display name`() throws {
            let addr = try RFC_6531.EmailAddress("John Doe <user@example.com>")
            #expect(String(addr) == "John Doe <user@example.com>")
        }

        @Test
        func `Serialize with special characters quotes display name`() throws {
            let addr = try RFC_6531.EmailAddress(
                displayName: "Doe, John",
                localPart: try .init("user"),
                domain: try .init("example.com")
            )
            #expect(String(addr) == "\"Doe, John\" <user@example.com>")
        }

        @Test
        func `Serialize UTF-8 address`() throws {
            let addr = try RFC_6531.EmailAddress("用户@example.com")
            #expect(String(addr) == "用户@example.com")
        }

        @Test
        func `Serialize UTF-8 display name quotes when has special chars`() throws {
            let addr = try RFC_6531.EmailAddress(
                displayName: "张,三",
                localPart: try .init("user"),
                domain: try .init("example.com")
            )
            let serialized = String(addr)
            #expect(serialized.contains("\""))
        }
    }

}

// MARK: - Edge Cases and Boundary Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 - Edge Cases")
    struct EdgeCase {

        @Test
        func `Single character domain labels`() throws {
            let addr = try RFC_6531.EmailAddress("user@a.b.c")
            #expect(addr.domain.name == "a.b.c")
        }

        @Test
        func `Numbers in domain`() throws {
            let addr = try RFC_6531.EmailAddress("user@123.example.com")
            #expect(addr.domain.name == "123.example.com")
        }

        @Test
        func `All allowed special characters in local part`() throws {
            // Per RFC 5321/6531, these are allowed in atoms: !#$%&'*+\-/=?^_`{|}~
            let addr = try RFC_6531.EmailAddress("a!#$%&'*+-/=?^_`{|}~b@example.com")
            #expect(addr.localPart.rawValue == "a!#$%&'*+-/=?^_`{|}~b")
        }

        @Test
        func `Whitespace trimmed from display name`() throws {
            let addr = try RFC_6531.EmailAddress("  John Doe  <user@example.com>")
            #expect(addr.displayName == "John Doe")
        }

        @Test
        func `Empty display name becomes nil`() throws {
            let addr = try RFC_6531.EmailAddress("   <user@example.com>")
            #expect(addr.displayName == nil)
        }

        @Test
        func `4-byte UTF-8 emoji in local part (allowed per RFC 6531)`() throws {
            let addr = try RFC_6531.EmailAddress("user🙂@example.com")
            #expect(addr.localPart.rawValue == "user🙂")
        }

        @Test
        func `Emoji in quoted local part`() throws {
            let addr = try RFC_6531.EmailAddress("\"user🙂\"@example.com")
            #expect(addr.localPart.rawValue == "\"user🙂\"")
        }

        @Test
        func `RawRepresentable conformance`() throws {
            let addr = RFC_6531.EmailAddress(rawValue: "user@example.com")
            #expect(addr != nil)
            #expect(addr?.rawValue == "user@example.com")
        }

        @Test
        func `RawRepresentable returns nil for invalid`() throws {
            let addr = RFC_6531.EmailAddress(rawValue: "invalid")
            #expect(addr == nil)
        }

        @Test
        func `CustomStringConvertible`() throws {
            let addr = try RFC_6531.EmailAddress("user@example.com")
            #expect(addr.description == "user@example.com")
        }
    }

}

// MARK: - UTF-8 Multi-byte Sequence Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 - UTF-8 Byte Sequences")
    struct UTF8ByteSequence {

        @Test(
            arguments: [
                "café@example.com",  // é = C3 A9
                "naïve@example.com",  // ï = C3 AF
                "Ångström@example.com",  // Å = C3 85
            ]
        )
        func `2-byte UTF-8 sequences (Latin Extended, etc.)`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.isASCII == false)
        }

        @Test(
            arguments: [
                "日本語@example.com",  // Japanese
                "한국어@example.com",  // Korean
                "中文@example.com",  // Chinese
                "עברית@example.com",  // Hebrew
                "العربية@example.com",  // Arabic
            ]
        )
        func `3-byte UTF-8 sequences (CJK, etc.)`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.isASCII == false)
        }

        @Test(
            arguments: [
                "🎉party@example.com",
                "test🔥@example.com",
                "emoji👍@example.com",
            ]
        )
        func `4-byte UTF-8 sequences (Emoji) - allowed per RFC 6531`(email: String) throws {
            let addr = try RFC_6531.EmailAddress(email)
            #expect(addr.isASCII == false)
        }
    }

}

// MARK: - Constructor Tests

extension RFC_6531.EmailAddress.Test {

    @Suite("RFC 6531 EmailAddress - Constructors")
    struct Constructor {

        @Test
        func `Constructor from components without display name`() throws {
            let localPart = try RFC_6531.EmailAddress.LocalPart("user")
            let domain = try RFC_1123.Domain("example.com")
            let addr = RFC_6531.EmailAddress(localPart: localPart, domain: domain)

            #expect(addr.displayName == nil)
            #expect(addr.localPart == localPart)
            #expect(addr.domain == domain)
            #expect(addr.address == "user@example.com")
        }

        @Test
        func `Constructor from components with display name`() throws {
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

        @Test
        func `Constructor trims whitespace from display name`() throws {
            let localPart = try RFC_6531.EmailAddress.LocalPart("user")
            let domain = try RFC_1123.Domain("example.com")
            let addr = RFC_6531.EmailAddress(
                displayName: "  John Doe  ",
                localPart: localPart,
                domain: domain
            )

            #expect(addr.displayName == "John Doe")
        }

        @Test
        func `Constructor with empty display name becomes nil`() throws {
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

}
