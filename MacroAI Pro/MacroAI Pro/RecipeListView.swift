// RecipeListView.swift
// Main recipe management interface
import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recipeManager: RecipeManager
    @StateObject private var entryStore: MacroEntryStore
    @StateObject private var storeKit: StoreKitManager
    
    @State private var searchText = ""
    @State private var selectedSource: RecipeSource? = nil
    @State private var showingCreateRecipe = false
    @State private var showingRecipeAnalysis = false
    @State private var selectedRecipe: Recipe?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(modelContext: ModelContext, entryStore: MacroEntryStore, storeKit: StoreKitManager) {
        self._recipeManager = StateObject(wrappedValue: RecipeManager(modelContext: modelContext))
        self._entryStore = StateObject(wrappedValue: entryStore)
        self._storeKit = StateObject(wrappedValue: storeKit)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Recipe List
                if recipeManager.isLoading {
                    ProgressView("Loading recipes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRecipes.isEmpty {
                    emptyState
                } else {
                    recipeList
                }
            }
            .navigationTitle("My Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Recipe", systemImage: "plus") {
                            showingCreateRecipe = true
                        }
                        
                        // TEMPORARILY DISABLED - Recipe analyze feature returning zeros
                        /*
                        Button("Analyze Recipe", systemImage: "magnifyingglass") {
                            showingRecipeAnalysis = true
                        }
                        */
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes...")
            .task {
                await recipeManager.fetchRecipes()
            }
            .refreshable {
                await recipeManager.fetchRecipes()
            }
            .alert("Recipe Manager", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
        .sheet(isPresented: $showingCreateRecipe) {
            CreateRecipeView(recipeManager: recipeManager)
        }
        .sheet(isPresented: $showingRecipeAnalysis) {
            RecipeAnalysisView(recipeManager: recipeManager)
        }
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(
                recipe: recipe,
                recipeManager: recipeManager,
                entryStore: entryStore,
                storeKit: storeKit
            )
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Source Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedSource == nil,
                        action: { selectedSource = nil }
                    )
                    
                    ForEach(RecipeSource.allCases, id: \.self) { source in
                        FilterChip(
                            title: source.displayName,
                            icon: source.icon,
                            isSelected: selectedSource == source,
                            action: { selectedSource = source }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Recipe List
    
    private var recipeList: some View {
        List {
            // Popular Recipes Section
            if !searchText.isEmpty == false && selectedSource == nil {
                let popularRecipes = recipeManager.getPopularRecipes(limit: 3)
                if !popularRecipes.isEmpty {
                    Section("Popular Recipes") {
                        ForEach(popularRecipes, id: \.id) { recipe in
                            RecipeRowView(
                                recipe: recipe,
                                onTap: { selectedRecipe = recipe },
                                onUse: { await useRecipe(recipe) },
                                onDelete: { await deleteRecipe(recipe) }
                            )
                        }
                    }
                }
            }
            
            // All Recipes
            Section(searchText.isEmpty ? "All Recipes" : "Search Results") {
                ForEach(filteredRecipes, id: \.id) { recipe in
                    RecipeRowView(
                        recipe: recipe,
                        onTap: { selectedRecipe = recipe },
                        onUse: { await useRecipe(recipe) },
                        onDelete: { await deleteRecipe(recipe) }
                    )
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Recipes Yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Create your first recipe or analyze ingredients to get nutrition data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                Button("Create Recipe") {
                    showingCreateRecipe = true
                }
                .buttonStyle(.borderedProminent)
                
                // TEMPORARILY DISABLED - Recipe analyze feature returning zeros
                /*
                Button("Analyze Recipe") {
                    showingRecipeAnalysis = true
                }
                .buttonStyle(.bordered)
                */
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredRecipes: [Recipe] {
        var recipes = recipeManager.searchRecipes(query: searchText)
        
        if let source = selectedSource {
            recipes = recipes.filter { $0.source == source }
        }
        
        return recipes
    }
    
    // MARK: - Actions
    
    private func useRecipe(_ recipe: Recipe) async {
        // Add recipe to today's macros
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
        
        alertMessage = "Added '\(recipe.name)' to today's macros"
        showingAlert = true
    }
    
    private func deleteRecipe(_ recipe: Recipe) async {
        await recipeManager.deleteRecipe(recipe)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    let onTap: () -> Void
    let onUse: () async -> Void
    let onDelete: () async -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe Image or Icon
            recipeImage
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Label("\(recipe.caloriesPerServing)", systemImage: "flame")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("\(recipe.proteinPerServing)g", systemImage: "p.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Label("\(recipe.carbsPerServing)g", systemImage: "c.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("\(recipe.fatsPerServing)g", systemImage: "f.circle")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Label(recipe.source.displayName, systemImage: recipe.source.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if recipe.useCount > 0 {
                        Text("Used \(recipe.useCount) times")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 8) {
                Button("Use") {
                    Task {
                        isLoading = true
                        await onUse()
                        isLoading = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                
                Menu {
                    Button("View Details") { onTap() }
                    Button("Delete", role: .destructive) {
                        Task { await onDelete() }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
    
    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: recipe.source.icon)
                            .foregroundColor(.accentColor)
                    )
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, MacroEntry.self, NutritionCacheEntry.self, configurations: config)
    let entryStore = MacroEntryStore(modelContext: container.mainContext)
    let storeKit = StoreKitManager.shared
    
    return RecipeListView(modelContext: container.mainContext, entryStore: entryStore, storeKit: storeKit)
} 