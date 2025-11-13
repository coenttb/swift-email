//
//  ReadmeVerificationTests.swift
//  swift-email
//
//  Created by Coen ten Thije Boonkkamp on 13/11/2025.
//

import Email
import Foundation
import Testing

@Suite("README Verification")
struct ReadmeVerificationTests {

    // MARK: - Quick Start Examples

    @Test("README Example: Simple HTML Email")
    func simpleHtmlEmail() throws {
        // From README line 49-65
        let email = try Email(
            to: [EmailAddress("user@example.com")],
            from: EmailAddress("hello@company.com"),
            subject: "Welcome!"
        ) {
            HTMLDocument {
                div {
                    h1 { "Welcome to our service!" }
                    p { "Thank you for signing up." }
                }
                .padding(.rem(2))
                .fontFamily(.withFallback(["system-ui"], fallback: .sansSerif))
            } head: {
                title { "Welcome!" }
                meta(charset: .utf8)()
            }
        }

        #expect(email.to.count == 1)
        #expect(email.to[0].rawValue == "user@example.com")
        #expect(email.from.rawValue == "hello@company.com")
        #expect(email.subject == "Welcome!")

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content.contains("Welcome to our service!"))
            #expect(content.contains("Thank you for signing up."))
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    @Test("README Example: Welcome Email with Styled Button")
    func welcomeEmailWithStyledButton() throws {
        // From README line 70-112
        let verificationUrl = "https://example.com/verify?token=abc123"

        let email = try Email(
            to: [EmailAddress("user@example.com")],
            from: EmailAddress("noreply@company.com"),
            subject: "Verify your email"
        ) {
            HTMLDocument {
                div {
                    h1 { "Welcome!" }
                        .fontSize(.rem(2.5))
                        .marginBottom(.rem(1))

                    p { "Click the button below to verify your email address:" }
                        .marginBottom(.rem(2))

                    a(href: .init(rawValue: verificationUrl)) {
                        "Verify Email Address"
                    }
                    .display(.inlineBlock)
                    .padding(vertical: .rem(0.75), horizontal: .rem(1.5))
                    .backgroundColor(.blue)
                    .color(.white)
                    .textDecoration(TextDecoration.none)
                    .borderRadius(.px(6))
                    .fontWeight(.semiBold)

                    p { "Thanks for signing up!" }
                        .marginTop(.rem(2))
                        .fontSize(.rem(0.875))
                        .color(.gray600)
                }
                .fontFamily(.withFallback(["system-ui", "-apple-system"], fallback: .sansSerif))
                .maxWidth(.px(600))
                .margin(horizontal: .auto)
                .padding(.rem(2))
            } head: {
                title { "Verify Your Email" }
                meta(charset: .utf8)()
                meta(name: .viewport, content: "width=device-width, initial-scale=1")()
            }
        }

        #expect(email.to[0].rawValue == "user@example.com")
        #expect(email.from.rawValue == "noreply@company.com")
        #expect(email.subject == "Verify your email")

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content.contains("Welcome!"))
            #expect(content.contains("Verify Email Address"))
            #expect(content.contains(verificationUrl))
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    @Test("README Example: Multipart Email (Text + HTML)")
    func multipartEmail() throws {
        // From README line 117-146
        let email = try Email(
            to: [EmailAddress("subscriber@example.com")],
            from: EmailAddress("newsletter@example.com"),
            subject: "Monthly Newsletter",
            text: "Welcome! Visit https://example.com for more info.",
            html: {
                HTMLDocument {
                    div {
                        h1 { "Welcome!" }
                            .fontSize(.rem(2))
                            .color(.blue)

                        p {
                            "Visit "
                            a(href: .init(rawValue: "https://example.com")) { "our website" }
                            " for more info."
                        }
                    }
                    .fontFamily(.withFallback(["system-ui"], fallback: .sansSerif))
                    .padding(.rem(2))
                    .maxWidth(.px(600))
                    .margin(horizontal: .auto)
                } head: {
                    title { "Newsletter" }
                    meta(charset: .utf8)()
                    meta(name: .viewport, content: "width=device-width, initial-scale=1")()
                }
            }
        )

        #expect(email.to[0].rawValue == "subscriber@example.com")
        #expect(email.from.rawValue == "newsletter@example.com")
        #expect(email.subject == "Monthly Newsletter")

        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains("Welcome!"))
            #expect(rendered.contains("https://example.com"))
        } else {
            Issue.record("Expected multipart body type")
        }
    }

    // MARK: - Usage Examples

    @Test("README Example: Newsletter with Dynamic Content")
    func newsletterWithDynamicContent() throws {
        // From README line 155-222
        struct Article {
            let title: String
            let summary: String
            let url: String
        }

        let articles: [Article] = [
            Article(
                title: "New Features",
                summary: "Check out our latest updates...",
                url: "https://example.com/blog/new"
            ),
            Article(
                title: "Tips & Tricks",
                summary: "Learn how to...",
                url: "https://example.com/blog/tips"
            ),
        ]

        let email = try Email(
            to: [EmailAddress("subscriber@example.com")],
            from: EmailAddress("newsletter@example.com"),
            subject: "Monthly Newsletter",
            text: articles.map { "\($0.title)\n\($0.summary)\n\($0.url)" }
                .joined(separator: "\n\n"),
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
                                    .color(.gray700)

                                a(href: .init(rawValue: article.url)) { "Read more →" }
                                    .color(.blue)
                                    .textDecoration(TextDecoration.none)
                            }
                            .padding(bottom: .rem(1.5))
                            .marginBottom(.rem(1.5))
                            .borderBottom(width: .px(1), color: .gray200)
                        }

                        p { "Thanks for being a subscriber!" }
                            .marginTop(.rem(2))
                            .fontSize(.rem(0.875))
                            .color(.gray600)
                    }
                    .fontFamily(
                        .withFallback(["system-ui", "-apple-system"], fallback: .sansSerif)
                    )
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

        #expect(email.to[0].rawValue == "subscriber@example.com")
        #expect(email.subject == "Monthly Newsletter")

        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains("New Features"))
            #expect(rendered.contains("Tips & Tricks"))
            #expect(rendered.contains("https://example.com/blog/new"))
            #expect(rendered.contains("https://example.com/blog/tips"))
        } else {
            Issue.record("Expected multipart body type")
        }
    }

    @Test("README Example: Email with All Optional Fields")
    func emailWithAllOptionalFields() throws {
        // From README line 227-255
        let email = try Email(
            to: [
                EmailAddress("user1@example.com"),
                EmailAddress("user2@example.com"),
            ],
            from: EmailAddress("noreply@company.com"),
            replyTo: EmailAddress("support@company.com"),
            cc: [EmailAddress("cc@example.com")],
            bcc: [EmailAddress("bcc@example.com")],
            subject: "Important Notification",
            text: "Plain text version of the email.",
            html: {
                HTMLDocument {
                    div {
                        h1 { "Important Notification" }
                        p { "This email includes all optional fields." }
                    }
                    .padding(.rem(2))
                } head: {
                    title { "Notification" }
                    meta(charset: .utf8)()
                }
            },
            additionalHeaders: [
                .init(name: "X-Priority", value: "1"),
                .init(name: "X-Mailer", value: "swift-email"),
            ]
        )

        #expect(email.to.count == 2)
        #expect(email.to[0].rawValue == "user1@example.com")
        #expect(email.to[1].rawValue == "user2@example.com")
        #expect(email.from.rawValue == "noreply@company.com")
        #expect(email.replyTo?.rawValue == "support@company.com")
        #expect(email.cc?.count == 1)
        #expect(email.bcc?.count == 1)
        #expect(email.additionalHeaders["X-Priority"] == "1")
        #expect(email.additionalHeaders["X-Mailer"] == "swift-email")

        if case .multipart(let multipart) = email.body {
            let rendered = multipart.render()
            #expect(rendered.contains("Important Notification"))
            #expect(rendered.contains("Plain text version of the email."))
        } else {
            Issue.record("Expected multipart body type")
        }
    }

    @Test("README Example: Creating Email Bodies Separately")
    func creatingEmailBodiesSeparately() throws {
        // From README line 262-284
        let body = Email.Body.html {
            HTMLDocument {
                div {
                    h1 { "Hello, World!" }
                        .fontSize(.rem(2))
                    p { "This is a test email." }
                        .lineHeight(1.6)
                }
                .padding(.rem(2))
                .fontFamily(.withFallback(["system-ui"], fallback: .sansSerif))
            } head: {
                title { "Test Email" }
                meta(charset: .utf8)()
            }
        }

        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            body: body
        )

        #expect(email.to[0].rawValue == "recipient@example.com")
        #expect(email.from.rawValue == "sender@example.com")
        #expect(email.subject == "Test")

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content.contains("Hello, World!"))
            #expect(content.contains("This is a test email."))
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    @Test("README Example: Custom Character Encoding")
    func customCharacterEncoding() throws {
        // From README line 291-299
        let body = Email.Body.html(charset: "ISO-8859-1") {
            HTMLDocument {
                p { "Content with custom charset" }
            } head: {
                title { "Custom Encoding" }
                meta(charset: .utf8)()
            }
        }

        #expect(body.contentType.parameters["charset"] == "ISO-8859-1")

        let content = body.content
        #expect(content.contains("Content with custom charset"))
    }

    // MARK: - Backward Compatibility

    @Test("README Example: Backward Compatibility")
    func backwardCompatibility() throws {
        // From README line 350-356
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test",
            html: "<h1>Hello</h1>"  // String-based HTML still supported
        )

        #expect(email.to[0].rawValue == "recipient@example.com")
        #expect(email.from.rawValue == "sender@example.com")
        #expect(email.subject == "Test")

        if case .html(let data, _) = email.body {
            let content = String(data: data, encoding: .utf8)!
            #expect(content == "<h1>Hello</h1>")
        } else {
            Issue.record("Expected HTML body type")
        }
    }

    // MARK: - Additional Verification Tests

    @Test("Verify EmailAddress re-export from Email module")
    func emailAddressReExport() throws {
        // Verify we can use EmailAddress directly from Email module
        let address = try EmailAddress("test@example.com")
        #expect(address.rawValue == "test@example.com")
    }

    @Test("Verify HTML types are accessible via exports")
    func htmlTypesAccessible() throws {
        // Verify that HTML types from swift-html are accessible
        let email = try Email(
            to: [EmailAddress("test@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Test"
        ) {
            // Using HTMLDocument which should be exported
            HTMLDocument {
                div {
                    h1 { "Test" }
                }
            } head: {
                title { "Test" }
                meta(charset: .utf8)()
            }
        }

        #expect(email.subject == "Test")
    }
}
