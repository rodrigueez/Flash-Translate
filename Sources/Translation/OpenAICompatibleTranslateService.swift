import Foundation

struct OpenAICompatibleTranslateService {
    let httpClient: HTTPClient

    func translate(text: String, direction: TranslationDirection, settings: AppSettings) async throws -> String {
        guard let request = try buildRequest(text: text, direction: direction, settings: settings) else {
            throw TranslationNetworkError.missingConfiguration
        }

        let data = try await httpClient.send(request)
        let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw TranslationNetworkError.invalidResponse
        }
        return content
    }

    func buildRequest(text: String, direction: TranslationDirection, settings: AppSettings) throws -> URLRequest? {
        guard
            !settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !settings.model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        let normalizedBase = settings.baseURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: normalizedBase + "/chat/completions") else {
            throw TranslationNetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = OpenAIChatRequest(
            model: settings.model,
            messages: [
                .init(role: "system", content: "You are a translation engine. Return only the translated text with no explanation."),
                .init(role: "user", content: "Translate the following text from \(direction.sourceLanguageCode) to \(direction.targetLanguageCode):\n\n\(text)")
            ],
            reasoningEffort: settings.reasoningEffort
        )
        request.httpBody = try JSONEncoder().encode(payload)
        return request
    }
}

struct OpenAIChatRequest: Codable, Equatable {
    let model: String
    let messages: [OpenAIChatMessage]
    let reasoningEffort: ReasoningEffort?

    enum CodingKeys: String, CodingKey {
        case model, messages
        case reasoningEffort = "reasoning_effort"
    }
}

struct OpenAIChatMessage: Codable, Equatable {
    let role: String
    let content: String
}

struct OpenAIChatResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIChatMessage
}
