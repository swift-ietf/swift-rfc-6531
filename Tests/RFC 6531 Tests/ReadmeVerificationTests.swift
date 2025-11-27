//
//  ReadmeVerificationTests.swift
//  swift-rfc-6531
//
//  Verifies that README code examples actually work
//

import RFC_6531
import RFC_1123
import RFC_5321
import RFC_5322
import Testing

@Suite
struct `README Verification` {

    @Test
    func `README Line 53-56: Parse internationalized email address`() throws {
        let email = try RFC_6531.EmailAddress("用户@example.com")
        #expect(email.localPart.description == "用户")
        #expect(email.domain.name == "example.com")
    }

    @Test
    func `README Line 58-61: Parse with internationalized display name`() throws {
        let named = try RFC_6531.EmailAddress("张三 <user@example.com>")
        #expect(named.displayName == "张三")
        #expect(named.address == "user@example.com")
    }

    @Test
    func `README Line 63-69: Create from components`() throws {
        let addr = try RFC_6531.EmailAddress(
            displayName: "田中太郎",
            localPart: .init("user"),
            domain: .init("example.com")
        )
        #expect(addr.description == "\"田中太郎\" <user@example.com>")
    }

    @Test
    func `README Line 75-77: ASCII detection`() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        #expect(asciiEmail.isASCII == true)

        let utf8Email = try RFC_6531.EmailAddress("用户@example.com")
        #expect(utf8Email.isASCII == false)
    }

    @Test
    func `README Line 82-88: Convert to RFC 5321`() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        let rfc5321 = try RFC_5321.EmailAddress(asciiEmail)
        #expect(rfc5321.description == "user@example.com")
    }

    @Test
    func `README Line 90-96: Convert to RFC 5322`() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        let rfc5322 = try RFC_5322.EmailAddress(asciiEmail)
        #expect(rfc5322.description == "user@example.com")
    }

    @Test
    func `README Line 102-105: UTF-8 length validation`() throws {
        let chinese = "用户名"  // 9 bytes in UTF-8
        let email = try RFC_6531.EmailAddress("\(chinese)@example.com")
        #expect(email.localPart.description == chinese)
    }

    @Test
    func `README Line 107-113: Local part too long`() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.self) {
            let longLocal = String(repeating: "用", count: 22)  // 66 bytes
            _ = try RFC_6531.EmailAddress("\(longLocal)@example.com")
        }
    }

    @Test
    func `README Line 119-122: Valid addresses`() throws {
        let valid1 = try RFC_6531.EmailAddress("user@example.com")
        let valid2 = try RFC_6531.EmailAddress("用户@example.com")
        let valid3 = try RFC_6531.EmailAddress("user.name@example.com")

        #expect(valid1.localPart.description == "user")
        #expect(valid2.localPart.description == "用户")
        #expect(valid3.localPart.description == "user.name")
    }

    @Test
    func `README Line 125-128: Missing at sign`() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.missingAtSign) {
            _ = try RFC_6531.EmailAddress("no-at-sign")
        }
    }

    @Test
    func `README Line 131-134: Consecutive dots`() throws {
        #expect(throws: RFC_6531.EmailAddress.Error.consecutiveDots) {
            _ = try RFC_6531.EmailAddress("user..name@example.com")
        }
    }
}
