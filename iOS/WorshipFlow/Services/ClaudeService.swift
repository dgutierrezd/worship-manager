import Foundation

// MARK: - Claude AI Service
//
// Song lookup is proxied through the WorshipFlow backend (/ai/song-lookup).
// The Anthropic API key lives in the backend's ANTHROPIC_API_KEY env var —
// it is never embedded in the iOS binary or stored in source control.

enum ClaudeService {

    // MARK: - Public API

    /// Looks up song details for `names` via the WorshipFlow backend.
    /// Returns one `AISongResult` per input name in the same order.
    static func lookupSongs(names: [String]) async throws -> [AISongResult] {
        let rawText = try await callBackend(names: names)
        return try parseResults(from: rawText, expectedCount: names.count, inputNames: names)
    }

    // MARK: - Network Request

    private static func callBackend(names: [String]) async throws -> String {
        let rawText: BackendResponse = try await APIClient.shared.post(
            "/ai/song-lookup",
            body: ["names": names]
        )
        return rawText.result
    }

    // MARK: - Response Parsing

    private static func parseResults(
        from text: String,
        expectedCount: Int,
        inputNames: [String]
    ) throws -> [AISongResult] {

        // Normalise: strip any accidental markdown fences Claude might emit
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: "\n")
            cleaned = lines.dropFirst().dropLast().joined(separator: "\n")
        }

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw ClaudeError.invalidJSON("Response is not valid UTF-8")
        }

        struct Wrapper: Decodable { let results: [AISongResult] }

        do {
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: jsonData)
            var results = wrapper.results

            // Safety: if Claude returns fewer items than expected, pad with "not found" stubs
            while results.count < expectedCount {
                let idx  = results.count
                let name = idx < inputNames.count ? inputNames[idx] : "Unknown"
                results.append(AISongResult.notFound(title: name))
            }

            return results

        } catch let decodingError {
            throw ClaudeError.invalidJSON(
                "\(decodingError.localizedDescription)\n\nRaw response:\n\(cleaned.prefix(500))"
            )
        }
    }
}

// MARK: - Backend Response Envelope

private struct BackendResponse: Decodable {
    let result: String
}

// MARK: - Error Types

enum ClaudeError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case noTextContent
    case invalidJSON(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from AI service"
        case .httpError(let code, let body):
            return "AI service returned HTTP \(code).\n\(body)"
        case .noTextContent:
            return "AI service returned an empty response"
        case .invalidJSON(let detail):
            return "Could not read song data from AI.\n\(detail)"
        }
    }
}

// MARK: - AISongResult factory helper

private extension AISongResult {
    static func notFound(title: String) -> AISongResult {
        AISongResult(
            found: false,
            title: title,
            artist: nil,
            defaultKey: nil,
            tempoBpm: nil,
            durationSec: nil,
            lyrics: nil,
            theme: nil,
            youtubeUrl: nil,
            spotifyUrl: nil,
            chordSections: nil
        )
    }
}
