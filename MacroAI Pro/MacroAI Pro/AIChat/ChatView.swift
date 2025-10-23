import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isTyping = false
    @State private var showingPaywall = false
    @State private var lastMessageTime = Date()
    @StateObject private var chatService = AIChatService.shared
    var initialPrompt: String? = nil
    @State private var showFeed: Bool = true
    @State private var showCustomizeFeed: Bool = false
    @State private var showNudgeConfig: Bool = false
    @State private var showChatTips: Bool = false
    @State private var showChatSpotlight: Bool = false
    // Coach Feed options (persisted)
    @State private var feedProteinByLunch: Bool = true
    @State private var feedPrelogDinner: Bool = true
    @State private var feedHydration: Bool = false
    @State private var feedSteps: Bool = false
    @State private var feedBreakfast: Bool = false
    @State private var feedLunch: Bool = false
    @State private var feedDinner: Bool = false
    @State private var feedProteinSnacks: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                coachFeed
                // Fallback notice when Apple model is unavailable
                if chatService.isUsingAppleModel == false {
                    Text("Using OpenAI due to device/OS compatibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                // Show upgrade prompt for Basic after trial expiry
                if subscriptionManager.currentTier == .basic && !CoachTrialManager.shared.isWithinTrialWindow() {
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
                    .onChange(of: messages.count) {
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
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showCustomizeFeed = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.small)
                    }
                    Button {
                        showNudgeConfig = true
                    } label: {
                        Image(systemName: "bell.badge")
                            .imageScale(.small)
                            .accessibilityLabel("Configure Coach Nudges")
                    }
                    Button {
                        let enable = chatService.adapterMode != .nutrition
                        chatService.adapterMode = enable ? .nutrition : .none
                        Analytics.featureUse("chat_adapter", action: enable ? "enable_nutrition" : "disable_nutrition")
                    } label: {
                        Image(systemName: chatService.adapterMode == .nutrition ? "leaf.circle.fill" : "leaf.circle")
                            .foregroundColor(chatService.adapterMode == .nutrition ? .green : .primary)
                            .imageScale(.small)
                            .accessibilityLabel(chatService.adapterMode == .nutrition ? "Disable Nutrition" : "Enable Nutrition")
                    }
                    
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
            if let prompt = initialPrompt, !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, messageText.isEmpty {
                messageText = prompt
            }
            // If Coach Mode is enabled, default adapter to nutrition
            if UserDefaults.standard.bool(forKey: "coachModeEnabled") {
                chatService.adapterMode = .nutrition
            }
            loadFeedPrefs()
            // Start 7‑day trial on first open if Basic
            if subscriptionManager.currentTier == .basic {
                let started = CoachTrialManager.shared.startIfNeeded(days: 7)
                if started { Analytics.featureUse("coach", action: "trial_started") }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showCustomizeFeed) {
            NavigationView {
                Form {
                    Section("Quick wins") {
                        Toggle("Protein by Lunch", isOn: $feedProteinByLunch)
                        Toggle("Pre‑log Dinner", isOn: $feedPrelogDinner)
                        Toggle("Hydration reminder", isOn: $feedHydration)
                        Toggle("Steps boost walk", isOn: $feedSteps)
                    }
                    Section("Meal planning") {
                        Toggle("Breakfast plan", isOn: $feedBreakfast)
                        Toggle("Lunch plan", isOn: $feedLunch)
                        Toggle("Dinner plan", isOn: $feedDinner)
                        Toggle("High‑protein snack ideas", isOn: $feedProteinSnacks)
                    }
                }
                .navigationTitle("Coach Feed")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { showCustomizeFeed = false } }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { saveFeedPrefs(); showCustomizeFeed = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showNudgeConfig) {
            CoachNudgeConfigView(onScheduled: { _ in })
        }
        .sheet(isPresented: $showChatTips) {
            ChatTipsOverlay { showChatTips = false }
        }
        .overlay(
            ChatSpotlightOverlay(isVisible: $showChatSpotlight)
        )
        .onAppear {
            // Clear coach badge when opening chat
            UserDefaults.standard.set(true, forKey: "coach_badge_override_zero")
            NotificationCenter.default.post(name: .coachBadgeUpdated, object: nil)
            if !UserDefaults.standard.bool(forKey: "ChatTipsSeen") {
                showChatTips = true
                UserDefaults.standard.set(true, forKey: "ChatTipsSeen")
            }
            if !UserDefaults.standard.bool(forKey: "ChatSpotlightSeen") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation { showChatSpotlight = true }
                }
            }
        }
        .onDisappear {
            // Post notification when coach is dismissed to resume demo
            NotificationCenter.default.post(name: Notification.Name("ResumeInteractiveDemo"), object: nil)
        }
    }
    
    // Minimal Coach Feed at top
    private var coachFeed: some View {
        VStack(alignment: .leading, spacing: 6) {
            DisclosureGroup(isExpanded: $showFeed) {
                VStack(alignment: .leading, spacing: 8) {
                    if SubscriptionManager.shared.currentTier == .basic && !CoachTrialManager.shared.isWithinTrialWindow() {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill").foregroundColor(.orange)
                            Text("Unlock Coach to see personalized quick wins and plans.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Upgrade") { showingPaywall = true }
                                .font(.caption)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                        }
                        .padding(.horizontal)
                    } else {
                        if feedProteinByLunch { feedRow(title: "Protein by Lunch") { messageText = "Give me 5 quick high‑protein snack ideas under 250 calories." } }
                        if feedPrelogDinner { feedRow(title: "Pre‑log Dinner") { messageText = "Help me plan a balanced dinner ~550 calories with ~35–40g protein. 3 options." } }
                        if feedHydration { feedRow(title: "Hydration reminder") { messageText = "Suggest simple ways to hit 2–3L water today. 5 quick tips." } }
                        if feedSteps { feedRow(title: "Steps boost walk") { messageText = "Give me three 10–15 minute walk ideas I can do today, with timing suggestions." } }
                        if feedBreakfast { feedRow(title: "Breakfast plan") { messageText = "Plan a balanced breakfast ~400 kcal with ~25g protein. 3 options." } }
                        if feedLunch { feedRow(title: "Lunch plan") { messageText = "Plan a balanced lunch ~500 kcal with ~30–35g protein. 3 options." } }
                        if feedDinner { feedRow(title: "Dinner plan") { messageText = "Plan a balanced dinner ~550 kcal with ~35–40g protein. 3 options." } }
                        if feedProteinSnacks { feedRow(title: "High‑protein snacks") { messageText = "List 6 high‑protein snacks under 250 calories." } }
                    }
                }
                .padding(.top, 4)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(.orange)
                    Text("Coach Feed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 6)
                .padding(.horizontal)
            }
        }
    }

    // Compact row with trailing pill button
    private func feedRow(title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button("Plan", action: action)
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(.horizontal)
    }

    // Persist Coach Feed preferences
    private func loadFeedPrefs() {
        let d = UserDefaults.standard
        feedProteinByLunch = d.object(forKey: "feedProteinByLunch") as? Bool ?? true
        feedPrelogDinner = d.object(forKey: "feedPrelogDinner") as? Bool ?? true
        feedHydration = d.object(forKey: "feedHydration") as? Bool ?? false
        feedSteps = d.object(forKey: "feedSteps") as? Bool ?? false
        feedBreakfast = d.object(forKey: "feedBreakfast") as? Bool ?? false
        feedLunch = d.object(forKey: "feedLunch") as? Bool ?? false
        feedDinner = d.object(forKey: "feedDinner") as? Bool ?? false
        feedProteinSnacks = d.object(forKey: "feedProteinSnacks") as? Bool ?? false
    }

    private func saveFeedPrefs() {
        let d = UserDefaults.standard
        d.set(feedProteinByLunch, forKey: "feedProteinByLunch")
        d.set(feedPrelogDinner, forKey: "feedPrelogDinner")
        d.set(feedHydration, forKey: "feedHydration")
        d.set(feedSteps, forKey: "feedSteps")
        d.set(feedBreakfast, forKey: "feedBreakfast")
        d.set(feedLunch, forKey: "feedLunch")
        d.set(feedDinner, forKey: "feedDinner")
        d.set(feedProteinSnacks, forKey: "feedProteinSnacks")
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
        
        switch subscriptionManager.currentTier {
        case .basic:
            welcomeText = "Hi! I’m your Coach. I help with simple, safe nutrition guidance: quick wins, meal ideas, and gentle reminders. Free users get a 7‑day trial of Coach. Upgrade to unlock full access. Tap the bell to set nudges, or ask me anything about food and macros."
        case .pro:
            welcomeText = "Welcome to Coach. I give practical nutrition help: quick wins, meal planning, and habit nudges (daily/evening/weekly). Tap the bell to set times, or ask me anything about meals and macros."
        case .elite:
            welcomeText = "Welcome to Coach (Elite). I can tailor guidance to your goals and macros. Set your nudges with the bell, enable the leaf for Nutrition mode, and ask for meal plans or macro tweaks."
        }
        
        let intro = [welcomeText, "\n\nAbout Coach:\n- Educational only; not medical advice\n- Nudges: Daily, Evening, Weekly, Protein by Lunch, Pre‑log Dinner\n- Configure via the bell icon in the top‑right\n- Ask ‘What can Coach do?’ to learn more"].joined()
        let welcomeMessage = ChatMessage(
            text: intro,
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
        
        // Build adapter context if Nutrition mode is enabled
        var contextSummary: String? = nil
        // Prefer Apple model with adapter/context
        let historyStrings: [String] = messages.suffix(8).map { $0.isUser ? "user: \($0.text)" : "assistant: \($0.text)" }
        AIChatService.shared.chat(userMessage: currentMessage, context: contextSummary, history: historyStrings, temperature: 0.6) { result in
            DispatchQueue.main.async {
                isTyping = false
                
                let responseText: String
                switch result {
                case .success(let aiResponse):
                    responseText = aiResponse
                    // Record successful chat usage or credit consumption
                    subscriptionManager.recordChatRequest()
                case .failure(let error):
                    if (error as? ModerationError) != nil {
                        responseText = "I can’t help with that request. Please rephrase to avoid disallowed content (violence, hate, sexual content with minors, self‑harm, illegal activity, or medical diagnosis/treatment)."
                    } else {
                        print("⚠️ [ChatView] AI API failed, using mock: \(error)")
                        // Fall back to enhanced mock responses
                        responseText = generateMockResponse(for: currentMessage)
                    }
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

