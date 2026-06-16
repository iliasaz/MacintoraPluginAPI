//
//  PluginComposition.swift
//  Macintora  (app target — PUBLIC version)
//
//  The "composition root": the single place that decides which plugins this
//  build ships. Call `PluginComposition.registerAll()` once at launch (e.g. in
//  your App's `init()` or `applicationDidFinishLaunching`).
//
//  This PUBLIC version registers only public/built-in plugins (none yet). The
//  Pro/private build replaces THIS FILE (in the private mirror) with a version
//  that also registers private plugins — see Macintora-wiring.md. Keeping the
//  difference to one small file means the private branch rebases cleanly onto
//  upstream and the public repo never names a private plugin.
//

import MacintoraPluginAPI

enum PluginComposition {
    /// Registers every plugin compiled into this build.
    static func registerAll() {
        // Public / built-in plugins go here, e.g.:
        // PluginRegistry.shared.register(SomePublicPlugin())
    }
}
