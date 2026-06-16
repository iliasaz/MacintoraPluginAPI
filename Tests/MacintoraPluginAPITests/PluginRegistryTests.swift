import XCTest
import Foundation
@testable import MacintoraPluginAPI

private struct DummyWalletProvider: WalletTLSProvider {
    static let pluginID = "test.dummy.wallet"
    static let displayName = "Dummy Wallet"
    let material: WalletTLSMaterial?
    func canHandle(walletFolderAt folder: URL) -> Bool { material != nil }
    func walletMaterial(forWalletAt folder: URL) throws -> WalletTLSMaterial? { material }
}

private struct OtherPlugin: MacintoraPlugin {
    static let pluginID = "test.other"
    static let displayName = "Other"
}

final class PluginRegistryTests: XCTestCase {

    func test_registerAndQueryByCapability() throws {
        let reg = PluginRegistry()
        reg.register(DummyWalletProvider(material: WalletTLSMaterial(pkcs12DER: Data([0x30, 0x82]),
                                                                     passphrase: [1, 2, 3])))
        reg.register(OtherPlugin())

        let providers = reg.plugins(WalletTLSProvider.self)
        XCTAssertEqual(providers.count, 1)
        XCTAssertEqual(reg.all.count, 2)

        let provider = try XCTUnwrap(providers.first)
        let material = try provider.walletMaterial(forWalletAt: URL(filePath: "/tmp"))
        XCTAssertEqual(material?.passphrase, [1, 2, 3])
    }

    func test_registrationIsIdempotentByID() {
        let reg = PluginRegistry()
        reg.register(DummyWalletProvider(material: nil))
        reg.register(DummyWalletProvider(material: nil))
        XCTAssertEqual(reg.all.count, 1)
    }

    func test_emptyRegistryReturnsNoProviders() {
        XCTAssertTrue(PluginRegistry().plugins(WalletTLSProvider.self).isEmpty)
    }

    func test_canHandleCapabilityQuery() {
        let reg = PluginRegistry()
        reg.register(DummyWalletProvider(material: WalletTLSMaterial(pkcs12DER: Data([0x30]), passphrase: [1])))
        let providers = reg.plugins(WalletTLSProvider.self)
        XCTAssertTrue(providers.contains { $0.canHandle(walletFolderAt: URL(filePath: "/any")) })
        let none = PluginRegistry().plugins(WalletTLSProvider.self)
        XCTAssertFalse(none.contains { $0.canHandle(walletFolderAt: URL(filePath: "/any")) })
    }

    func test_instanceConveniences() {
        let p = OtherPlugin()
        XCTAssertEqual(p.pluginID, "test.other")
        XCTAssertEqual(p.displayName, "Other")
    }
}
