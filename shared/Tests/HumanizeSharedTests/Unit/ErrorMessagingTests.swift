import Testing
import Foundation
@testable import HumanizeShared

@Suite("HumanizeError user-facing messages")
struct ErrorMessagingTests {
    @Test("noAPIKey has user-facing description")
    func noAPIKeyMessage() {
        let error = HumanizeError.noAPIKey
        #expect(error.userFacingDescription.contains("API key"))
        #expect(!error.userFacingDescription.contains("error"))
    }

    @Test("invalidResponse has user-facing description")
    func invalidResponseMessage() {
        let error = HumanizeError.invalidResponse
        #expect(error.userFacingDescription.contains("unreadable"))
    }

    @Test("networkError has user-facing description")
    func networkErrorMessage() {
        let error = HumanizeError.networkError("Connection refused")
        #expect(error.userFacingDescription.contains("connect"))
        // Should NOT contain the raw technical message
        #expect(!error.userFacingDescription.contains("Connection refused"))
    }

    @Test("apiError passes through provider message")
    func apiErrorMessage() {
        let error = HumanizeError.apiError(status: 429, message: "Rate limit reached")
        #expect(error.userFacingDescription == "Rate limit reached")
    }

    @Test("isCritical is true for network and key errors")
    func criticalErrors() {
        #expect(HumanizeError.noAPIKey.isCritical == true)
        #expect(HumanizeError.networkError("timeout").isCritical == true)
    }

    @Test("isCritical is false for recoverable errors")
    func nonCriticalErrors() {
        #expect(HumanizeError.invalidResponse.isCritical == false)
        #expect(HumanizeError.apiError(status: 500, message: "unavailable").isCritical == false)
    }

    @Test("All error types produce non-empty user-facing descriptions")
    func allDescriptionsNonEmpty() {
        let errors: [HumanizeError] = [
            .noAPIKey,
            .invalidResponse,
            .networkError("test"),
            .apiError(status: 400, message: "bad request"),
        ]
        for error in errors {
            #expect(!error.userFacingDescription.isEmpty)
        }
    }
}
