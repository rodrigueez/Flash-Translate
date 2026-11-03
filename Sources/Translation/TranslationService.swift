import Foundation

final class TranslationService {
    private let settingsStore: SettingsStore
    private let languageDirectionResolver: LanguageDirectionResolver
    private let googleService: GoogleTranslateService
    private let openAIService: OpenAICompatibleTranslateService
    private let deepLService: DeepLTranslateService

    init(
        settingsStore: SettingsStore,
        languageDirectionResolver: LanguageDirectionResolver,
        googleService: GoogleTranslateService,
        openAIService: OpenAICompatibleTranslateService,
        deepLService: DeepLTranslateService
    ) {
        self.settingsStore = settingsStore
        self.languageDirectionResolver = languageDirectionResolver
        self.googleService = googleService
        self.openAIService = openAIService
        self.deepLService = deepLService
    }

    func translate(text: String) async throws -> String {
        let settings = await MainActor.run { settingsStore.settings }
        let direction = languageDirectionResolver.resolve(for: text)

        switch settings.provider {
        case .google:
            return try await googleService.translate(text: text, direction: direction)
        case .openAICompatible:
            return try await openAIService.translate(text: text, direction: direction, settings: settings)
        case .deepL:
            return try await deepLService.translate(text: text, direction: direction, settings: settings)
        }
    }
}

struct TranslationDirection: Equatable {
    let sourceLanguageCode: String
    let targetLanguageCode: String
}
