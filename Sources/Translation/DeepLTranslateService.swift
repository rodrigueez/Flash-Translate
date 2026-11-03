import Foundation

struct DeepLTranslateService {
    let httpClient: HTTPClient

    func translate(text: String, direction: TranslationDirection, settings: AppSettings) async throws -> String {
        guard let request = try buildRequest(text: text, direction: direction, settings: settings) else {
            throw TranslationNetworkError.missingConfiguration
        }

        let data = try await httpClient.send(request)
        let response = try JSONDecoder().decode(DeepLResponse.self, from: data)
        guard let translated = response.translations.first?.text,
              !translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranslationNetworkError.invalidResponse
        }
        return translated
    }

    func buildRequest(text: String, direction: TranslationDirection, settings: AppSettings) throws -> URLRequest? {
        let apiKey = settings.deepLAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else { return nil }
        guard let url = URL(string: settings.deepLPlan.baseURL + "/v2/translate") else {
            throw TranslationNetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(DeepLRequest(
            text: [text],
            source_lang: direction.sourceLanguageCode == "zh-CN" ? "ZH" : direction.sourceLanguageCode.uppercased(),
            target_lang: direction.targetLanguageCode == "zh-CN" ? "ZH-HANS" : direction.targetLanguageCode.uppercased()
        ))
        return request
    }
}

private struct DeepLRequest: Encodable {
    let text: [String]
    let source_lang: String
    let target_lang: String
}

private struct DeepLResponse: Decodable {
    let translations: [Translation]

    struct Translation: Decodable {
        let text: String
    }
}
