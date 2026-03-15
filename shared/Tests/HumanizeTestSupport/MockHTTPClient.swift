import Foundation
import HumanizeShared

public struct MockHTTPClient: HTTPClient, Sendable {
    public let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    public init(handler: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}

public func mockResponse(json: [String: Any], statusCode: Int = 200) -> (Data, URLResponse) {
    let data = try! JSONSerialization.data(withJSONObject: json)
    let response = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
    return (data, response)
}
