//
//  WalletTLSMaterial+NIOSSL.swift
//  Macintora  (app target — PUBLIC, safe to commit)
//
//  Turns transport-agnostic plugin material into a NIOSSL TLSConfiguration.
//  This is the only place NIOSSL meets the plugin API; plugins themselves stay
//  TLS-library-free. Copy this file into the Macintora app target.
//

import Foundation
import NIOSSL
import MacintoraPluginAPI

extension WalletTLSMaterial {
    /// Builds a client mutual-TLS configuration from the wallet's PKCS#12 bytes.
    func makeTLSConfiguration() throws -> TLSConfiguration {
        let bundle = try NIOSSLPKCS12Bundle(buffer: [UInt8](pkcs12DER), passphrase: passphrase)
        var tls = TLSConfiguration.makeClientConfiguration()
        tls.certificateChain = bundle.certificateChain.map { .certificate($0) }
        tls.privateKey = .privateKey(bundle.privateKey)
        return tls
    }
}
