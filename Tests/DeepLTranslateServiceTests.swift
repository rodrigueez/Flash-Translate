import XCTest
@testable import FlashTranslate

final class DeepLTranslateServiceTests: XCTestCase {
    func testBuildRequestUsesPlanAndMapsChineseLanguageCodes() throws {
        let service = DeepLTranslateService(httpClient: HTTPClient())
        var settings = AppSettings()
        settings.deepLAPIKey = " secret:fx \n"

        for plan in DeepLPlan.allCases {
            settings.deepLPlan = plan
            for direction in [
                TranslationDirection(sourceLanguageCode: "en", targetLanguageCode: "zh-CN"),
                TranslationDirection(sourceLanguageCode: "zh-CN", targetLanguageCode: "en")
            ] {
                let request = try XCTUnwrap(service.buildRequest(text: "hello & 你好", direction: direction, settings: settings))
                let expectedHost = plan == .free ? "api-free.deepl.com" : "api.deepl.com"
                XCTAssertEqual(request.url?.absoluteString, "https://\(expectedHost)/v2/translate")
                XCTAssertEqual(request.httpMethod, "POST")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "DeepL-Auth-Key secret:fx")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
                let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
                XCTAssertEqual(payload["text"] as? [String], ["hello & 你好"])
                XCTAssertEqual(payload["source_lang"] as? String, direction.sourceLanguageCode == "en" ? "EN" : "ZH")
                XCTAssertEqual(payload["target_lang"] as? String, direction.targetLanguageCode == "en" ? "EN" : "ZH-HANS")
            }
        }
    }

    func testMissingKeyDoesNotBuildRequest() throws {
        let service = DeepLTranslateService(httpClient: HTTPClient())
        var settings = AppSettings()
        settings.deepLAPIKey = " \n"
        XCTAssertNil(try service.buildRequest(
            text: "hello",
            direction: TranslationDirection(sourceLanguageCode: "en", targetLanguageCode: "zh-CN"),
            settings: settings
        ))
    }

    @MainActor
    func testTranslationServiceRoutesDeepLAndReturnsTranslation() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DeepLStubProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let httpClient = HTTPClient(session: session)
        let suiteName = "DeepLTranslateServiceTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = SettingsStore(defaults: defaults)
        var settings = AppSettings()
        settings.provider = .deepL
        settings.deepLAPIKey = "test-key"
        store.save(settings)
        let service = TranslationService(
            settingsStore: store,
            languageDirectionResolver: LanguageDirectionResolver(),
            googleService: GoogleTranslateService(httpClient: httpClient),
            openAIService: OpenAICompatibleTranslateService(httpClient: httpClient),
            deepLService: DeepLTranslateService(httpClient: httpClient)
        )

        let translated = try await service.translate(text: "hello")
        XCTAssertEqual(translated, "你好")
    }

    func testEmptyTranslationAndHTTPFailuresAreReported() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DeepLStubProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = DeepLTranslateService(httpClient: HTTPClient(session: session))
        var settings = AppSettings()
        settings.deepLAPIKey = "test-key"

        for text in ["empty", "quota"] {
            do {
                _ = try await service.translate(
                    text: text,
                    direction: TranslationDirection(sourceLanguageCode: "en", targetLanguageCode: "zh-CN"),
                    settings: settings
                )
                XCTFail("Expected failure for \(text)")
            } catch let error as TranslationNetworkError {
                if text == "empty" {
                    XCTAssertEqual(error, .invalidResponse)
                } else {
                    XCTAssertEqual(error, .httpError(statusCode: 456, message: "Quota exceeded"))
                }
            }
        }
    }
}

private final class DeepLStubProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard request.url?.host == "api-free.deepl.com", request.url?.path == "/v2/translate" else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let body: Data
        if let data = request.httpBody {
            body = data
        } else if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 1024)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                data.append(buffer, count: count)
            }
            body = data
        } else {
            body = Data()
        }
        let payload = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
        let text = (payload?["text"] as? [String])?.first
        let status = text == "quota" ? 456 : 200
        let responseBody = text == "quota" ? "Quota exceeded" :
            (text == "empty" ? "{\"translations\":[]}" : "{\"translations\":[{\"text\":\"你好\"}]}")
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(responseBody.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
