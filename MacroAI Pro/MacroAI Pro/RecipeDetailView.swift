// RecipeDetailView.swift
// Detailed recipe view with editing and usage capabilities
import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recipeManager: RecipeManager
    @StateObject private var entryStore: MacroEntryStore
    @StateObject private var storeKit: StoreKitManager
    @State private var recipe: Recipe
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var isAddingToMacros = false
    @State private var isAnalyzing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(
        recipe: Recipe,
        recipeManager: RecipeManager,
        entryStore: MacroEntryStore,
        storeKit: StoreKitManager
    ) {
        self._recipe = State(initialValue: recipe)
        self._recipeManager = StateObject(wrappedValue: recipeManager)
        self._entryStore = StateObject(wrappedValue: entryStore)
        self._storeKit = StateObject(wrappedValue: storeKit)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recipe Header
                    recipeHeader
                    
                    // Nutrition Grid
                    nutritionGrid
                    
                    // Recipe Info
                    recipeInfoSection
                    
                    // Ingredients Section
                    if !recipe.ingredients.isEmpty {
                        ingredientsSection
                    }
                    
                    // Instructions Section
                    if !recipe.instructions.isEmpty {
                        instructionsSection
                    }
                    
                    // Notes Section
                    if let notes = recipe.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Recipe", systemImage: "pencil") {
                            showingEditSheet = true
                        }
                        
                        Button("Share Recipe", systemImage: "square.and.arrow.up") {
                            showingShareSheet = true
                        }
                        
                        Divider()
                        
                        Button("Delete Recipe", systemImage: "trash", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await recipeManager.deleteRecipe(recipe)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(recipe.name)'? This action cannot be undone.")
            }
            .alert("Recipe Manager", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            CreateRecipeView(recipeManager: recipeManager, editingRecipe: recipe)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
    }
    
    // MARK: - Recipe Header
    
    private var recipeHeader: some View {
        VStack(spacing: 16) {
            // Recipe Image or Icon
            Group {
                if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: recipe.source.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                        )
                }
            }
            
            // Recipe Title and Source
            VStack(spacing: 8) {
                Text(recipe.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Label(recipe.source.displayName, systemImage: recipe.source.icon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Recipe Stats
            HStack(spacing: 20) {
                StatItem(title: "Servings", value: "\(recipe.servings)")
                
                if let totalTime = recipe.totalTimeMinutes {
                    StatItem(title: "Total Time", value: "\(totalTime) min")
                }
                
                if recipe.useCount > 0 {
                    StatItem(title: "Used", value: "\(recipe.useCount) times")
                }
            }
        }
    }
    
    // MARK: - Nutrition Grid
    
    private var nutritionGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Per Serving")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                DetailedNutritionCard(
                    title: "Calories",
                    value: "\(recipe.caloriesPerServing)",
                    color: .orange,
                    icon: "flame"
                )
                
                DetailedNutritionCard(
                    title: "Protein",
                    value: "\(recipe.proteinPerServing)g",
                    color: .blue,
                    icon: "p.circle"
                )
                
                DetailedNutritionCard(
                    title: "Carbs",
                    value: "\(recipe.carbsPerServing)g",
                    color: .green,
                    icon: "c.circle"
                )
                
                DetailedNutritionCard(
                    title: "Fats",
                    value: "\(recipe.fatsPerServing)g",
                    color: .purple,
                    icon: "f.circle"
                )
            }
        }
    }
    
    // MARK: - Recipe Info Section
    
    private var recipeInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let prepTime = recipe.prepTimeMinutes {
                    InfoRow(title: "Prep Time", value: "\(prepTime) minutes")
                }
                
                if let cookTime = recipe.cookTimeMinutes {
                    InfoRow(title: "Cook Time", value: "\(cookTime) minutes")
                }
                
                InfoRow(title: "Total Calories", value: "\(recipe.totalCalories)")
                InfoRow(title: "Date Created", value: recipe.dateCreated.formatted(date: .abbreviated, time: .omitted))
                
                if let lastUsed = recipe.lastUsed {
                    InfoRow(title: "Last Used", value: lastUsed.formatted(date: .abbreviated, time: .omitted))
                }
                
                if !recipe.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FlowLayout(items: recipe.tags) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients (\(recipe.ingredients.count))")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    HStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                        
                        Text(ingredient)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions (\(recipe.instructions.count) steps)")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.accentColor))
                        
                        Text(instruction)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
            
            Text(notes)
                .font(.body)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Add to Macros Button
            Button(action: addToMacros) {
                HStack {
                    if isAddingToMacros {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text(isAddingToMacros ? "Adding to Macros..." : "Add to Today's Macros")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAddingToMacros)
            
            // TEMPORARILY DISABLED - Recipe analyze feature returning zeros
            // TODO: Fix recipe analyze feature in next update
            /*
            // Analyze Recipe Button (if has ingredients)
            if !recipe.ingredients.isEmpty {
                Button(action: analyzeRecipe) {
                    HStack(spacing: 8) {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.orange)
                        } else {
                            Image(systemName: recipe.source == .spoonacularAPI ? "arrow.clockwise" : "sparkles")
                                .font(.system(size: 16))
                        }
                        
                        Text(isAnalyzing ? "Analyzing Recipe..." : 
                             recipe.source == .spoonacularAPI ? "Re-analyze Recipe" : "Analyze Recipe with Spoonacular")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isAnalyzing)
            }
            */
            
            // Secondary Actions
            HStack(spacing: 16) {
                Button("Edit Recipe") {
                    showingEditSheet = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Share Recipe") {
                    showingShareSheet = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            
            // Attribution (if from Spoonacular)
            if recipe.source == .spoonacularAPI {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    
                    Text("Nutrition data powered by Spoonacular")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Actions
    
    private func addToMacros() {
        isAddingToMacros = true
        
        Task {
            let entry = MacroEntry(
                name: recipe.name,
                calories: recipe.caloriesPerServing,
                protein: recipe.proteinPerServing,
                carbs: recipe.carbsPerServing,
                fats: recipe.fatsPerServing,
                source: .recipe
            )
            
            _ = await entryStore.addEntry(entry)
            await recipeManager.markRecipeAsUsed(recipe)
            
            // Update local recipe data
            recipe.lastUsed = Date()
            recipe.useCount += 1
            
            await MainActor.run {
                alertMessage = "Added '\(recipe.name)' to today's macros"
                showingAlert = true
                isAddingToMacros = false
            }
        }
    }
    
    private func analyzeRecipe() {
        guard !recipe.ingredients.isEmpty else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                print("🔬 [RecipeDetailView] Starting analysis for existing recipe: \(recipe.name)")
                print("🔬 [RecipeDetailView] Ingredients: \(recipe.ingredients)")
                
                let result = try await SpoonacularRecipeAPI.analyzeRecipe(
                    ingredients: recipe.ingredients,
                    instructions: recipe.instructions
                )
                
                await MainActor.run {
                    // Update recipe nutrition values with per-serving amounts
                    recipe.caloriesPerServing = Int(result.calories / Double(recipe.servings))
                    recipe.proteinPerServing = Int(result.protein / Double(recipe.servings))
                    recipe.carbsPerServing = Int(result.carbs / Double(recipe.servings))
                    recipe.fatsPerServing = Int(result.fat / Double(recipe.servings))
                    
                    // Update source to indicate it was analyzed (only if not already from Spoonacular)
                    if recipe.source != .spoonacularAPI {
                        recipe.source = .spoonacularAPI
                    }
                    
                    isAnalyzing = false
                    
                    // Save the updated recipe
                    Task {
                        await recipeManager.updateRecipe(recipe)
                        
                        await MainActor.run {
                            alertMessage = "✅ Recipe nutrition updated!\n\n📊 New values per serving:\n• \(recipe.caloriesPerServing) calories\n• \(recipe.proteinPerServing)g protein\n• \(recipe.carbsPerServing)g carbs\n• \(recipe.fatsPerServing)g fats"
                            showingAlert = true
                        }
                    }
                    
                    print("✅ [RecipeDetailView] Analysis complete: \(recipe.caloriesPerServing)cal, \(recipe.proteinPerServing)g protein, \(recipe.carbsPerServing)g carbs, \(recipe.fatsPerServing)g fat per serving")
                }
                
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    
                    if let analysisError = error as? RecipeAnalysisError {
                        alertMessage = "Analysis failed: \(analysisError.localizedDescription)"
                    } else {
                        alertMessage = "Recipe analysis failed: \(error.localizedDescription)"
                    }
                    
                    showingAlert = true
                    print("❌ [RecipeDetailView] Analysis failed: \(error)")
                }
            }
        }
    }
    
    private func createShareText() -> String {
        var shareText = "🍽️ \(recipe.name)\n\n"
        shareText += "📊 Nutrition per serving:\n"
        shareText += "• \(recipe.caloriesPerServing) calories\n"
        shareText += "• \(recipe.proteinPerServing)g protein\n"
        shareText += "• \(recipe.carbsPerServing)g carbs\n"
        shareText += "• \(recipe.fatsPerServing)g fats\n\n"
        
        if !recipe.ingredients.isEmpty {
            shareText += "🛒 Ingredients:\n"
            for ingredient in recipe.ingredients {
                shareText += "• \(ingredient)\n"
            }
            shareText += "\n"
        }
        
        if !recipe.instructions.isEmpty {
            shareText += "👨‍🍳 Instructions:\n"
            for (index, instruction) in recipe.instructions.enumerated() {
                shareText += "\(index + 1). \(instruction)\n"
            }
            shareText += "\n"
        }
        
        shareText += "Created with MacroAI 📱"
        return shareText
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct FlowLayout<T: Hashable, Content: View>: View {
    let items: [T]
    let content: (T) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { dimensions in
                        if (abs(width - dimensions.width) > geometry.size.width) {
                            width = 0
                            height -= dimensions.height
                        }
                        let result = width
                        if index == items.count - 1 {
                            width = 0
                        } else {
                            width -= dimensions.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { dimensions in
                        let result = height
                        if index == items.count - 1 {
                            height = 0
                        }
                        return result
                    })
            }
        }.background(viewHeightReader($totalHeight))
    }
    
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geometry -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geometry.size.height
            }
            return Color.clear
        }
    }
}

struct DetailedNutritionCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, MacroEntry.self, configurations: config)
    let recipeManager = RecipeManager(modelContext: container.mainContext)
    let entryStore = MacroEntryStore(modelContext: container.mainContext)
    let storeKit = StoreKitManager.shared
    
    RecipeDetailView(
        recipe: Recipe.sampleRecipes[0],
        recipeManager: recipeManager,
        entryStore: entryStore,
        storeKit: storeKit
    )
}
