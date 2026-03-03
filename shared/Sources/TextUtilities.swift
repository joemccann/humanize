import Foundation

public func formatAnalysisForDisplay(_ raw: String) -> String {
    raw.replacingOccurrences(of: "(?m)^- ", with: "• ", options: .regularExpression)
       .replacingOccurrences(of: "(?m)^(• .+)\n(• )", with: "$1\n\n$2", options: .regularExpression)
}

public func parseHumanizeResponse(_ raw: String) -> (text: String, analysis: String?) {
    // 1. Try explicit --- delimiter (first occurrence only)
    if let delimiterRange = raw.range(of: "\n---\n") {
        let textPart = String(raw[raw.startIndex..<delimiterRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let analysisPart = String(raw[delimiterRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (textPart, analysisPart.isEmpty ? nil : analysisPart)
    }

    // 2. Heuristic: look for "What makes" analysis header to split on
    let analysisPatterns = ["**What makes", "## What makes"]
    for pattern in analysisPatterns {
        if let splitRange = raw.range(of: pattern) {
            var textPart = String(raw[raw.startIndex..<splitRange.lowerBound])
            var analysisPart = String(raw[splitRange.lowerBound...])

            // Strip leading header from text part (e.g. "**Rewritten Version:**\n" or "## Rewritten\n")
            let headerPatterns = [
                "\\*\\*Rewritten[^*]*\\*\\*:?\\s*\n?",
                "##\\s*Rewritten[^\n]*\n?",
            ]
            for hp in headerPatterns {
                textPart = textPart.replacingOccurrences(of: hp, with: "", options: .regularExpression)
            }

            // Strip the analysis header line itself
            let analysisHeaderPatterns = [
                "\\*\\*What makes[^*]*\\*\\*:?\\s*\n?",
                "##\\s*What makes[^\n]*\n?",
            ]
            for ahp in analysisHeaderPatterns {
                analysisPart = analysisPart.replacingOccurrences(of: ahp, with: "", options: .regularExpression)
            }

            textPart = textPart.trimmingCharacters(in: .whitespacesAndNewlines)
            analysisPart = analysisPart.trimmingCharacters(in: .whitespacesAndNewlines)

            return (textPart, analysisPart.isEmpty ? nil : analysisPart)
        }
    }

    // 3. No structure detected — return raw as text
    return (raw.trimmingCharacters(in: .whitespacesAndNewlines), nil)
}

public func normalizeInputWhitespace(_ text: String) -> String {
    text
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .replacingOccurrences(of: "[\\t ]+", with: " ", options: .regularExpression)
        .replacingOccurrences(of: " *\n *", with: "\n", options: .regularExpression)
        .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
}

public func formatLatencySeconds(_ latencyMs: Int) -> String {
    let clampedMs = max(0, latencyMs)
    let wholeSeconds = clampedMs / 1000
    let remainingMs = clampedMs % 1000

    guard remainingMs != 0 else { return "\(wholeSeconds)s" }

    let roundedHundredths = (remainingMs + 5) / 10
    if roundedHundredths == 0 {
        return "\(wholeSeconds)s"
    }
    if roundedHundredths == 100 {
        return "\(wholeSeconds + 1)s"
    }

    let tenths = roundedHundredths / 10
    let hundredths = roundedHundredths % 10
    if hundredths == 0 {
        return "\(wholeSeconds).\(tenths)s"
    }
    return "\(wholeSeconds).\(tenths)\(hundredths)s"
}
