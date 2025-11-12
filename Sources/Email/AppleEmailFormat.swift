//
//  AppleEmailFormat.swift
//  coenttb-html
//
//  Created by Coen ten Thije Boonkkamp on 21/07/2025.
//

import Foundation
import RFC_2046
import RFC_5322

public struct AppleEmail: CustomStringConvertible {
    private let message: RFC_5322.Message
    private let universalUUID: String

    public init(
        htmlContent: String,
        from: String,
        subject: String = "",
        date: Date = Date(),
        boundary: String? = nil,
        messageId: String? = nil,
        universal: String = UUID().uuidString
    ) throws {
        let plainTextContent = try! String(htmlContent, stripHTML: true)

        // Create multipart body using RFC 2046
        let multipart = try RFC_2046.Multipart(
            subtype: .alternative,
            parts: [
                .init(
                    contentType: .textPlainUTF8,
                    transferEncoding: .sevenBit,
                    text: plainTextContent
                ),
                .init(
                    contentType: .textHTMLUTF8,
                    transferEncoding: .sevenBit,
                    text: htmlContent
                )
            ],
            boundary: boundary.map { "Apple-Mail=_\($0)" }
        )

        // Parse RFC 5322 email address
        let fromAddress = try RFC_5322.EmailAddress(from)

        // Generate or use provided message ID
        let finalMessageId = messageId ?? RFC_5322.Message.generateMessageId(from: fromAddress)

        // Create RFC 5322 message with Apple-specific headers
        self.message = RFC_5322.Message(
            from: fromAddress,
            to: [], // Apple Mail drafts don't require recipients
            subject: subject,
            date: date,
            messageId: finalMessageId,
            body: multipart.render(),
            additionalHeaders: [
                "Content-Type": multipart.contentType.headerValue,
                "Mime-Version": "1.0 (Mac OS X Mail 16.0 \\(3826.700.71\\))",
                "X-Apple-Base-Url": "x-msg://1/",
                "X-Universally-Unique-Identifier": universal,
                "X-Apple-Mail-Remote-Attachments": "YES",
                "X-Apple-Windows-Friendly": "1",
                "X-Apple-Mail-Signature": "",
                "X-Uniform-Type-Identifier": "com.apple.mail-draft"
            ]
        )

        self.universalUUID = universal
    }

    public init(
        emailDocument: any EmailDocument,
        from: String,
        subject: String = "",
        date: Date = Date()
    ) throws {
        let htmlContent = try! String(emailDocument)
        try self.init(
            htmlContent: htmlContent,
            from: from,
            subject: subject,
            date: date
        )
    }

    public var description: String {
        message.render()
    }

    /// The underlying RFC 5322 message
    public var rfc5322Message: RFC_5322.Message {
        message
    }
}
