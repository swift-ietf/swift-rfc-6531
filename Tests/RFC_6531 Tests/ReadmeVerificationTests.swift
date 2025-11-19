//
//  ReadmeVerificationTests.swift
//  swift-rfc-6531
//
//  Verifies that README code examples actually work
//

import RFC_6531
import Testing

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("README Line 53-56: Parse internationalized email address")
    func parseInternationalizedEmail() throws {
        let email = try RFC_6531.EmailAddress("用户@example.com")
        #expect(email.localPart.stringValue == "用户")
        #expect(email.domain.name == "example.com")
    }

    @Test("README Line 58-61: Parse with internationalized display name")
    func parseWithInternationalizedDisplayName() throws {
        let named = try RFC_6531.EmailAddress("张三 <user@example.com>")
        #expect(named.displayName == "张三")
        #expect(named.address == "user@example.com")
    }

    @Test("README Line 63-69: Create from components")
    func createFromComponents() throws {
        let addr = try RFC_6531.EmailAddress(
            displayName: "田中太郎",
            localPart: .init("user"),
            domain: .init("example.com")
        )
        #expect(addr.stringValue == "\"田中太郎\" <user@example.com>")
    }

    @Test("README Line 75-77: ASCII detection")
    func asciiDetection() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        #expect(asciiEmail.isASCII == true)

        let utf8Email = try RFC_6531.EmailAddress("用户@example.com")
        #expect(utf8Email.isASCII == false)
    }

    @Test("README Line 82-88: Convert to RFC 5321")
    func convertToRFC5321() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        let rfc5321 = try asciiEmail.toRFC5321()
        #expect(rfc5321.address == "user@example.com")
    }

    @Test("README Line 90-96: Convert to RFC 5322")
    func convertToRFC5322() throws {
        let asciiEmail = try RFC_6531.EmailAddress("user@example.com")
        let rfc5322 = try asciiEmail.toRFC5322()
        #expect(rfc5322.address == "user@example.com")
    }

    @Test("README Line 102-105: UTF-8 length validation")
    func utf8LengthValidation() throws {
        let chinese = "用户名"  // 9 bytes in UTF-8
        let email = try RFC_6531.EmailAddress("\(chinese)@example.com")
        #expect(email.localPart.stringValue == chinese)
    }

    @Test("README Line 107-113: Local part too long")
    func localPartTooLong() throws {
        #expect(throws: RFC_6531.EmailAddress.ValidationError.self) {
            let longLocal = String(repeating: "用", count: 22)  // 66 bytes
            _ = try RFC_6531.EmailAddress("\(longLocal)@example.com")
        }
    }

    @Test("README Line 119-122: Valid addresses")
    func validAddresses() throws {
        let valid1 = try RFC_6531.EmailAddress("user@example.com")
        let valid2 = try RFC_6531.EmailAddress("用户@example.com")
        let valid3 = try RFC_6531.EmailAddress("user.name@example.com")

        #expect(valid1.localPart.stringValue == "user")
        #expect(valid2.localPart.stringValue == "用户")
        #expect(valid3.localPart.stringValue == "user.name")
    }

    @Test("README Line 125-128: Missing at sign")
    func missingAtSign() throws {
        #expect(throws: RFC_6531.EmailAddress.ValidationError.missingAtSign) {
            _ = try RFC_6531.EmailAddress("no-at-sign")
        }
    }

    @Test("README Line 131-134: Consecutive dots")
    func consecutiveDots() throws {
        #expect(throws: RFC_6531.EmailAddress.ValidationError.consecutiveDots) {
            _ = try RFC_6531.EmailAddress("user..name@example.com")
        }
    }
}
