//
//  AppleMailTests.swift
//  swift-email
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Email
import Foundation
import Testing

@Suite("Apple Mail Format Tests")
struct AppleMailTests {
    
    // MARK: - Basic AppleMail.Message Creation
    
    @Test("Create AppleMail.Message from simple Email")
    func createAppleMailMessageSimple() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test Email",
            body: "Hello, World!"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify basic RFC 5322 headers
        #expect(emlContent.contains("From: sender@example.com"))
        #expect(emlContent.contains("To: recipient@example.com"))
        #expect(emlContent.contains("Subject: Test Email"))
        #expect(emlContent.contains("Date: "))
        #expect(emlContent.contains("Message-ID: "))
        
        // Verify Apple-specific headers
        #expect(emlContent.contains("Mime-Version: 1.0 (Mac OS X Mail 16.0 \\(3826.700.71\\))"))
        #expect(emlContent.contains("X-Apple-Base-Url: x-msg://1/"))
        #expect(emlContent.contains("X-Universally-Unique-Identifier: "))
        #expect(emlContent.contains("X-Apple-Mail-Remote-Attachments: YES"))
        #expect(emlContent.contains("X-Apple-Windows-Friendly: 1"))
        #expect(emlContent.contains("X-Uniform-Type-Identifier: com.apple.mail-draft"))
        
