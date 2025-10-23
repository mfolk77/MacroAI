// OpenAIAPI.swift
// OpenAI API for nutrition chat functionality

import Foundation

class OpenAIAPI {
    
    // MARK: - API Key Management
    
    static func saveAPIKey(_ key: String) {
        do {
            try SecureConfig.saveOpenAIAPIKey(key)
        } catch {
            print("❌ Failed to save OpenAI API key: \(error)")
        }
    }
    
    static func getAPIKey() -> String? {
        return SecureConfig.getOpenAIAPIKey()
    }
    
    static func deleteAPIKey() {
        do {
            try SecureConfig.deleteOpenAIAPIKey()
        } catch {
            print("❌ Failed to delete OpenAI API key: \(error)")
        }
    }
    
    static func hasValidAPIKey() -> Bool {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            return false
        }
        return apiKey.hasPrefix("sk-")
    }
    
    // MARK: - Nutrition Chat
    
    static func nutritionChat(
        userMessage: String,
        subscriptionManager: Any?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Check if we have a valid API key
        guard let apiKey = getAPIKey(), hasValidAPIKey() else {
            completion(.failure(APIError.noAPIKey))
            return
        }
        
        // Make real OpenAI API call
        Task {
            do {
                let response = try await makeOpenAIAPICall(message: userMessage, apiKey: apiKey)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - General Chat with context/history (for testing fallback)
    static func chat(
        adapter: AppleAIAPI.Adapter,
        context: String?,
        userMessage: String,
        history: [String]?,
        temperature: Double = 0.6,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiKey = getAPIKey(), hasValidAPIKey() else {
            completion(.failure(APIError.noAPIKey))
            return
        }
        Task {
            do {
                let response = try await makeOpenAIChatCall(
                    adapter: adapter,
                    context: context,
                    userMessage: userMessage,
                    history: history ?? [],
                    temperature: temperature,
                    apiKey: apiKey
                )
                DispatchQueue.main.async { completion(.success(response)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Real OpenAI API Integration
    
    private static func makeOpenAIAPICall(message: String, apiKey: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are a nutrition expert assistant. Provide helpful, accurate nutrition advice in a friendly, conversational tone. 
        Focus on practical tips, meal suggestions, and evidence-based nutrition information.
        Keep responses concise but informative (2-3 paragraphs max).
        
        User question: \(message)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are a helpful nutrition expert assistant."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 500,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ OpenAI API Error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                print("Error details: \(errorData)")
            }
            throw APIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError
        }
        
        return content
    }

    private static func makeOpenAIChatCall(
        adapter: AppleAIAPI.Adapter,
        context: String?,
        userMessage: String,
        history: [String],
        temperature: Double,
        apiKey: String
    ) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: Any]] = []
        let system: String
        switch adapter {
        case .general:
            system = "You are a concise, helpful assistant for MacroAI. Be clear and practical."
        case .nutrition:
            system = "You are a nutrition planning assistant for MacroAI. Provide practical, evidence‑based suggestions. Avoid medical advice."
        }
        messages.append(["role": "system", "content": system])
        if let ctx = context, !ctx.isEmpty {
            messages.append(["role": "system", "content": "Context: \(ctx)"])
        }
        for h in history.prefix(10) {
            if h.hasPrefix("user:") {
                messages.append(["role": "user", "content": String(h.dropFirst(5)).trimmingCharacters(in: .whitespaces)])
            } else if h.hasPrefix("assistant:") {
                messages.append(["role": "assistant", "content": String(h.dropFirst(10)).trimmingCharacters(in: .whitespaces)])
            }
        }
        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "max_tokens": 500,
            "temperature": max(0, min(1, temperature))
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard httpResponse.statusCode == 200 else {
            if let err = String(data: data, encoding: .utf8) { print("❌ OpenAI chat error: \(httpResponse.statusCode) -> \(err)") }
            throw APIError.apiError("HTTP \(httpResponse.statusCode)")
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else { throw APIError.decodingError }
        return content
    }
    
    // MARK: - Error Types
    
    enum APIError: Error, LocalizedError {
        case noAPIKey
        case invalidResponse
        case apiError(String)
        case decodingError
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured"
            case .invalidResponse:
                return "Invalid response from OpenAI API"
            case .apiError(let message):
                return "API Error: \(message)"
            case .decodingError:
                return "Failed to decode API response"
            }
        }
    }
    
    // MARK: - Mock Response Generation
    
    private static func generateMockResponse(for userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        // Keto-specific meal suggestions
        if lowercased.contains("keto") && (lowercased.contains("dinner") || lowercased.contains("meal")) && lowercased.contains("chicken") {
            let ketoChickenMeals = [
                "Here's a delicious keto chicken dinner idea:\n\n🍗 **Herb-Crusted Chicken Thighs**\n• 6 oz chicken thighs (skin-on)\n• Sautéed spinach with garlic\n• Roasted broccoli with parmesan\n• Side of avocado slices\n\n**Macros**: ~35g protein, 5g net carbs, 28g fat\nTotal: ~400 calories",
                
                "Perfect! Try this keto chicken dinner:\n\n🥗 **Chicken Caesar Salad Bowl**\n• Grilled chicken breast (6 oz)\n• Romaine lettuce with full-fat caesar dressing\n• Parmesan cheese and bacon bits\n• Cucumber and cherry tomatoes\n\n**Macros**: ~40g protein, 6g net carbs, 25g fat\nTotal: ~390 calories",
                
                "Great choice! Here's a satisfying keto option:\n\n🍲 **Chicken & Cauliflower Casserole**\n• Diced chicken thighs (6 oz)\n• Cauliflower rice base\n• Heavy cream sauce with herbs\n• Topped with mozzarella cheese\n\n**Macros**: ~38g protein, 7g net carbs, 30g fat\nTotal: ~420 calories"
            ]
            return ketoChickenMeals.randomElement() ?? ketoChickenMeals[0]
        }
        
        // General meal suggestions with protein
        if (lowercased.contains("dinner") || lowercased.contains("meal")) && lowercased.contains("chicken") {
            let chickenMeals = [
                "Here's a balanced chicken dinner:\n\n🍽️ **Mediterranean Chicken**\n• Grilled chicken breast with herbs\n• Quinoa pilaf with vegetables\n• Greek salad with olive oil\n• Side of hummus\n\n**Macros**: ~35g protein, 45g carbs, 18g fat",
                
                "Try this nutritious option:\n\n🥘 **Chicken Stir-Fry**\n• Chicken breast strips (6 oz)\n• Mixed vegetables (bell peppers, broccoli, snap peas)\n• Brown rice (1/2 cup cooked)\n• Light teriyaki sauce\n\n**Macros**: ~40g protein, 35g carbs, 12g fat"
            ]
            return chickenMeals.randomElement() ?? chickenMeals[0]
        }
        
        if lowercased.contains("protein") {
            let proteinTips = [
                "Great question about protein! For optimal muscle maintenance and growth, aim for 0.8-1.2g of protein per kg of body weight. Good sources include lean meats, fish, eggs, dairy, legumes, and protein supplements.",
                "Protein is crucial for muscle repair and satiety! Try to include protein in every meal. Some quick options: Greek yogurt, cottage cheese, protein smoothies, or hard-boiled eggs for snacks.",
                "Timing your protein intake matters too! Having 20-30g protein within 2 hours post-workout can optimize muscle protein synthesis. Don't forget plant proteins like lentils and quinoa!"
            ]
            return proteinTips.randomElement() ?? proteinTips[0]
        } else if lowercased.contains("carb") || lowercased.contains("carbohydrate") {
            let carbTips = [
                "Carbohydrates are your body's primary energy source! Focus on complex carbs like whole grains, fruits, and vegetables. Timing matters too - having carbs around workouts can boost performance and recovery.",
                "Not all carbs are created equal! Choose complex carbohydrates like oats, sweet potatoes, and brown rice over simple sugars. They provide sustained energy and better blood sugar control.",
                "Carb cycling can be effective for some people - higher carbs on training days, lower on rest days. This helps fuel performance while supporting body composition goals."
            ]
            return carbTips.randomElement() ?? carbTips[0]
        } else if lowercased.contains("fat") || lowercased.contains("healthy fat") {
            let fatTips = [
                "Healthy fats are essential for hormone production and nutrient absorption! Include sources like avocados, nuts, olive oil, and fatty fish. Aim for about 20-35% of your daily calories from fats.",
                "Don't fear fats! They're crucial for brain health and hormone production. Focus on omega-3s from fish, monounsaturated fats from olive oil and avocados, and moderate amounts of saturated fats.",
                "Fat-soluble vitamins (A, D, E, K) need dietary fat for absorption. Include a little healthy fat with each meal to maximize nutrient uptake from your vegetables!"
            ]
            return fatTips.randomElement() ?? fatTips[0]
        } else if lowercased.contains("weight loss") || lowercased.contains("lose weight") {
            let weightLossTips = [
                "For sustainable weight loss, create a moderate caloric deficit (300-500 calories below maintenance). Focus on whole foods, stay hydrated, and maintain adequate protein to preserve muscle mass.",
                "Weight loss is about consistency, not perfection! Aim for 1-2 lbs per week. Track your food, eat plenty of vegetables, and don't eliminate entire food groups unless medically necessary.",
                "The best diet for weight loss is one you can stick to long-term. Focus on nutrient-dense foods that keep you satisfied, and remember that small, sustainable changes beat dramatic restrictions."
            ]
            return weightLossTips.randomElement() ?? weightLossTips[0]
        } else if lowercased.contains("meal") || lowercased.contains("food") {
            let mealTips = [
                "For balanced meals, try the plate method: 1/2 vegetables, 1/4 lean protein, 1/4 complex carbs. Don't forget healthy fats! This helps ensure you're getting all the nutrients your body needs.",
                "Meal prep is a game-changer! Prepare proteins, chop vegetables, and cook grains in batches. Having healthy options ready makes it easier to stick to your nutrition goals.",
                "Listen to your hunger cues and eat mindfully. Chew slowly, put your fork down between bites, and stop when you're satisfied (not stuffed). This helps with digestion and portion control."
            ]
            return mealTips.randomElement() ?? mealTips[0]
        } else if lowercased.contains("water") || lowercased.contains("hydration") {
            let hydrationTips = [
                "Stay hydrated! Aim for 8-10 glasses of water daily, more if you're active. Proper hydration supports metabolism, helps with appetite control, and improves overall performance.",
                "Your urine color is a good hydration indicator - aim for pale yellow. Add lemon, cucumber, or mint to make water more appealing if you struggle to drink enough plain water.",
                "Don't wait until you're thirsty! Thirst is a late indicator of dehydration. Start your day with a glass of water and keep a water bottle nearby as a visual reminder."
            ]
            return hydrationTips.randomElement() ?? hydrationTips[0]
        } else {
            let generalResponses = [
                "That's a great question! I'd love to help you with nutrition advice. Try asking about protein, carbs, meal planning, or weight management tips!",
                "I'm here to help with nutrition guidance! Feel free to ask about meal ideas, macro targets, hydration, or any specific dietary questions you have.",
                "Nutrition is personal! What works for one person might not work for another. I'm here to provide evidence-based advice tailored to your needs and goals."
            ]
            return generalResponses.randomElement() ?? generalResponses[0]
        }
    }
} 