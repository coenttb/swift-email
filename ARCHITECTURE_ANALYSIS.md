# Email Ecosystem Architecture Analysis

## Current Package Ecosystem

### swift-standards (RFC implementations)

**swift-rfc-2045** - MIME Part One: Format of Internet Message Bodies
- `ContentType` - media type parsing/formatting
- `ContentTransferEncoding` - encoding mechanisms
- Purpose: Core MIME type system

**swift-rfc-2046** - MIME Part Two: Media Types
- `Multipart` - multipart message structure
- `BodyPart` - individual MIME body parts
- `Multipart.alternative()` - text + HTML alternatives
- Purpose: MIME multipart structure

**swift-rfc-5321** - Simple Mail Transfer Protocol
- `RFC_5321.EmailAddress` - SMTP-compliant addresses (stricter, no display names)
- Purpose: SMTP protocol addresses

**swift-rfc-5322** - Internet Message Format ⚠️ INCOMPLETE
- `RFC_5322.EmailAddress` - message format addresses (allows display names)
- `RFC_5322.Date` - RFC 5322 date formatting
- **MISSING**: Message structure, header fields, .eml generation
- Purpose: Email message format specification

### swift-standards (High-level types)

**swift-emailaddress-type**
- Unified `EmailAddress` type
- Can convert between RFC 5321, RFC 5322, RFC 6531 formats
- Purpose: Polymorphic email address abstraction

**swift-email-type**
- `Email` struct with to/from/subject/body/headers
- Uses RFC 2045/2046 for MIME bodies
- Does NOT generate .eml files (just a data structure)
- Re-exports: EmailAddress, RFC_2045, RFC_2046
- Purpose: Type-safe email message representation

### coenttb (Application level)

**swift-email** (current project)
- Integrates swift-email-type with swift-html
- Provides `@HTMLBuilder` DSL for generating HTML emails
- Contains `AppleEmailFormat.swift` - generates .eml files with Apple-specific headers
- Purpose: Developer-friendly email composition with HTML DSL

## The Question: Where Should .eml Generation Live?

### What RFC 5322 Actually Specifies

RFC 5322 "Internet Message Format" defines:
- Section 2.1: General Description (message structure: headers + body)
- Section 2.2: Header Fields and Their Components
- Section 3.3: Date and Time Specification (already implemented ✓)
- Section 3.4: Address Specification (already implemented ✓)
- Section 3.6: Field Definitions
  - 3.6.1: The Origination Date Field (Date:)
  - 3.6.2: Originator Fields (From:, Sender:, Reply-To:)
  - 3.6.3: Destination Address Fields (To:, Cc:, Bcc:)
  - 3.6.4: Identification Fields (Message-ID:, In-Reply-To:, References:)
  - 3.6.5: Informational Fields (Subject:, Comments:, Keywords:)
- **The complete .eml file format**

### Current State Analysis

**AppleEmailFormat.swift** currently does:
1. Creates RFC 5322 message structure (headers + MIME body)
2. Generates standard RFC 5322 headers (From, Subject, Date, Message-Id, Mime-Version)
3. Uses RFC 2046 multipart/alternative structure
4. **Adds Apple-specific custom headers** (X-Apple-*, X-Uniform-Type-Identifier)
5. Uses inline DateFormatter (should use RFC_5322.Date)

**What's architecturally incorrect:**
- swift-rfc-5322 is incomplete - doesn't implement message format
- swift-email is implementing RFC 5322 message generation (should be in swift-rfc-5322)
- AppleEmailFormat duplicates date formatting (should use RFC_5322.Date)

## Recommended Architecture

### Option A: Complete RFC 5322 Implementation (CORRECT)

**swift-rfc-5322** should add:
```swift
extension RFC_5322 {
    /// RFC 5322 Internet Message Format
    struct Message {
        let headers: [String: String]  // All RFC 5322 headers
        let body: String               // MIME body (from RFC 2045/2046)

        /// Generate RFC 5322 .eml format
        func render() -> String

        /// Create from swift-email-type's Email
        init(from email: Email) throws
    }

    /// Standard RFC 5322 headers
    struct Headers {
        let from: EmailAddress
        let to: [EmailAddress]
        let subject: String
        let date: Date
        let messageId: String
        // ... other standard headers
    }
}
```

**swift-email** would then:
```swift
// Generate standard RFC 5322 .eml
let message = RFC_5322.Message(from: email)
let emlContent = message.render()

// Generate Apple Mail .eml with custom headers
let appleMessage = AppleEmail(from: email)
let applEmlContent = appleMessage.render()  // Adds X-Apple-* headers
```

### Why This Is Correct

1. **RFC 5322 is the message format specification** - it should generate messages
2. **Separation of concerns**:
   - RFC packages: Standards implementation
   - swift-email-type: Data structure
   - swift-email: Developer experience (HTML DSL) + platform-specific extensions (Apple)
3. **Reusability**: Other packages can generate .eml files without depending on swift-html
4. **Standards compliance**: Implementation lives with specification

### Implementation Plan

1. **swift-rfc-5322**: Add `RFC_5322.Message` with:
   - Header field generation (From:, To:, Subject:, Date:, Message-ID:, etc.)
   - Message structure (headers + body)
   - `.render()` method to generate .eml format
   - `init(from: Email)` to convert from swift-email-type

2. **swift-email**: Update `AppleEmailFormat` to:
   - Use `RFC_5322.Message` as base
   - Use `RFC_5322.Date.formatter` instead of inline DateFormatter
   - Add only Apple-specific headers on top
   - Keep convenience init with `EmailDocument`

3. **swift-email-type**: No changes needed
   - Remains a pure data structure
   - Consumers convert to RFC_5322.Message for serialization

## Conclusion

**Yes, RFC 5322 should have .eml file generation** - this is what RFC 5322 specifies.

The current architecture has:
- ✓ RFC 2045/2046 correctly implement MIME types
- ✓ swift-email-type correctly provides Email data structure
- ✗ RFC 5322 is incomplete (missing message format)
- ✗ swift-email implementing RFC functionality (should extend, not replace)

**Next Steps:**
1. Extend swift-rfc-5322 with Message type
2. Update AppleEmailFormat to use RFC_5322.Message + RFC_5322.Date
3. Keep Apple-specific customizations in swift-email
