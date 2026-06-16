# Wiring MacintoraPluginAPI into Macintora

This adds a behavior-neutral plugin seam to the app: with no plugins registered,
the app behaves exactly as before. A build that registers plugins lights up the
extra behavior they provide.

## A. Add the API package (one-time)

1. In Xcode: *Macintora project → Package Dependencies → +* → add
   `https://github.com/iliasaz/MacintoraPluginAPI`, branch `macintora`
   (matches the other dependencies).
2. Add the `MacintoraPluginAPI` library to the **Macintora app target**.
   Commit the updated `Package.resolved`.

## B. App-side files

Copy both into the app target:

- `WalletTLSMaterial+NIOSSL.swift` — converts plugin material → `TLSConfiguration`
  (the only spot NIOSSL meets the plugin API).
- `PluginComposition.swift` — the composition root (registers plugins).

Call the composition root once at launch, e.g. in your `@main` App:

```swift
init() {
    PluginComposition.registerAll()
}
```

## C. `OracleEndpoint` change

Add `import MacintoraPluginAPI`, then give plugins first crack at the `.wallet`
case before the default path. Replace the current `.wallet` case in
`makeConfiguration(...)`:

```swift
case .wallet(let folderPath):
    let folder = URL(filePath: folderPath)

    // 1. Let a plugin handle it first (returns nil to defer to the default).
    if let material = Self.pluginWalletMaterial(forWalletAt: folder) {
        do {
            config.tls = try .require(.init(configuration: material.makeTLSConfiguration()))
            break
        } catch {
            throw ResolveError.walletConfigurationFailed(error.localizedDescription)
        }
    }

    // 2. Default: the app's built-in wallet path (unchanged behavior).
    let effectivePassword = walletPassword ?? ""
    do {
        let tls = try TLSConfiguration.makeOracleWalletConfiguration(
            wallet: folderPath,
            walletPassword: effectivePassword
        )
        config.tls = try .require(.init(configuration: tls))
    } catch {
        if effectivePassword.isEmpty, walletKeyIsEncrypted(folderPath: folderPath) {
            throw ResolveError.walletConfigurationFailed(
                "the wallet's private key is encrypted, so a wallet password is required"
            )
        }
        throw ResolveError.walletConfigurationFailed(error.localizedDescription)
    }
```

Add the helper to `OracleEndpoint`:

```swift
/// First registered ``WalletTLSProvider`` that handles `folder`, if any.
/// A provider returning nil means "not my wallet"; a thrown error means it
/// recognised the wallet but failed — we fall back to the default path.
private static func pluginWalletMaterial(forWalletAt folder: URL) -> WalletTLSMaterial? {
    for provider in PluginRegistry.shared.plugins(WalletTLSProvider.self) {
        if let material = try? provider.walletMaterial(forWalletAt: folder) {
            return material
        }
    }
    return nil
}
```

`PluginRegistry` is `Mutex`-backed, so this is safe to call from
`makeConfiguration`'s off-main connection path.

## D. Registering plugins per build

The **composition root** (`PluginComposition.registerAll()`) is the one place a
build decides which plugins it ships:

```swift
import MacintoraPluginAPI
// import YourPluginModule   // only in the build that ships it

enum PluginComposition {
    static func registerAll() {
        // Public/built-in plugins here.
        // A private or paid build additionally registers its own, e.g.:
        // PluginRegistry.shared.register(MyPrivateProvider())
    }
}
```

For an open-core layout, keep this seam (A–C) public and put each closed plugin
in its own package. The difference between a free build and a richer build then
collapses to: one extra package dependency + the one extra `register(...)` line
in this file — small enough to live on a thin branch of a private mirror that
rebases cleanly onto the public `main`.
