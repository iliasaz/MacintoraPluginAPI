//
//  WalletTLSProvider.swift
//  MacintoraPluginAPI
//
//  Capability: supply mutual-TLS client material for a wallet folder. This is
//  the seam that lets a plugin add support for wallet sources the open core
//  doesn't handle natively (custom key stores, HSM-backed identities,
//  alternative container formats).
//
//  Material is passed as RAW BYTES (PKCS#12 + passphrase), so this package never
//  depends on a TLS library and a plugin never has to. The host app turns the
//  material into its own TLS configuration (e.g. NIOSSL `NIOSSLPKCS12Bundle`).
//

import Foundation

/// mTLS client material extracted from a wallet, as transport-agnostic bytes.
public struct WalletTLSMaterial: Sendable, Hashable {
    /// DER-encoded PKCS#12 archive (certificate chain + private key).
    public let pkcs12DER: Data

    /// Passphrase for `pkcs12DER`, as raw bytes (may be non-UTF-8 / contain
    /// control bytes).
    public let passphrase: [UInt8]

    public init(pkcs12DER: Data, passphrase: [UInt8]) {
        self.pkcs12DER = pkcs12DER
        self.passphrase = passphrase
    }
}

/// A plugin that can produce mTLS material for a wallet folder.
///
/// The host app consults registered providers before its built-in wallet path:
/// the first provider to return non-`nil` wins; returning `nil` means "not my
/// wallet, fall back to the default."
public protocol WalletTLSProvider: MacintoraPlugin {
    /// Fast, side-effect-free check: does this provider handle the wallet at
    /// `folder`? Used by the UI to decide an authentication mode (e.g. whether a
    /// password is needed) without doing the full, potentially expensive load.
    /// Should be cheap — typically a file-existence check.
    func canHandle(walletFolderAt folder: URL) -> Bool

    /// Returns mTLS material for the wallet at `folder`, or `nil` if this
    /// provider doesn't handle that wallet.
    ///
    /// - Throws: only when the provider *recognises* the wallet but fails to
    ///   read it (a genuine error worth surfacing). Use `nil`, not a throw, to
    ///   say "not applicable."
    func walletMaterial(forWalletAt folder: URL) throws -> WalletTLSMaterial?
}

public extension WalletTLSProvider {
    /// Default capability check: probe by attempting a load. This keeps adding
    /// `canHandle` a non-breaking API change for existing conformers. Providers
    /// SHOULD override it with a cheaper check (e.g. file existence), since it
    /// runs in UI paths where a full load would be wasteful.
    func canHandle(walletFolderAt folder: URL) -> Bool {
        (try? walletMaterial(forWalletAt: folder)) != nil
    }
}
