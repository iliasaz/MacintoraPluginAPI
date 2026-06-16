// swift-tools-version: 6.0
import PackageDescription

// MacintoraPluginAPI — the public, dependency-light plugin interface for
// Macintora. Both the app and any plugin (public or private) depend on this
// package and nothing heavier, so plugins are cheap to build and stay decoupled
// from the app's TLS / driver internals.
//
// Intended to live in its own PUBLIC repo (branch `macintora`, consumed via a
// Package.resolved pin), matching Macintora's other SPM dependencies.

let package = Package(
    name: "MacintoraPluginAPI",
    platforms: [.macOS(.v15)], // `Mutex` (Synchronization) requires macOS 15+
    products: [
        .library(name: "MacintoraPluginAPI", targets: ["MacintoraPluginAPI"]),
    ],
    targets: [
        .target(name: "MacintoraPluginAPI"),
        .testTarget(name: "MacintoraPluginAPITests", dependencies: ["MacintoraPluginAPI"]),
    ]
)
