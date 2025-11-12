//
//  EmailHTMLTests.swift
//  swift-email
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Email  // Our package that re-exports EmailType
import Foundation
import Testing

@Suite("Email HTML Builder Tests")
struct EmailHTMLTests {

    // MARK: - Basic HTML Email Tests

    @Test("Create HTML-only email with simple content")
    func htmlOnlyEmailSimple() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test Email")
        {
            HTMLDocument {
                div {
                    h1 { "Hello, World!" }
                    p { "This is a test email." }
                }
                .padding(.rem(2))
            } head: {
                title { "Test Email" }
                meta(charset: .utf8)()
            }
        }
        

        #expect(email.to.count == 1)
        #expect(email.to[0].rawValue == "recipient@example.com")
        #expect(email.from.rawValue == "sender@example.com")
        #expect(email.subject == "Test Email")

        // Verify body is HTML type
        if case .html(let data, let charset) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(charset == "UTF-8")
            #expect(content.contains("Hello, World!"))
            #expect(content.contains("This is a test email."))
            #expect(content.contains("<h1>"))
            #expect(content.contains("<p>"))
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    @Test("Create HTML-only email with complex structure")
    func htmlOnlyEmailComplex() throws {
        let email = try Email(
            to: [
                EmailAddress("user1@example.com"),
                EmailAddress("user2@example.com")
            ],
            from: EmailAddress("noreply@company.com"),
            cc: [EmailAddress("cc@example.com")],
            bcc: [EmailAddress("bcc@example.com")],
            subject: "Welcome to our service!",
            html: {
                HTMLDocument {
                    div {
                        h1 { "Welcome!" }
                            .fontSize(.rem(2))
                        p {
                            "Thank you for joining "
                            strong { "our amazing service" }
                            "."
                        }
                        ul {
                            li { "Feature 1: Fast" }
                            li { "Feature 2: Secure" }
                            li { "Feature 3: Reliable" }
                        }
                        a(href: .init(rawValue: "https://example.com/verify")) {
                            "Verify your email"
                        }
                            .display(.inlineBlock)
                            .padding(.rem(1))
                            .backgroundColor(.blue)
                            .color(.white)
                            .borderRadius(.px(4))
                            .textDecoration(TextDecoration.none)
                    }
                        .padding(.rem(2))
                } head: {
                    title { "Welcome Email" }
                    meta(charset: .utf8)()
                    meta(name: .viewport, content: "width=device-width, initial-scale=1")()
                }
            },
            headers: ["X-Custom-Header": "test-value"]
        )

        #expect(email.to.count == 2)
        #expect(email.cc?.count == 1)
        #expect(email.bcc?.count == 1)
        #expect(email.headers["X-Custom-Header"] == "test-value")

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content.contains("<!doctype html>") || content.contains("<!DOCTYPE html>"))
            #expect(content.contains("Welcome!"))
            #expect(content.contains("our amazing service"))
            #expect(content.contains("Feature 1: Fast"))
            #expect(content.contains("https://example.com/verify"))
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    // MARK: - Multipart Email Tests

    @Test("Create multipart email with text and HTML")
    func multipartEmail() throws {
        let plainText = "Welcome! Visit https://example.com for more info."

        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Newsletter",
            text: plainText,
            html: {
                HTMLDocument {
                    div {
                        h1 { "Welcome!" }
                            .fontSize(.rem(2))
                        p {
                            "Visit "
                            a(href: .init(rawValue: "https://example.com")) { "our website" }
                            " for more info."
                        }
                    }
                        .padding(.rem(2))
                } head: {
                    title { "Newsletter" }
                    meta(charset: .utf8)()
                }
            }
        )

        #expect(email.subject == "Newsletter")

