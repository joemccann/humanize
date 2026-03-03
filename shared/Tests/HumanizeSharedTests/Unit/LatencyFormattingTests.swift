import Testing
@testable import HumanizeShared

@Suite("formatLatencySeconds")
struct LatencyFormattingTests {
    @Test("Formats exact seconds without decimals")
    func exactSeconds() {
        #expect(formatLatencySeconds(5000) == "5s")
        #expect(formatLatencySeconds(0) == "0s")
    }

    @Test("Formats non-zero fractional seconds")
    func fractionalSeconds() {
        #expect(formatLatencySeconds(5182) == "5.18s")
        #expect(formatLatencySeconds(5100) == "5.1s")
    }

    @Test("Rounds to next whole second when hundredths overflow")
    func roundsToNextSecond() {
        #expect(formatLatencySeconds(5996) == "6s")
    }

    @Test("Clamps negative latency to zero")
    func negativeLatency() {
        #expect(formatLatencySeconds(-250) == "0s")
    }
}
