//
//  Email+HTML.swift
//  swift-email
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import Email_Type
import Foundation
import HTML

// MARK: - HTML Builder Extensions

extension Email {
    /// Creates an email with HTML content using the @HTMLBuilder DSL
    ///
    /// This provides a type-safe way to generate HTML email content using swift-html's DSL.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try Email(
    ///     to: [EmailAddress("recipient@example.com")],
    ///     from: EmailAddress("sender@example.com"),
    ///     subject: "Welcome!",
    ///     html: {
    ///         div {
    ///             h1 { "Welcome to our service!" }
    ///             p { "Thank you for signing up." }
    ///         }
    ///     }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - to: Recipient addresses (must not be empty)
    ///   - from: Sender address
    ///   - replyTo: Reply-to address (optional)
    ///   - cc: Carbon copy addresses (optional)
    ///   - bcc: Blind carbon copy addresses (optional)
    ///   - subject: Email subject
    ///   - html: HTML content builder closure
    ///   - additionalHeaders: Additional custom headers (optional)
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        replyTo: EmailAddress? = nil,
        cc: [EmailAddress]? = nil,
        bcc: [EmailAddress]? = nil,
        subject: String,
        @HTMLBuilder html: () -> any HTML,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws {
        let bytes = AnyHTML(html()).render()
        try self.init(
            to: to,
            from: from,
            replyTo: replyTo,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: .html(Data(bytes), charset: .utf8),
            additionalHeaders: additionalHeaders
        )
    }

    /// Creates an email with both plain text and HTML content using the @HTMLBuilder DSL
    ///
    /// This creates a multipart/alternative email with both text and HTML versions,
    /// allowing email clients to display the appropriate version.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try Email(
    ///     to: [EmailAddress("recipient@example.com")],
    ///     from: EmailAddress("sender@example.com"),
    ///     subject: "Newsletter",
    ///     text: "Welcome! Visit our website for more info.",
    ///     html: {
    ///         div {
    ///             h1 { "Welcome!" }
    ///             p {
    ///                 "Visit "
    ///                 a(href: .init(rawValue: "https://example.com")) { "our website" }
    ///                 " for more info."
    ///             }
    ///         }
    ///     }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - to: Recipient addresses (must not be empty)
    ///   - from: Sender address
    ///   - replyTo: Reply-to address (optional)
    ///   - cc: Carbon copy addresses (optional)
    ///   - bcc: Blind carbon copy addresses (optional)
    ///   - subject: Email subject
    ///   - text: Plain text content (fallback for clients that don't support HTML)
    ///   - html: HTML content builder closure
    ///   - additionalHeaders: Additional custom headers (optional)
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        replyTo: EmailAddress? = nil,
        cc: [EmailAddress]? = nil,
        bcc: [EmailAddress]? = nil,
        subject: String,
        additionalHeaders: [RFC_5322.Header] = [],
        @HTMLBuilder html: () -> any HTML,
        @StringBuilder text: () -> String
    ) throws {
        try self.init(
            to: to,
            from: from,
            replyTo: replyTo,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: .multipart(try .alternative(textContent: text(), htmlContent: String(html()))),
            additionalHeaders: additionalHeaders
        )
    }
}

// MARK: - Email.Body HTML Builder Extensions

extension Email.Body {
    /// Creates an HTML email body using the @HTMLBuilder DSL
    ///
    /// ## Example
    ///
    /// ```swift
    /// let body = Email.Body.html {
    ///     div {
    ///         h1 { "Hello, World!" }
    ///         p { "This is a test email." }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - charset: Character encoding (default: UTF-8)
    ///   - content: HTML content builder closure
    /// - Returns: An HTML email body
    public static func html(
        charset: RFC_2045.Charset = .utf8,
        @HTMLBuilder content: () -> any HTML
    ) -> Self {
        let bytes = AnyHTML(content()).render()
        return .html(Data(bytes), charset: charset)
    }
}
