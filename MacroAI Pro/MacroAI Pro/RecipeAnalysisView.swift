// RecipeAnalysisView.swift
// Recipe analysis with Spoonacular API integration
import SwiftUI
import SwiftData

struct RecipeAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recipeManager: RecipeManager
    
    @State private var recipeName = ""
    @State private var servings = 1
    @State private var ingredients: [String] = [""]
    @State private var instructions: [String] = [""]
    @State private var notes = ""
    
    @State private var isAnalyzing = false
    @State private var showingResult = false
    @State private var analyzedRecipe: Recipe?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(recipeManager: RecipeManager) {
        self._recipeManager = StateObject(wrappedValue: recipeManager)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Recipe Details
                    recipeDetailsSection
                    
                    // Ingredients Section
                    ingredientsSection
                    
                    // Instructions Section (Optional)
                    instructionsSection
                    
                    // Notes Section
                    notesSection
                    
                    // Analyze Button
                    analyzeButton
                    
                    // Spoonacular Attribution
                    attributionSection
                }
                .padding()
            }
            .navigationTitle("Analyze Recipe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Analysis Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingResult) {
            if let recipe = analyzedRecipe {
                RecipeResultView(recipe: recipe, onSave: {
                    dismiss()
                })
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Recipe Nutrition Analysis")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your recipe ingredients and we'll analyze the nutrition using Spoonacular's database")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Recipe Details Section
    
    private var recipeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Recipe Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Birds Eye Vegetables & Rice", text: $recipeName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Servings
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of Servings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Button("-") {
                            if servings > 1 { servings -= 1 }
                        }
                        .buttonStyle(.bordered)
                        .disabled(servings <= 1)
                        
                        Text("\(servings)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .frame(minWidth: 40)
                        
                        Button("+") {
                            if servings < 20 { servings += 1 }
                        }
                        .buttonStyle(.bordered)
                        .disabled(servings >= 20)
                        
                        Spacer()
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
            HStack {
                Text("Ingredients")
                    .font(.headline)
                
                Spacer()
                
                Text("Required")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
            
            VStack(spacing: 8) {
                ForEach(0..<ingredients.count, id: \.self) { index in
                    HStack {
                        TextField("e.g., 1 cup brown rice", text: $ingredients[index])
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if ingredients.count > 1 {
                            Button("Remove") {
                                ingredients.remove(at: index)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Button("Add Ingredient") {
                    ingredients.append("")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Instructions")
                    .font(.headline)
                
                Spacer()
                
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            VStack(spacing: 8) {
                ForEach(0..<instructions.count, id: \.self) { index in
                    HStack {
                        TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                        
                        if instructions.count > 1 {
                            Button("Remove") {
                                instructions.remove(at: index)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Button("Add Step") {
                    instructions.append("")
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
            
            TextField("Additional notes about this recipe...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Analyze Button
    
    private var analyzeButton: some View {
        VStack(spacing: 12) {
            Button(action: analyzeRecipe) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Text(isAnalyzing ? "Analyzing Recipe..." : "Analyze Nutrition")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canAnalyze ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canAnalyze || isAnalyzing)
            
            if !canAnalyze {
                Text("Please enter a recipe name and at least one ingredient")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Attribution Section
    
    private var attributionSection: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                
                Text("Nutrition data powered by Spoonacular")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canAnalyze: Bool {
        !recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.isEmpty
    }
    
    private var cleanIngredients: [String] {
        ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private var cleanInstructions: [String] {
        instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Actions
    
    private func analyzeRecipe() {
        guard canAnalyze else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                let recipe = try await recipeManager.analyzeRecipe(
                    title: recipeName,
                    ingredients: cleanIngredients,
                    instructions: cleanInstructions,
                    servings: servings
                )
                
                // Add notes if provided
                if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    recipe.notes = notes
                }
                
                await MainActor.run {
                    analyzedRecipe = recipe
                    showingResult = true
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isAnalyzing = false
                }
            }
        }
    }
}

// MARK: - Recipe Result View

struct RecipeResultView: View {
    let recipe: Recipe
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Success Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Analysis Complete!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Your recipe has been analyzed and saved")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Recipe Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recipe Summary")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Name:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(recipe.name)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Servings:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(recipe.servings)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Ingredients:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(recipe.ingredients.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Nutrition Per Serving
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition Per Serving")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            NutritionCard(
                                title: "Calories",
                                value: "\(recipe.caloriesPerServing)",
                                color: .orange
                            )
                            
                            NutritionCard(
                                title: "Protein",
                                value: "\(recipe.proteinPerServing)g",
                                color: .blue
                            )
                            
                            NutritionCard(
                                title: "Carbs",
                                value: "\(recipe.carbsPerServing)g",
                                color: .green
                            )
                            
                            NutritionCard(
                                title: "Fats",
                                value: "\(recipe.fatsPerServing)g",
                                color: .purple
                            )
                        }
                    }
                    
                    // Save Button
                    Button("Save Recipe") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    // Attribution
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("Nutrition data powered by Spoonacular")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                .padding()
            }
            .navigationTitle("Recipe Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// NutritionCard is already defined in RecipeDetailView.swift

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    let recipeManager = RecipeManager(modelContext: container.mainContext)
    
    RecipeAnalysisView(recipeManager: recipeManager)
}
