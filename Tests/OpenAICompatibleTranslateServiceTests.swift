import XCTest
@testable import FlashTranslate

final class OpenAICompatibleTranslateServiceTests: XCTestCase {
    func testBuildRequestUsesChatCompletionsEndpoint() throws {
        let service = OpenAICompatibleTranslateService(httpClient: HTTPClient())
        var settings = AppSettings()
        settings.provider = .openAICompatible
        settings.baseURL = "https://api.example.com/v1/"
        settings.apiKey = "secret"
        settings.model = "gpt-4.1-mini"

        let request = try service.buildRequest(
            text: "hello",
            direction: TranslationDirection(sourceLanguageCode: "en", targetLanguageCode: "zh-CN"),
            settings: settings
        )

        XCTAssertEqual(request?.url?.absoluteString, "https://api.example.com/v1/chat/completions")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer secret")
        XCTAssertEqual(request?.httpMethod, "POST")
        let body = try XCTUnwrap(request?.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertNil(payload["reasoning_effort"])
    }

    func testBuildRequestSendsEachExplicitReasoningEffort() throws {
        let service = OpenAICompatibleTranslateService(httpClient: HTTPClient())
        var settings = AppSettings()
        settings.baseURL = "https://api.example.com/v1"
        settings.apiKey = "secret"

        for effort in ReasoningEffort.allCases {
            settings.reasoningEffort = effort
            let request = try service.buildRequest(
                text: "hello",
                direction: TranslationDirection(sourceLanguageCode: "en", targetLanguageCode: "zh-CN"),
                settings: settings
            )
            let body = try XCTUnwrap(request?.httpBody)
            let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
            XCTAssertEqual(payload["reasoning_effort"] as? String, effort.rawValue)
            XCTAssertNil(payload["reasoningEffort"])
        }
    }
}