        // Verify body is multipart type
        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains(plainText))
            #expect(rendered.contains("Welcome!"))
            #expect(rendered.contains("our website"))
            #expect(rendered.contains("https://example.com"))
        } else {
            Issue.record("Expected multipart body type")
        }
    }

    @Test("Multipart email with all optional fields")
    func multipartEmailComplete() throws {
        let email = try Email(
            to: [EmailAddress("to@example.com")],
            from: EmailAddress("from@example.com"),
            replyTo: EmailAddress("reply@example.com"),
            cc: [EmailAddress("cc@example.com")],
            bcc: [EmailAddress("bcc@example.com")],
            subject: "Complete Email",
            text: "Plain text version",
            html: {
                HTMLDocument {
                    div {
                        h1 { "HTML version" }
                    }
                } head: {
                    title { "Complete Email" }
                    meta(charset: .utf8)()
                }
            },
            headers: [
                "X-Priority": "1",
                "X-Mailer": "swift-email"
            ]
        )

        #expect(email.replyTo?.rawValue == "reply@example.com")
        #expect(email.headers["X-Priority"] == "1")
        #expect(email.headers["X-Mailer"] == "swift-email")
    }

    // MARK: - Email.Body Builder Tests

    @Test("Create Email.Body with HTML builder")
    func bodyHtmlBuilder() throws {
        let body = Email.Body.html {
            HTMLDocument {
                div {
                    h2 { "Body Test" }
                    p { "Testing Email.Body.html builder" }
                }
            } head: {
                title { "Body Test" }
                meta(charset: .utf8)()
            }
        }

        #expect(body.contentType.type == "text")
        #expect(body.contentType.subtype == "html")
        #expect(body.contentType.parameters["charset"] == "UTF-8")

        let content = body.content
        #expect(content.contains("Body Test"))
        #expect(content.contains("Testing Email.Body.html builder"))
    }

    @Test("Email.Body with custom charset")
    func bodyCustomCharset() throws {
        let body = Email.Body.html(charset: "ISO-8859-1") {
            HTMLDocument {
                p { "Test content" }
            } head: {
                title { "Test" }
                meta(charset: .utf8)()
            }
        }

        #expect(body.contentType.parameters["charset"] == "ISO-8859-1")
    }

    // MARK: - Error Handling Tests

    @Test("Email with empty recipients throws error")
    func emptyRecipientsError() {
        #expect(throws: Email.Error.self) {
            try Email(
                to: [],
                from: EmailAddress("sender@example.com"),
                subject: "Test",
                html: { p { "Test" } }
            )
        }
    }

    // MARK: - Re-export Verification Tests

    @Test("Can use EmailAddress from re-export")
    func emailAddressReExport() throws {
        let address = try EmailAddress("test@example.com")
        #expect(address.rawValue == "test@example.com")
    }

    @Test("Can create Email with traditional string HTML")
    func traditionalStringHtml() throws {
        // Verify backward compatibility - can still use string-based init
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            html: "<h1>Hello</h1>"
        )

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content == "<h1>Hello</h1>")
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    // MARK: - Practical Use Case Tests

    @Test("Welcome email with verification link")
    func welcomeEmailUseCase() throws {
        let userName = "John Doe"
        let verificationToken = "abc123xyz"
        let verificationUrl = "https://example.com/verify?token=\(verificationToken)"

        let email = try Email(
            to: [EmailAddress("john.doe@example.com")],
            from: EmailAddress("noreply@example.com"),
            replyTo: EmailAddress("support@example.com"),
            subject: "Welcome to Example.com - Please verify your email",
            text: """
            Hi \(userName),

            Welcome to Example.com!

            Please verify your email by clicking this link:
            \(verificationUrl)

            If you didn't sign up for this account, please ignore this email.

            Best regards,
            The Example.com Team
            """,
            html: {
                HTMLDocument {
                    div {
                        h1 { "Welcome to Example.com!" }
                            .fontSize(.rem(2))
                        p { "Hi \(userName)," }
                        p { "Thank you for signing up. Please verify your email address by clicking the button below:" }
                            .marginBottom(.rem(1.5))
                        p {
                            a(href: .init(rawValue: verificationUrl)) {
                                "Verify Email Address"
                            }
                                .display(.inlineBlock)
                                .padding(vertical: .rem(0.75), horizontal: .rem(1.5))
                                .backgroundColor(.blue)
                                .color(.white)
                                .textDecoration(TextDecoration.none)
                                .borderRadius(.px(4))
                        }
                        p {
                            "If you didn't sign up for this account, please ignore this email."
                        }
                            .marginTop(.rem(2))
                            .fontSize(.rem(0.875))
                        p {
                            "Best regards,"
                            br()
                            "The Example.com Team"
                        }
                            .fontSize(.rem(0.875))
                    }
                        .maxWidth(.px(600))
                        .margin(horizontal: .auto)
                        .padding(.rem(2))
                } head: {
                    title { "Welcome to Example.com" }
                    meta(charset: .utf8)()
                    meta(name: .viewport, content: "width=device-width, initial-scale=1")()
                }
            },
            headers: [
                "X-Email-Type": "verification",
                "X-Priority": "1"
            ]
        )

        #expect(email.to[0].rawValue == "john.doe@example.com")
        #expect(email.replyTo?.rawValue == "support@example.com")
        #expect(email.subject.contains("verify"))
        #expect(email.headers["X-Email-Type"] == "verification")

        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains(userName))
            #expect(rendered.contains(verificationUrl))
            #expect(rendered.contains("Verify Email Address"))
        } else {
            Issue.record("Expected multipart body type")
        }
    }

    @Test("Newsletter email with multiple sections")
    func newsletterEmailUseCase() throws {
        struct Article {
            let title: String
            let summary: String
            let url: String
        }

        let articles = [
            Article(
                title: "New Feature Released",
                summary: "We've just launched an amazing new feature...",
                url: "https://example.com/blog/new-feature"
            ),
            Article(
                title: "Tips and Tricks",
                summary: "Learn how to get the most out of our platform...",
                url: "https://example.com/blog/tips"
            )
        ]

        let plainText = articles.map { "• \($0.title)\n  \($0.summary)\n  Read more: \($0.url)" }.joined(separator: "\n\n")

        let email = try Email(
            to: [EmailAddress("subscriber@example.com")],
            from: EmailAddress("newsletter@example.com"),
            subject: "Monthly Newsletter - \(Date.now.formatted(.dateTime.month().year()))",
            text: plainText,
            html: {
                HTMLDocument {
                    div {
                        h1 { "Monthly Newsletter" }
                            .fontSize(.rem(2.5))
                            .marginBottom(.rem(2))

                        HTMLForEach(articles) { article in
                            div {
                                h2 { article.title }
                                    .fontSize(.rem(1.5))
                                    .marginBottom(.rem(0.5))
                                p { article.summary }
                                    .marginBottom(.rem(1))
                                p {
                                    a(href: .init(rawValue: article.url)) { "Read more →" }
                                        .color(.blue)
                                        .textDecoration(TextDecoration.none)
                                }
                            }
                                .padding(bottom: .rem(1.5))
                                .marginBottom(.rem(1.5))
                        }

                        div {
                            p {
                                "Thanks for being a subscriber!"
                            }
                            p {
                                "Questions? "
                                a(href: .init(rawValue: "mailto:support@example.com")) { "Contact us" }
                            }
                        }
                            .fontSize(.rem(0.875))
                            .marginTop(.rem(2))
                    }
                        .maxWidth(.px(600))
                        .margin(horizontal: .auto)
                        .padding(.rem(2))
                } head: {
                    title { "Monthly Newsletter" }
                    meta(charset: .utf8)()
                    meta(name: .viewport, content: "width=device-width, initial-scale=1")()
                }
            }
        )

        #expect(email.subject.contains("Newsletter"))

        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains("New Feature Released"))
            #expect(rendered.contains("Tips and Tricks"))
            #expect(rendered.contains("https://example.com/blog/new-feature"))
        } else {
            Issue.record("Expected multipart body type")
        }
    }
}
