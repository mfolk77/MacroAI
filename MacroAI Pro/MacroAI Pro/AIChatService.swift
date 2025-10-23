import Foundation
import Combine

final class AIChatService: ObservableObject {
    static let shared = AIChatService()

    @Published private(set) var isUsingAppleModel: Bool = true
    
    enum AdapterMode {
        case none
        case nutrition
    }
    
    @Published var adapterMode: AdapterMode = .none

    // Short, static help context so the model can answer questions about Coach and app features
    static let featuresHelpContext: String = {
        return [
            "Feature Overview:",
            "- Coach: educational nutrition guidance (not medical advice). Helps with quick wins, meal planning, and gentle reminders.",
            "- Coach Nudges: Daily, Evening, Weekly, Protein-by-Lunch, Pre-log Dinner. User sets times via the bell icon in Chat or Settings → Coach Mode → Schedule.",
            "- Trial & Access: Coach fully available for Pro/Elite; Basic gets a one-time 7-day trial.",
            "- Nutrition Adapter: when enabled (leaf icon), the chat tailors answers to macros and targets.",
            "- Auto-Tune: weekly macro tweaks based on progress.",
            "Answer policy: provide practical, safe, food-related guidance; do not give medical diagnosis or treatment.",
        ].joined(separator: "\n")
    }()

    private init() {}

    enum ChatError: Error {
        case unavailable
    }

    func chat(userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        chat(userMessage: userMessage, context: nil, history: nil, temperature: 0.5, completion: completion)
    }

    func chat(userMessage: String, context: String?, history: [String]?, temperature: Double = 0.5, completion: @escaping (Result<String, Error>) -> Void) {
        // Pre-moderation (user prompt)
        let pre = ModerationService.shared.evaluateUserPrompt(userMessage)
        guard pre.isAllowed else {
            completion(.failure(ModerationError.blocked(categories: pre.categories)))
            return
        }
        // Route to Apple's foundation model only. If unavailable, surface a controlled failure
        // so the UI can provide a local mock response without using third-party providers.
        if AppleAIAPI.isAvailable {
            let adapter: AppleAIAPI.Adapter
            switch adapterMode {
            case .none: adapter = .general
            case .nutrition: adapter = .nutrition
            }
            // Prepend feature help context so the model can answer "what can Coach do?" etc.
            let mergedContext: String
            if let ctx = context, !ctx.isEmpty {
                mergedContext = AIChatService.featuresHelpContext + "\n\n" + ctx
            } else {
                mergedContext = AIChatService.featuresHelpContext
            }
            AppleAIAPI.chat(adapter: adapter, context: mergedContext, userMessage: userMessage, history: history, temperature: temperature) { [weak self] result in
                DispatchQueue.main.async { self?.isUsingAppleModel = true }
                switch result {
                case .success(let text):
                    // Post-moderation (model reply)
                    let post = ModerationService.shared.evaluateModelReply(text)
                    if post.isAllowed {
                        completion(.success(text))
                    } else {
                        completion(.failure(ModerationError.blocked(categories: post.categories)))
                    }
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        } else {
            DispatchQueue.main.async { self.isUsingAppleModel = true }
            completion(.failure(ChatError.unavailable))
        }
    }

    // No OpenAI fallback per product requirements (Apple model only)
}


