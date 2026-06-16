# MacintoraPluginAPI

The **public** plugin interface for [Macintora](https://github.com/iliasaz/Macintora).
Both the app and any plugin — public or private — depend on this small,
dependency-light package and nothing heavier, so plugins stay decoupled from the
app's TLS/driver internals.

> Consumed like Macintora's other SPM dependencies: its own repo, branch
> `macintora`, pinned in `Package.resolved`.

## Concepts

- **`MacintoraPlugin`** — base protocol (`pluginID`, `displayName`), `Sendable`.
- **Capability protocols** — what a plugin actually *does*. A plugin conforms to
  the base plus one or more capabilities.
  - **`WalletTLSProvider`** — supplies mutual-TLS material (`WalletTLSMaterial`:
    raw PKCS#12 bytes + passphrase) for a wallet folder. Lets a plugin add
    support for wallet sources the core app doesn't handle natively (custom
    key stores, HSM-backed identities, alternative container formats) without
    this package or the plugin depending on a TLS library — the host app
    converts the bytes to its own TLS config.
- **`PluginRegistry`** — concurrency-safe (`Mutex`-backed) registry. Register at
  launch; query by capability from any actor.

## Writing a plugin

```swift
import MacintoraPluginAPI

public struct MyWalletProvider: WalletTLSProvider {
    public static let pluginID = "com.example.macintora.my-wallet"
    public static let displayName = "My Wallet"
    public init() {}
    public func walletMaterial(forWalletAt folder: URL) throws -> WalletTLSMaterial? {
        // return material, or nil to defer to the app's default path
    }
}
```

## Registering (composition root)

A build decides which plugins it ships by registering them at launch:

```swift
import MacintoraPluginAPI

func registerPlugins() {
    // free build: public plugins only (or none)
    // pro/private build also adds, e.g.:
    // PluginRegistry.shared.register(MyPrivateProvider())
}
```

## Host-app integration

See `integration/Macintora-wiring.md` for the exact `OracleEndpoint` changes and
the `WalletTLSMaterial → NIOSSL TLSConfiguration` adapter the app provides.

## Compile-time, by design

Macintora is signed + notarized with hardened runtime, so plugins are linked at
build time (no runtime `.dylib`/`.bundle` loading). The free build links public
plugins; the Pro build links public + private. The interface here is the public
contract both sides agree on.
