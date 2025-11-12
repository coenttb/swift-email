//
//  AppleMail.swift
//  swift-email
//
//  Created by Coen ten Thije Boonkkamp on 21/07/2025.
//

import EmailType
import Foundation
import RFC_5322

/// Apple Mail email format
///
/// Provides encoding and decoding of Apple Mail messages with Apple-specific headers.
public struct AppleMail {}

extension AppleMail {

    /// An email message in Apple Mail format
    ///
    /// Wraps an RFC 5322 message with Apple-specific headers for compatibility
    /// with Apple Mail applications.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let email = try Email(
    ///     to: [EmailAddress("recipient@example.com")],
    ///     from: EmailAddress("sender@example.com"),
    ///     subject: "Hello",
    ///     body: "Hello, World!"
    /// )
    ///
    /// let message = try AppleMail.Message(from: email)
    /// let emlContent = message.description
    /// ```
    public struct Message: CustomStringConvertible {
        private let message: RFC_5322.Message
        private let universalUUID: String

        /// Creates an Apple Mail message from an Email
        ///
        /// Adds Apple-specific headers to a standard RFC 5322 message.
        ///
        /// - Parameters:
        ///   - email: The Email to convert
        ///   - universalUUID: Custom UUID for X-Universally-Unique-Identifier header
        /// - Throws: If email address parsing fails
        public init(
            from email: Email,
            universalUUID: String = UUID().uuidString
        ) throws {
            // Convert Email to RFC_5322.Message (from swift-email-type)
            let baseMessage = try RFC_5322.Message(from: email)

            // Add Apple-specific headers
            var headers = baseMessage.additionalHeaders
            headers["Mime-Version"] = "1.0 (Mac OS X Mail 16.0 \\(3826.700.71\\))"
            headers["X-Apple-Base-Url"] = "x-msg://1/"
            headers["X-Universally-Unique-Identifier"] = universalUUID
            headers["X-Apple-Mail-Remote-Attachments"] = "YES"
            headers["X-Apple-Windows-Friendly"] = "1"
            headers["X-Apple-Mail-Signature"] = ""
            headers["X-Uniform-Type-Identifier"] = "com.apple.mail-draft"

            // Create new message with Apple headers
            self.message = RFC_5322.Message(
                from: baseMessage.from,
                to: baseMessage.to,
                cc: baseMessage.cc,
                bcc: baseMessage.bcc,
                replyTo: baseMessage.replyTo,
                subject: baseMessage.subject,
                date: baseMessage.date,
                messageId: baseMessage.messageId,
                body: baseMessage.body,
                additionalHeaders: headers,
                mimeVersion: baseMessage.mimeVersion
            )

            self.universalUUID = universalUUID
        }

        /// Creates an Apple Mail message from an EmailDocument
        ///
        /// Convenience initializer for email-optimized HTML documents.
        ///
        /// - Parameters:
        ///   - emailDocument: The EmailDocument to render
        ///   - email: The Email metadata (to, from, subject, etc.)
        /// - Throws: If email address parsing or HTML rendering fails
        public init(
            emailDocument: any EmailDocument,
            from email: Email
        ) throws {
            // This assumes emailDocument renders to HTML
            // TODO: Create a new Email with the rendered HTML as body
            // For now, just use the email as-is and rely on it having HTML body
            _ = try String(emailDocument)  // Validate emailDocument renders
            try self.init(from: email)
        }

        public var description: String {
            message.render()
        }

        /// The underlying RFC 5322 message
        public var rfc5322Message: RFC_5322.Message {
            message
        }
    }
}
