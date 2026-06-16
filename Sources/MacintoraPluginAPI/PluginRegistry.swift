//
//  PluginRegistry.swift
//  MacintoraPluginAPI
//
//  A concurrency-safe, actor-agnostic registry of plugins. Register at app
//  launch; query from anywhere (including off the main actor, e.g. the
//  connection-building path). Backed by `Mutex` so it needs no actor isolation.
//

import Synchronization

/// Holds the plugins compiled into the current build and lets the app query them
/// by capability.
public final class PluginRegistry: Sendable {

    /// Shared registry used by the app. Plugins are registered into this at
    /// launch by the build's composition root.
    public static let shared = PluginRegistry()

    private let storage = Mutex<[any MacintoraPlugin]>([])

    public init() {}

    /// Registers a plugin instance. Idempotent: a second registration with the
    /// same ``MacintoraPlugin/pluginID`` is ignored.
    public func register(_ plugin: any MacintoraPlugin) {
        storage.withLock { list in
            let id = type(of: plugin).pluginID
            guard !list.contains(where: { type(of: $0).pluginID == id }) else { return }
            list.append(plugin)
        }
    }

    /// All registered plugins that conform to the given capability protocol.
    ///
    /// ```swift
    /// let providers = PluginRegistry.shared.plugins(WalletTLSProvider.self)
    /// ```
    public func plugins<P>(_ type: P.Type = P.self) -> [P] {
        storage.withLock { $0.compactMap { $0 as? P } }
    }

    /// Every registered plugin, regardless of capability.
    public var all: [any MacintoraPlugin] {
        storage.withLock { $0 }
    }
}
