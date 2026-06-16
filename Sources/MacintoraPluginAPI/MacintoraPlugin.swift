//
//  MacintoraPlugin.swift
//  MacintoraPluginAPI
//
//  The base protocol every Macintora plugin conforms to. A plugin adds one or
//  more capabilities by *also* conforming to capability protocols (e.g.
//  ``WalletTLSProvider``). Plugins are `Sendable` — typically small, stateless
//  values or singletons — and are registered with the ``PluginRegistry`` at app
//  launch (the "composition root").
//

import Foundation

/// A unit of optional functionality that can be compiled into a Macintora build.
///
/// Conform to this plus one or more capability protocols, then register an
/// instance:
/// ```swift
/// struct MyPlugin: SomeCapability {
///     static let pluginID = "com.example.macintora.my-plugin"
///     static let displayName = "My Plugin"
///     // capability requirements…
/// }
/// PluginRegistry.shared.register(MyPlugin())
/// ```
public protocol MacintoraPlugin: Sendable {
    /// Stable, globally-unique identifier. Reverse-DNS is recommended
    /// (e.g. `"com.example.macintora.my-plugin"`).
    static var pluginID: String { get }

    /// Human-readable name for UI and diagnostics.
    static var displayName: String { get }
}

public extension MacintoraPlugin {
    /// Instance access to ``pluginID`` for convenience in UI/logging.
    var pluginID: String { Self.pluginID }
    /// Instance access to ``displayName`` for convenience in UI/logging.
    var displayName: String { Self.displayName }
}