        // Verify body content
        #expect(emlContent.contains("Hello, World!"))
    }
    
    @Test("Create AppleMail.Message with custom UUID")
    func createAppleMailMessageCustomUUID() throws {
        let customUUID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test content"
        )

        let appleEmail = try AppleMail.Message(
            from: email,
            universalUUID: customUUID
        )
        let emlContent = appleEmail.description

        #expect(emlContent.contains("X-Universally-Unique-Identifier: \(customUUID.uuidString)"))
    }
    
    @Test("AppleMail.Message with HTML content")
    func appleEmailWithHTML() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "HTML Email",
            html: "<h1>Hello, World!</h1><p>This is a test.</p>"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify Content-Type header for HTML
        #expect(emlContent.contains("Content-Type: text/html"))
        #expect(emlContent.contains("charset=UTF-8"))
        
        // Verify HTML content
        #expect(emlContent.contains("<h1>Hello, World!</h1>"))
        #expect(emlContent.contains("<p>This is a test.</p>"))
    }
    
    @Test("AppleMail.Message with multipart content")
    func appleEmailWithMultipart() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Multipart Email",
            text: "Plain text version",
            html: "<h1>HTML version</h1>"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify multipart Content-Type
        #expect(emlContent.contains("Content-Type: multipart/alternative"))
        #expect(emlContent.contains("boundary="))
        
        // Verify both text and HTML parts
        #expect(emlContent.contains("Plain text version"))
        #expect(emlContent.contains("<h1>HTML version</h1>"))
    }
    
    // MARK: - Complete Email Tests
    
    @Test("AppleMail.Message with all email fields")
    func appleEmailComplete() throws {
        let email = try Email(
            to: [
                EmailAddress("to1@example.com"),
                EmailAddress("to2@example.com")
            ],
            from: EmailAddress("sender@example.com"),
            replyTo: EmailAddress("reply@example.com"),
            cc: [EmailAddress("cc@example.com")],
            bcc: [EmailAddress("bcc@example.com")],
            subject: "Complete Email",
            body: "Test body",
            additionalHeaders: [
                .init(name: "X-Custom-Header", value: "custom-value"),
                .init(name: "X-Priority", value: "1")
            ]
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify all recipient types
        #expect(emlContent.contains("To: to1@example.com"))
        #expect(emlContent.contains("to2@example.com"))
        #expect(emlContent.contains("Cc: cc@example.com"))
        #expect(emlContent.contains("Reply-To: reply@example.com"))
        // BCC should NOT appear in message headers
        #expect(!emlContent.contains("Bcc:"))
        
        // Verify custom headers
        #expect(emlContent.contains("X-Custom-Header: custom-value"))
        #expect(emlContent.contains("X-Priority: 1"))
        
        // Verify Apple headers are still present
        #expect(emlContent.contains("X-Apple-Base-Url: x-msg://1/"))
    }
    
    // MARK: - EmailDocument Integration Tests
    
    @Test("AppleMail.Message from EmailDocument")
    func appleEmailFromDocument() throws {
        struct TestEmailDocument: EmailDocument {
            var body: some HTML {
                HTMLDocument {
                    div {
                        h1 { "Test Email" }
                        p { "This is from EmailDocument" }
                    }
                } head: {
                    Title { "Test" }
                    meta(charset: .utf8)()
                }
            }
        }
        
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Document Email",
            html: {
                TestEmailDocument()
            }
        )
        
        let appleEmail = try AppleMail.Message(
            emailDocument: TestEmailDocument(),
            from: email
        )
        let emlContent = appleEmail.description
        
        // Verify document renders
        #expect(emlContent.contains("From: sender@example.com"))
        #expect(emlContent.contains("Subject: Document Email"))
        
        // Verify Apple headers
        #expect(emlContent.contains("X-Apple-Base-Url: x-msg://1/"))
        #expect(emlContent.contains("X-Uniform-Type-Identifier: com.apple.mail-draft"))
    }
    
    // MARK: - RFC 5322 Compliance Tests
    
    @Test("AppleMail.Message produces valid .eml structure")
    func validEmlStructure() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test content"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify RFC 5322 required headers
        #expect(emlContent.contains("From: "))
        #expect(emlContent.contains("To: "))
        #expect(emlContent.contains("Subject: "))
        #expect(emlContent.contains("Date: "))
        #expect(emlContent.contains("Message-ID: "))
        
        // Verify headers/body separator (CRLF CRLF)
        #expect(emlContent.contains("\r\n\r\n"))
        
        // Verify CRLF line endings (not just LF)
        #expect(emlContent.contains("\r\n"))
        
        // Verify Content-Type header
        #expect(emlContent.contains("Content-Type: "))
    }
    
    @Test("Message-ID format is valid")
    func messageIdFormat() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Extract Message-ID
        let lines = emlContent.components(separatedBy: "\r\n")
        let messageIdLine = lines.first { $0.hasPrefix("Message-ID: ") }
        
        #expect(messageIdLine != nil)
        if let messageIdLine = messageIdLine {
            let messageId = messageIdLine.replacingOccurrences(of: "Message-ID: ", with: "")
            // RFC 5322: Message-ID format is <id-left@id-right>
            #expect(messageId.hasPrefix("<"))
            #expect(messageId.hasSuffix(">"))
            #expect(messageId.contains("@"))
        }
    }
    
    // MARK: - HTML Builder Integration Tests
    
    @Test("AppleMail.Message with HTML builder content")
    func appleEmailWithHTMLBuilder() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Welcome!"
        ) {
            HTMLDocument {
                div {
                    h1 { "Welcome to our service!" }
                        .fontSize(.rem(2))
                    p { "Thank you for signing up." }
                    a(href: .init(rawValue: "https://example.com/verify")) {
                        "Verify your email"
                    }
                    .display(.inlineBlock)
                    .padding(.rem(1))
                    .backgroundColor(.blue)
                    .color(.white)
                }
                .padding(.rem(2))
            } head: {
                title { "Welcome" }
                meta(charset: .utf8)()
            }
        }
        
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify HTML builder output is in the email
        #expect(emlContent.contains("Welcome to our service!"))
        #expect(emlContent.contains("Thank you for signing up"))
        #expect(emlContent.contains("https://example.com/verify"))
        #expect(emlContent.contains("<!doctype html>") || emlContent.contains("<!DOCTYPE html>"))
        
        // Verify Apple headers
        #expect(emlContent.contains("X-Apple-Base-Url: x-msg://1/"))
    }
    
    @Test("AppleMail.Message with styled HTML content")
    func appleEmailStyledHTML() throws {
        let email = try Email(
            to: [EmailAddress("subscriber@example.com")],
            from: EmailAddress("newsletter@example.com"),
            subject: "Monthly Newsletter",
            text: "Plain text version of newsletter"
        ) {
            HTMLDocument {
                div {
                    h1 { "Monthly Newsletter" }
                        .fontSize(.rem(2.5))
                    
                    div {
                        h2 { "Feature Article" }
                            .fontSize(.rem(1.5))
                        p { "Check out our latest features..." }
                    }
                    .padding(.rem(1))
                    .backgroundColor(.blue)
                    .borderRadius(.px(8))
                }
                .maxWidth(.px(600))
                .margin(horizontal: .auto)
                .padding(.rem(2))
            } head: {
                Title { "Newsletter" }
                meta(charset: .utf8)()
                meta(name: .viewport, content: "width=device-width, initial-scale=1")()
            }
        }
        
        
        let appleEmail = try AppleMail.Message(from: email)
        let emlContent = appleEmail.description
        
        // Verify multipart structure with styled HTML
        #expect(emlContent.contains("Content-Type: multipart/alternative"))
        #expect(emlContent.contains("Plain text version of newsletter"))
        #expect(emlContent.contains("Monthly Newsletter"))
        #expect(emlContent.contains("Feature Article"))
        
        // Verify Apple mail draft headers
        #expect(emlContent.contains("X-Uniform-Type-Identifier: com.apple.mail-draft"))
    }
    
    // MARK: - Access to RFC 5322 Message
    
    @Test("Can access underlying RFC 5322 message")
    func accessRFC5322Message() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: "Test content"
        )
        
        let appleEmail = try AppleMail.Message(from: email)
        let message = appleEmail.rfc5322Message
        
        // Verify we can access the underlying message
        #expect(message.from.addressValue == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.to[0].addressValue == "recipient@example.com")
        #expect(message.subject == "Test")
        #expect(message.bodyString == "Test content")
        
        // Verify Apple headers are in additional headers
        #expect(message.additionalHeaders["X-Apple-Base-Url"] == "x-msg://1/")
        #expect(message.additionalHeaders["X-Uniform-Type-Identifier"] == "com.apple.mail-draft")
    }
}
