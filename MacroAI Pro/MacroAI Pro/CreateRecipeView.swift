// CreateRecipeView.swift
// Manual recipe creation and editing interface
import SwiftUI
import PhotosUI
import SwiftData

struct CreateRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recipeManager: RecipeManager
    
    // Recipe Data
    @State private var recipeName = ""
    @State private var servings = 1
    @State private var prepTime: Int?
    @State private var cookTime: Int?
    @State private var ingredients: [String] = [""]
    @State private var instructions: [String] = [""]
    @State private var notes = ""
    @State private var tags: [String] = []
    @State private var currentTag = ""
    
    // Nutrition Data
    @State private var calories = 0
    @State private var protein = 0
    @State private var carbs = 0
    @State private var fats = 0
    
    // Image Handling
    @State private var selectedImage: PhotosPickerItem?
    @State private var recipeImage: UIImage?
    
    // UI State
    @State private var isSaving = false
    @State private var isAnalyzing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingPhotoPicker = false
    
    // Editing Mode
    private var editingRecipe: Recipe?
    private var isEditing: Bool { editingRecipe != nil }
    
    init(recipeManager: RecipeManager, editingRecipe: Recipe? = nil) {
        self._recipeManager = StateObject(wrappedValue: recipeManager)
        self.editingRecipe = editingRecipe
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Image Section
                    imageSection
                    
                    // Basic Info
                    basicInfoSection
                    
                    // Nutrition Section
                    nutritionSection
                    
                    // Ingredients Section
                    ingredientsSection
                    
                    // Instructions Section
                    instructionsSection
                    
                    // Tags Section
                    tagsSection
                    
                    // Notes Section
                    notesSection
                    
                    // Save Button
                    saveButton
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "Create Recipe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let recipe = editingRecipe {
                    loadRecipeData(recipe)
                }
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedImage, matching: .images)
        .onChange(of: selectedImage) { _, newValue in
            loadSelectedImage()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: isEditing ? "pencil.circle.fill" : "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text(isEditing ? "Edit Your Recipe" : "Create Your Recipe")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(isEditing ? "Update your recipe details" : "Add a new recipe to your collection")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recipe Photo")
                .font(.headline)
            
            HStack {
                // Image Display
                Group {
                    if let image = recipeImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Text("No Photo")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button("Add Photo") {
                        showingPhotoPicker = true
                    }
                    .buttonStyle(.bordered)
                    
                    if recipeImage != nil {
                        Button("Remove") {
                            recipeImage = nil
                            selectedImage = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Recipe Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe Name *")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("e.g., Chicken Stir Fry", text: $recipeName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Servings
                VStack(alignment: .leading, spacing: 4) {
                    Text("Number of Servings *")
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
                
                // Timing
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prep Time (min)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("15", value: $prepTime, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cook Time (min)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("30", value: $cookTime, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Nutrition Section
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nutrition Per Serving")
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
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    NutritionField(title: "Calories", value: $calories, color: .orange, icon: "flame")
                    NutritionField(title: "Protein (g)", value: $protein, color: .blue, icon: "p.circle")
                }
                
                HStack(spacing: 16) {
                    NutritionField(title: "Carbs (g)", value: $carbs, color: .green, icon: "c.circle")
                    NutritionField(title: "Fats (g)", value: $fats, color: .purple, icon: "f.circle")
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
                
                // TEMPORARILY DISABLED - Recipe analyze feature returning zeros
                /*
                Button(action: analyzeRecipe) {
                    HStack(spacing: 6) {
                        if isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze Recipe")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
                .disabled(isAnalyzing || cleanIngredients.isEmpty)
                */
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
                
                HStack {
                    Button("Add Ingredient") {
                        ingredients.append("")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    // TEMPORARILY DISABLED - Recipe analyze feature
                    /*
                    if !cleanIngredients.isEmpty {
                        Text("💡 Add all ingredients, then tap 'Analyze Recipe' to auto-calculate nutrition")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.trailing)
                    }
                    */
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
            Text("Instructions")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(0..<instructions.count, id: \.self) { index in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            .frame(width: 20, alignment: .leading)
                        
                        VStack {
                            TextField("Step \(index + 1)", text: $instructions[index], axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                            
                            if instructions.count > 1 {
                                HStack {
                                    Spacer()
                                    Button("Remove Step") {
                                        instructions.remove(at: index)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
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
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tags")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Add Tag Field
                HStack {
                    TextField("Add tag (e.g., vegetarian, quick)", text: $currentTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addTag()
                        }
                    
                    Button("Add") {
                        addTag()
                    }
                    .buttonStyle(.bordered)
                    .disabled(currentTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Tags Display
                if !tags.isEmpty {
                    FlowLayout(items: tags) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                    }
                }
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
            
            TextField("Additional notes, tips, or variations...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(4...8)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await saveRecipe()
                }
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: isEditing ? "checkmark" : "plus")
                    }
                    
                    Text(isSaving ? "Saving Recipe..." : (isEditing ? "Update Recipe" : "Save Recipe"))
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.accentColor : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!canSave || isSaving)
            
            if !canSave {
                Text("Please enter recipe name, servings, and nutrition values")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        servings > 0 &&
        calories >= 0 &&
        protein >= 0 &&
        carbs >= 0 &&
        fats >= 0
    }
    
    private var cleanIngredients: [String] {
        ingredients.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private var cleanInstructions: [String] {
        instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let tag = currentTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            currentTag = ""
        }
    }
    
    private func loadSelectedImage() {
        guard let selectedImage = selectedImage else { return }
        
        selectedImage.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.recipeImage = uiImage
                    }
                }
            case .failure(let error):
                print("Failed to load image: \(error)")
            }
        }
    }
    
    private func loadRecipeData(_ recipe: Recipe) {
        recipeName = recipe.name
        servings = recipe.servings
        prepTime = recipe.prepTimeMinutes
        cookTime = recipe.cookTimeMinutes
        ingredients = recipe.ingredients.isEmpty ? [""] : recipe.ingredients
        instructions = recipe.instructions.isEmpty ? [""] : recipe.instructions
        notes = recipe.notes ?? ""
        tags = recipe.tags
        
        calories = recipe.caloriesPerServing
        protein = recipe.proteinPerServing
        carbs = recipe.carbsPerServing
        fats = recipe.fatsPerServing
        
        if let imageData = recipe.imageData {
            recipeImage = UIImage(data: imageData)
        }
    }
    
    private func analyzeRecipe() {
        guard !cleanIngredients.isEmpty else { return }
        
        let recipeTitleForAnalysis = recipeName.isEmpty ? "My Recipe" : recipeName
        
        isAnalyzing = true
        
        Task {
            do {
                print("🔬 [CreateRecipeView] Starting recipe analysis for: \(recipeTitleForAnalysis)")
                print("🔬 [CreateRecipeView] Ingredients: \(cleanIngredients)")
                
                let result = try await SpoonacularRecipeAPI.analyzeRecipe(
                    ingredients: cleanIngredients,
                    instructions: cleanInstructions
                )
                
                await MainActor.run {
                    // Update nutrition values with per-serving amounts
                    calories = Int(result.calories / Double(servings))
                    protein = Int(result.protein / Double(servings))
                    carbs = Int(result.carbs / Double(servings))
                    fats = Int(result.fat / Double(servings))
                    
                    isAnalyzing = false
                    
                    print("✅ [CreateRecipeView] Analysis complete: \(calories)cal, \(protein)g protein, \(carbs)g carbs, \(fats)g fat per serving")
                }
                
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    
                    if let analysisError = error as? RecipeAnalysisError {
                        errorMessage = analysisError.localizedDescription
                    } else {
                        errorMessage = "Recipe analysis failed: \(error.localizedDescription)"
                    }
                    
                    showingError = true
                    print("❌ [CreateRecipeView] Analysis failed: \(error)")
                }
            }
        }
    }
    
    private func saveRecipe() async {
        guard canSave else { return }
        
        isSaving = true
        
        let imageData = recipeImage?.jpegData(compressionQuality: 0.7)
                
                if let existingRecipe = editingRecipe {
                    // Update existing recipe
                    existingRecipe.name = recipeName
                    existingRecipe.servings = servings
                    existingRecipe.prepTimeMinutes = prepTime
                    existingRecipe.cookTimeMinutes = cookTime
                    existingRecipe.ingredients = cleanIngredients
                    existingRecipe.instructions = cleanInstructions
                    existingRecipe.notes = notes.isEmpty ? nil : notes
                    existingRecipe.tags = tags
                    existingRecipe.caloriesPerServing = calories
                    existingRecipe.proteinPerServing = protein
                    existingRecipe.carbsPerServing = carbs
                    existingRecipe.fatsPerServing = fats
                    existingRecipe.imageData = imageData
                    
                    await recipeManager.updateRecipe(existingRecipe)
                } else {
                    // Create new recipe
                    let recipe = Recipe(
                        name: recipeName,
                        ingredients: cleanIngredients,
                        instructions: cleanInstructions,
                        servings: servings,
                        prepTimeMinutes: prepTime,
                        cookTimeMinutes: cookTime,
                        caloriesPerServing: calories,
                        proteinPerServing: protein,
                        carbsPerServing: carbs,
                        fatsPerServing: fats,
                        tags: tags,
                        notes: notes.isEmpty ? nil : notes,
                        imageData: imageData,
                        source: .userCreated
                    )
                    
                    let _ = await recipeManager.saveRecipe(recipe)
                }
                
                await MainActor.run {
                    dismiss()
                }
        }
    }

// MARK: - Supporting Views

struct NutritionField: View {
    let title: String
    @Binding var value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("0", value: $value, format: .number)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    let recipeManager = RecipeManager(modelContext: container.mainContext)
    
    CreateRecipeView(recipeManager: recipeManager)
}