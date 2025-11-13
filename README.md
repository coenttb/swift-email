# swift-email

[![CI](https://github.com/coenttb/swift-email/workflows/CI/badge.svg)](https://github.com/coenttb/swift-email/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Type-safe email composition with HTML DSL support for Swift.

## Overview

`swift-email` integrates [swift-email-type](https://github.com/swift-standards/swift-email-type) with [swift-html](https://github.com/coenttb/swift-html), enabling type-safe HTML email composition using a result builder DSL instead of raw HTML strings. The package provides full multipart/alternative email support with automatic content encoding and RFC compliance.

## Features

- Type-safe email composition built on swift-email-type
- HTML DSL support via swift-html's @HTMLBuilder for compile-time validation
- Multipart/alternative emails with automatic text and HTML alternative handling
- RFC 2045, 2046, and 5322 compliance for email standards
- Full Swift 6.0 strict concurrency support
- Drop-in replacement for swift-email-type with backward compatibility

## Installation

Add `swift-email` to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-email", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Email", package: "swift-email")
    ]
)
```

## Quick Start

### Simple HTML Email

```swift
import Email

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
```

### Welcome Email with Styled Button

```swift
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
```

### Multipart Email (Text + HTML)

When you provide both `text:` and `html:` parameters, the email automatically becomes multipart/alternative. Email clients that support HTML will display the HTML version, while clients that only support plain text will display the text version.

```swift
let email = try Email(
    to: [EmailAddress("subscriber@example.com")],
    from: EmailAddress("newsletter@example.com"),
    subject: "Monthly Newsletter",
    text: "Welcome! Visit https://example.com for more info.",  // Plain text fallback
    html: {  // Rich HTML version
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
```

## Usage Examples

### Newsletter with Dynamic Content

Create newsletters with dynamic content using HTMLForEach:

```swift
struct Article: HTML {
    let title: String
    let summary: String
    let url: String

    var body: some HTML {
        div {
            h2 { title }
                .fontSize(.rem(1.5))
                .marginBottom(.rem(0.5))

            p { summary }
                .marginBottom(.rem(1))
                .color(.gray700)

            a(href: .init(rawValue: url)) { "Read more →" }
                .color(.blue)
                .textDecoration(TextDecoration.none)
        }
        .padding(bottom: .rem(1.5))
        .marginBottom(.rem(1.5))
        .borderBottom(width: .px(1), color: .gray200)
    }
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
    )
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

                HTMLForEach(articles)

                p { "Thanks for being a subscriber!" }
                    .marginTop(.rem(2))
                    .fontSize(.rem(0.875))
                    .color(.gray600)
            }
            .fontFamily(.withFallback(["system-ui", "-apple-system"], fallback: .sansSerif))
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
```

### Email with All Optional Fields

```swift
let email = try Email(
    to: [
        EmailAddress("user1@example.com"),
        EmailAddress("user2@example.com")
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
        .init(name: "X-Mailer", value: "swift-email")
    ]
)
```

### Creating Email Bodies Separately

Create email bodies independently and compose them later:

```swift
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
```

### Custom Character Encoding

Specify custom character encodings when needed:

```swift
let body = Email.Body.html(charset: "ISO-8859-1") {
    HTMLDocument {
        p { "Content with custom charset" }
    } head: {
        title { "Custom Encoding" }
        meta(charset: .utf8)()
    }
}
```

## API Overview

### Email Initializers

#### HTML Only Email

```swift
init(
    to: [EmailAddress],
    from: EmailAddress,
    replyTo: EmailAddress? = nil,
    cc: [EmailAddress]? = nil,
    bcc: [EmailAddress]? = nil,
    subject: String,
    @HTMLBuilder html: () -> any HTML,
    additionalHeaders: [RFC_5322.Header] = []
) throws
```

#### Multipart Email (Text + HTML)

```swift
init(
    to: [EmailAddress],
    from: EmailAddress,
    replyTo: EmailAddress? = nil,
    cc: [EmailAddress]? = nil,
    bcc: [EmailAddress]? = nil,
    subject: String,
    text: String,
    @HTMLBuilder html: () -> any HTML,
    additionalHeaders: [RFC_5322.Header] = []
) throws
```

### Email.Body Builder

```swift
static func html(
    charset: RFC_2045.Charset = .utf8,
    @HTMLBuilder content: () -> any HTML
) -> Email.Body
```

## Backward Compatibility

`swift-email` re-exports all types from `swift-email-type`, making it a complete drop-in replacement. Traditional string-based HTML still works:

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Test",
    html: "<h1>Hello</h1>"  // String-based HTML still supported
)
```

## Related Packages

- [swift-email-type](https://github.com/swift-standards/swift-email-type) - Core email types and RFC 2045/2046 implementations for MIME encoding
- [swift-html](https://github.com/coenttb/swift-html) - Type-safe HTML DSL for Swift with compile-time validation
- [swift-mailgun](https://github.com/coenttb/swift-mailgun) - Mailgun API integration for Swift applications

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## License

Apache License 2.0 with Runtime Library Exception

See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Coen ten Thije Boonkkamp
https://github.com/coenttb/swift-email
