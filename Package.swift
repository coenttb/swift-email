// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "swift-email",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Email",
            targets: ["Email"]
        )
    ],
    traits: [
        .trait(
            name: "Translating",
            description: "Include TranslatedString integration for internationalization support"
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-email-type", from: "0.2.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-5322", from: "0.1.0"),
        .package(url: "https://github.com/coenttb/swift-html", exact: "0.11.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.2"),
        .package(url: "https://github.com/swiftlang/swift-markdown", from: "0.4.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.2"),
        .package(url: "https://github.com/coenttb/swift-builders", from: "0.0.1"),
        .package(url: "https://github.com/coenttb/swift-translating", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "Email",
            dependencies: [
                .product(name: "Email Type", package: "swift-email-type"),
                .product(name: "RFC_5322", package: "swift-rfc-5322"),
                .product(name: "HTML", package: "swift-html"),
                .product(name: "HTMLTheme", package: "swift-html"),
                .product(name: "HTMLComponents", package: "swift-html"),
                .product(name: "HTMLMarkdown", package: "swift-html"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "StringBuilder", package: "swift-builders"),
                .product(
                    name: "Translating",
                    package: "swift-translating",
                    condition: .when(traits: ["Translating"])
                )
            ],
            swiftSettings: [
                .define("TRANSLATING", .when(traits: ["Translating"]))
            ]
        ),
        .testTarget(
            name: "Email Tests",
            dependencies: ["Email"]
        )
    ],
    swiftLanguageModes: [.v6]
)
