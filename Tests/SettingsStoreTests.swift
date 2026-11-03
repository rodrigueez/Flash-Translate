import XCTest
@testable import FlashTranslate

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testSaveAndReloadSettings() {
        let suiteName = "SettingsStoreTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        var updated = AppSettings()
        updated.provider = .openAICompatible
        updated.baseURL = "https://example.com/v1"
        updated.apiKey = "secret"
        updated.model = "gpt-test"
        updated.reasoningEffort = .high
        updated.deepLAPIKey = "deepl-secret"
        updated.deepLPlan = .pro
        store.save(updated)

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.settings, updated)
    }

    func testReloadLegacySettingsPreservesConfiguration() throws {
        let suiteName = "SettingsStoreTests.legacy"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let legacy = Data("""
        {"provider":"openAICompatible","baseURL":"https://example.com/v1",
         "apiKey":"existing-key","model":"existing-model",
         "hotkey":{"keyCode":17,"modifiers":262144},
         "enableCtrlSpace":false,"enableDoubleCommand":true}
        """.utf8)
        defaults.set(legacy, forKey: "flash_translate_settings")

        let settings = SettingsStore(defaults: defaults).settings
        XCTAssertEqual(settings.provider, .openAICompatible)
        XCTAssertEqual(settings.baseURL, "https://example.com/v1")
        XCTAssertEqual(settings.apiKey, "existing-key")
        XCTAssertEqual(settings.model, "existing-model")
        XCTAssertEqual(settings.hotkey.keyCode, 17)
        XCTAssertEqual(settings.hotkey.modifiers, .control)
        XCTAssertFalse(settings.enableCtrlSpace)
        XCTAssertTrue(settings.enableDoubleCommand)
        XCTAssertNil(settings.reasoningEffort)
        XCTAssertEqual(settings.deepLAPIKey, "")
        XCTAssertEqual(settings.deepLPlan, .free)
    }

    func testDeepLSettingsRoundTrip() throws {
        var settings = AppSettings()
        settings.provider = .deepL
        settings.deepLAPIKey = "deepl-secret"
        settings.deepLPlan = .pro
        let data = try JSONEncoder().encode(settings)
        XCTAssertEqual(try JSONDecoder().decode(AppSettings.self, from: data), settings)
    }
}
