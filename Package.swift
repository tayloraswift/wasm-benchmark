// swift-tools-version:6.2
import CompilerPluginSupport
import PackageDescription
import typealias Foundation.ProcessInfo

let package: Package = .init(
    name: "majesty",
    products: [
        .executable(name: "application", targets: ["Application"]),
    ],
    traits: [
        "Headless",
        "WebAssembly",
        .default(enabledTraits: ["WebAssembly"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", exact: "0.41.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.1"),
        .package(url: "https://github.com/tayloraswift/swift-json", from: "2.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "Application",
            dependencies: [
                .target(name: "GameEconomy"),
                .target(name: "JavaScript"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
        ),

        .target(
            name: "GameEconomy",
            dependencies: [
                .target(name: "Identifiers"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),

        .target(
            name: "Identifiers",
            dependencies: [
            ]
        ),


        .target(
            name: "JavaScript",
            dependencies: [
                .target(name: "JavaScriptBackend"),
            ]
        ),
        .target(
            name: "JavaScriptBackend",
            dependencies: [
                .product(
                    name: "JavaScriptPersistence",
                    package: "swift-json",
                    condition: .when(traits: ["Headless"]),
                ),
                .product(
                    name: "JavaScriptBigIntSupport",
                    package: "JavaScriptKit",
                    condition: .when(traits: ["WebAssembly"]),
                ),
                .product(
                    name: "JavaScriptKit",
                    package: "JavaScriptKit",
                    condition: .when(traits: ["WebAssembly"]),
                ),
            ]
        ),
    ]
)

for target: Target in package.targets {
    if case .plugin = target.type {
        continue
    }

    let swift: [SwiftSetting]
    let c: [CSetting]

    switch ProcessInfo.processInfo.environment["SWIFT_NOASSERT"] {
    case "1"?, "true"?:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
        ]

    case "0"?, "false"?, nil:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
            .define("TESTABLE"),
        ]

    case let value?:
        fatalError("Unexpected 'SWIFT_NOASSERT' value: \(value)")
    }

    switch ProcessInfo.processInfo.environment["SWIFT_WASM_SIMD128"] {
    case "1"?, "true"?:
        c = [
            .unsafeFlags(["-msimd128"])
        ]

    case "0"?, "false"?, nil:
        c = [
        ]

    case let value?:
        fatalError("Unexpected 'SWIFT_WASM_SIMD128' value: \(value)")
    }

    {
        $0 = ($0 ?? []) + swift
    } (&target.swiftSettings)

    if case .macro = target.type {
        // Macros are not compiled with C settings.
        continue
    }

    {
        $0 = ($0 ?? []) + c
    } (&target.cSettings)
}
