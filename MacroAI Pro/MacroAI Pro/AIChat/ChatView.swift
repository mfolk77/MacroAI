import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var showingPaywall = false
    @State private var lastMessageTime = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                // Show upgrade prompt for Basic tier (chat locked)
                if !subscriptionManager.currentTier.hasChatAccess {
                    upgradePromptBanner
                }
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input Bar
                HStack(spacing: 12) {
                    TextField("Ask about your macros...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // AI usage indicator
                aiUsageIndicator
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upgrade") {
                        showingPaywall = true
                    }
                    .opacity(subscriptionManager.currentTier == .basic ? 1 : 0)
                }
            }
        }
        .onAppear {
            if messages.isEmpty {
                addWelcomeMessage()
            }
            setupAutoCleanup()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var upgradePromptBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Chat Assistant Locked")
                    .font(.headline)
                Spacer()
                Button("Upgrade") {
                    showingPaywall = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            Text("Unlock AI chat with Pro ($4.99/month) or Elite ($5.99/month)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var aiUsageIndicator: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.blue)
            Text("Chat: \(subscriptionManager.getRemainingChatRequests())")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(subscriptionManager.currentTier.displayName)
                .font(.caption.bold())
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
    
    private func addWelcomeMessage() {
        let welcomeText: String
        
        if subscriptionManager.isTestFlightUser {
            welcomeText = "Hi! I'm your MacroAI assistant with full AI capabilities. I can help you with nutrition questions, meal suggestions, and macro tracking tips. What would you like to know?"
        } else {
            switch subscriptionManager.currentTier {
            case .basic:
                welcomeText = "Hi! I'm your MacroAI assistant. Chat is locked for free users - upgrade to Pro or Elite to unlock AI conversations. You can still use camera scanning (5/hour, 10/day limit)!"
            case .pro:
                welcomeText = "Hi! I'm your MacroAI Pro assistant. You have \(subscriptionManager.getRemainingChatRequests()) this month. I can help with nutrition questions, meal suggestions, and macro tracking tips. What would you like to know?"
            case .elite:
                welcomeText = "Hi! I'm your MacroAI Elite assistant with unlimited AI access. I can help with advanced nutrition analysis, meal optimization, and personalized macro guidance. What would you like to know?"
            }
        }
        
        let welcomeMessage = ChatMessage(
            text: welcomeText,
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
        lastMessageTime = Date()
    }
    
    // MARK: - Auto-Cleanup Functions
    
    private func setupAutoCleanup() {
        // Set up timer to check for auto-cleanup every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            checkForAutoCleanup()
        }
    }
    
    private func checkForAutoCleanup() {
        let now = Date()
        let timeSinceLastMessage = now.timeIntervalSince(lastMessageTime)
        
        // Auto-delete conversation after 10 minutes of inactivity
        if timeSinceLastMessage > 600 && messages.count > 1 { // Keep welcome message
            print("🧹 [ChatView] Auto-cleaning conversation after 10 minutes of inactivity")
            
            withAnimation(.easeInOut(duration: 0.5)) {
                // Keep only the welcome message
                if let welcomeMessage = messages.first(where: { !$0.isUser }) {
                    messages = [welcomeMessage]
                } else {
                    messages.removeAll()
                    addWelcomeMessage()
                }
            }
        }
    }
    
    private func updateLastMessageTime() {
        lastMessageTime = Date()
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            print("📱 [ChatView] Empty message, not sending")
            return 
        }
        
        print("📱 [ChatView] Sending message: '\(messageText)'")
        
        // Check if user can make chat request
        guard subscriptionManager.canMakeChatRequest() else {
            print("📱 [ChatView] Chat request denied, showing paywall")
            showingPaywall = true
            return
        }
        
        // Add user message
        let userMessage = ChatMessage(
            text: messageText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        updateLastMessageTime()
        
        let currentMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📱 [ChatView] Message before clearing: '\(messageText)'")
        
        // Clear the message field with proper UI update
        DispatchQueue.main.async {
            self.messageText = ""
            print("📱 [ChatView] messageText after clearing: '\(self.messageText)'")
        }
        
        // Show typing indicator
        isTyping = true
        
        // Try real AI first, fall back to mock if no API key
        OpenAIAPI.nutritionChat(userMessage: currentMessage, subscriptionManager: subscriptionManager) { result in
            DispatchQueue.main.async {
                isTyping = false
                
                let responseText: String
                switch result {
                case .success(let aiResponse):
                    responseText = aiResponse
                case .failure(let error):
                    print("⚠️ [ChatView] AI API failed, using mock: \(error)")
                    // Fall back to enhanced mock responses
                    responseText = generateMockResponse(for: currentMessage)
                }
                
                let aiMessage = ChatMessage(
                    text: responseText,
                    isUser: false,
                    timestamp: Date()
                )
                messages.append(aiMessage)
                self.updateLastMessageTime()
            }
        }
    }
    
    private func generateMockResponse(for userMessage: String) -> String {
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
                "Thanks for reaching out! I can assist with nutrition planning, meal suggestions, macro calculations, and general wellness tips. What would you like to explore?"
            ]
            return generalResponses.randomElement() ?? generalResponses[0]
        }
    }
}

// MARK: - Supporting Views

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(text: String, isUser: Bool, timestamp: Date) {
        self.id = UUID()
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .frame(maxWidth: .infinity * 0.8, alignment: .leading)
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    ChatView()
} 