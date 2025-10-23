import Foundation

enum ModerationCategory {
    case violence
    case hate
    case sexualMinors
    case selfHarm
    case illegalActivity
    case medicalDiagnosis
}

struct ModerationResult {
    let isAllowed: Bool
    let categories: [ModerationCategory]
}

final class ModerationService {
    static let shared = ModerationService()
    private init() {}

    // Lightweight keyword/heuristic checks; replace with Apple Safety APIs when available
    func evaluateUserPrompt(_ text: String) -> ModerationResult {
        let t = normalized(text)
        var hits: [ModerationCategory] = []
        if containsAny(t, ["kill", "murder", "assault"]) { hits.append(.violence) }
        if containsAny(t, ["hate", "racist", "homophobic"]) { hits.append(.hate) }
        if containsAny(t, ["minor", "underage"]) && containsAny(t, ["sex", "nude", "explicit"]) { hits.append(.sexualMinors) }
        if containsAny(t, ["suicide", "self harm", "kill myself"]) { hits.append(.selfHarm) }
        if containsAny(t, ["buy drugs", "fake id", "credit card dump"]) { hits.append(.illegalActivity) }
        if containsAny(t, ["diagnose", "prescribe", "treat my condition"]) { hits.append(.medicalDiagnosis) }
        return ModerationResult(isAllowed: hits.isEmpty, categories: hits)
    }

    func evaluateModelReply(_ text: String) -> ModerationResult {
        // Reuse same heuristics for now
        return evaluateUserPrompt(text)
    }

    private func normalized(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    private func containsAny(_ haystack: String, _ needles: [String]) -> Bool {
        for n in needles where haystack.contains(n) { return true }
        return false
    }
}

enum ModerationError: Error, LocalizedError {
    case blocked(categories: [ModerationCategory])

    var errorDescription: String? {
        switch self {
        case .blocked:
            return "This content isn’t allowed. Please rephrase your request."
        }
    }
}



