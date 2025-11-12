# swift-email

Type-safe email composition with HTML DSL support for Swift.

`swift-email` integrates [swift-email-type](https://github.com/swift-standards/swift-email-type) with [swift-html](https://github.com/coenttb/swift-html), allowing you to compose emails using type-safe HTML builders instead of raw HTML strings.

## Features

- 📧 **Type-safe email composition** - Built on swift-email-type
- 🎨 **HTML DSL support** - Use swift-html's @HTMLBuilder for type-safe HTML
- 🔄 **Drop-in replacement** - Use wherever you used swift-email-type
- ✅ **Multipart emails** - Automatic text + HTML alternative handling
- 🎯 **RFC compliant** - Built on RFC 2045, 2046, and email standards
- 🚀 **Swift 6.0** - Full strict concurrency support

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

## Usage

### Basic HTML Email

```swift
import Email

let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Welcome!",
    html: {
        HTMLDocument {
            div {
                h1 { "Welcome to our service!" }
                p { "Thank you for signing up." }
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
                .fontFamily("system-ui, sans-serif")
                .padding(.rem(2))
                .maxWidth(.px(600))
                .margin(horizontal: .auto)
        } head: {
            title { "Welcome!" }
            meta(charset: .utf8)()
            meta(name: .viewport, content: "width=device-width, initial-scale=1")()
        }
    }
)
```

### Multipart Email (Text + HTML)

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Newsletter",
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
                .fontFamily("system-ui, sans-serif")
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

### Complete Email with Custom Styling

```swift
let email = try Email(
    to: [EmailAddress("user@example.com")],
    from: EmailAddress("noreply@company.com"),
    subject: "Verify your email",
    html: {
        HTMLDocument {
            body {
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
                        .fontWeight(.semibold)

                    p { "Thanks for signing up!" }
                        .marginTop(.rem(2))
                        .fontSize(.rem(0.875))
                        .color(.gray600)
                }
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .maxWidth(.px(600))
                    .margin(horizontal: .auto)
                    .padding(.rem(2))
            }
        } head: {
            title { "Verify Your Email" }
            meta(charset: .utf8)()
            meta(name: .viewport, content: "width=device-width, initial-scale=1")()
        }
    }
)
```

### Newsletter with Dynamic Content

```swift
struct Article {
    let title: String
    let summary: String
    let url: String
}

let articles: [Article] = [
    Article(title: "New Features", summary: "Check out our latest updates...", url: "https://example.com/blog/new"),
    Article(title: "Tips & Tricks", summary: "Learn how to...", url: "https://example.com/blog/tips")
]

let email = try Email(
    to: subscribers,
    from: EmailAddress("newsletter@example.com"),
    subject: "Monthly Newsletter",
    text: articles.map { "\($0.title)\n\($0.summary)\n\($0.url)" }
        .joined(separator: "\n\n"),
    html: {
        HTMLDocument {
            body {
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
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .maxWidth(.px(600))
                    .margin(horizontal: .auto)
                    .padding(.rem(2))
            }
        } head: {
            title { "Monthly Newsletter" }
            meta(charset: .utf8)()
            meta(name: .viewport, content: "width=device-width, initial-scale=1")()
        }
    }
)
```

### Email Body Builder

You can also create email bodies separately:

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
            .fontFamily("system-ui, sans-serif")
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

## API Overview

### Email Initializers

#### HTML Only
```swift
init(
    to: [EmailAddress],
    from: EmailAddress,
    replyTo: EmailAddress? = nil,
    cc: [EmailAddress]? = nil,
    bcc: [EmailAddress]? = nil,
    subject: String,
    @HTMLBuilder html: () -> any HTML,
    headers: [String: String] = [:]
) throws
```

#### Text + HTML (Multipart)
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
    headers: [String: String] = [:]
) throws
```

### Email.Body Builder

```swift
static func html(
    charset: String = "UTF-8",
    @HTMLBuilder content: () -> any HTML
) throws -> Email.Body
```

## Backward Compatibility

`swift-email` re-exports all types from `swift-email-type`, so it's a complete drop-in replacement. You can still use string-based HTML if needed:

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Test",
    html: "<h1>Hello</h1>"  // Traditional string-based HTML still works
)
```

## Related Packages

- [swift-email-type](https://github.com/swift-standards/swift-email-type) - Core email types and RFC implementations
- [swift-html](https://github.com/coenttb/swift-html) - Type-safe HTML DSL
- [swift-mailgun](https://github.com/coenttb/swift-mailgun) - Send emails via Mailgun API

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, tvOS 17+, watchOS 10+

## License

Apache License 2.0 with Runtime Library Exception

See [LICENSE](LICENSE) for details.

## Author

Coen ten Thije Boonkkamp
https://github.com/coenttb/swift-email

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
