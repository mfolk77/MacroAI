import Foundation
import Combine

final class AIChatService: ObservableObject {
    static let shared = AIChatService()

    @Published private(set) var isUsingAppleModel: Bool = true

    private init() {}

    enum ChatError: Error {
        case unavailable
    }

    func chat(userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Prefer Apple's foundation model when available
        if AppleAIAPI.isAvailable {
            AppleAIAPI.nutritionChat(userMessage: userMessage) { [weak self] result in
                switch result {
                case .success(let text):
                    DispatchQueue.main.async { self?.isUsingAppleModel = true }
                    completion(.success(text))
                case .failure:
                    // Fallback to OpenAI when Apple model is unavailable/fails
                    self?.fallbackToOpenAI(userMessage: userMessage, completion: completion)
                }
            }
        } else {
            fallbackToOpenAI(userMessage: userMessage, completion: completion)
        }
    }

    private func fallbackToOpenAI(userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.main.async { self.isUsingAppleModel = false }
        OpenAIAPI.nutritionChat(userMessage: userMessage, subscriptionManager: nil) { result in
            completion(result)
        }
    }
}


