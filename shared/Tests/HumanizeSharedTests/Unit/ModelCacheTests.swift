import Testing
import Foundation
@testable import HumanizeShared
import HumanizeTestSupport

@Suite("Model cache invalidation")
struct ModelCacheTests {
    @Test("invalidateModelCache clears cached models")
    func invalidateModelCache() async throws {
        let fetchCount = FetchCounter()
        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            if path == "/v1/models" {
                await fetchCount.increment()
                return mockResponse(json: ["data": []])
            }
            return mockResponse(json: [
                "choices": [["message": ["content": "result"]]]
            ])
        }

        let service = HumanizeAPIService(httpClient: client)

        // First call — fetches models
        _ = try await service.humanize(text: "test", tone: .natural, provider: .openai, apiKey: "sk-test-cache-\(UUID())")
        let firstCount = await fetchCount.count

        // Invalidate and call again — should re-fetch
        await service.invalidateModelCache()
        _ = try await service.humanize(text: "test", tone: .natural, provider: .openai, apiKey: "sk-test-cache-\(UUID())")
        let secondCount = await fetchCount.count

        #expect(secondCount > firstCount)
    }
}

private actor FetchCounter {
    var count = 0
    func increment() { count += 1 }
}
