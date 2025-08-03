import SwiftUI
import SwiftData

struct SmartFoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var macroEntryStore: MacroEntryStore
    @ObservedObject var macroAIManager: MacroAIManager
    
    // Manual Entry Bindings
    @Binding var foodName: String
    @Binding var calories: String
    @Binding var protein: String
    @Binding var carbs: String
    @Binding var fat: String
    @Binding var isLoadingNutrition: Bool
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var showingFastFoodResults = false
    @State private var showingGeneralFoodResults = false
    
    private let fastFoodDB = FastFoodDatabase.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search food items...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchText) { _, newValue in
                                performSearch(query: newValue)
                            }
                    }
                    
                    // Search Tips
                    VStack(alignment: .leading, spacing: 4) {
                        Text("💡 Search Tips:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("• Try: 'Del Taco green burrito', 'McDonald's Big Mac'")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("• Or: 'chicken sandwich', 'pizza slice', 'french fries'")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Search Results
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else if !searchResults.isEmpty {
                    List {
                        ForEach(searchResults) { result in
                            SearchResultRow(result: result) {
                                addFoodItem(result)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try different keywords or check spelling")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Initial State
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        VStack(spacing: 8) {
                            Text("Smart Food Search")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Search for fast food, restaurant items, or general foods")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Quick Search Suggestions
                        VStack(spacing: 12) {
                            Text("Popular Searches:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(popularSearches, id: \.self) { search in
                                    Button(search) {
                                        searchText = search
                                        performSearch(query: search)
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private let popularSearches = [
        "Del Taco green burrito",
        "McDonald's Big Mac",
        "Taco Bell Crunchy Taco",
        "Subway turkey sandwich",
        "KFC fried chicken",
        "Pizza Hut pepperoni",
        "Chipotle burrito bowl",
        "Chick-fil-A sandwich"
    ]
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Search fast food database first
        let fastFoodResults = fastFoodDB.searchFastFood(query: query)
        
        // Convert to SearchResult format
        var results: [SearchResult] = []
        
        for item in fastFoodResults {
            results.append(SearchResult(
                id: item.id,
                name: "\(item.brand) - \(item.name)",
                brand: item.brand,
                category: item.category.rawValue,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                servingSize: item.servingSize,
                type: .fastFood,
                confidence: 0.95
            ))
        }
        
        // If we have fast food results, show them prominently
        if !results.isEmpty {
            searchResults = results
            isSearching = false
            return
        }
        
        // If no fast food results, search general food database
        // This would integrate with your existing nutrition service
        searchGeneralFood(query: query) { generalResults in
            DispatchQueue.main.async {
                self.searchResults = results + generalResults
                self.isSearching = false
            }
        }
    }
    
    private func searchGeneralFood(query: String, completion: @escaping ([SearchResult]) -> Void) {
        // This would integrate with your existing nutrition service
        // For now, we'll create some generic results
        let genericResults = [
            SearchResult(
                id: UUID(),
                name: query.capitalized,
                brand: "Generic",
                category: "Food",
                calories: 250,
                protein: 10,
                carbs: 30,
                fat: 8,
                servingSize: "1 serving",
                type: .general,
                confidence: 0.7
            )
        ]
        
        completion(genericResults)
    }
    
    private func addFoodItem(_ result: SearchResult) {
        // Populate the manual entry form
        foodName = result.name
        calories = String(result.calories)
        protein = String(result.protein)
        carbs = String(result.carbs)
        fat = String(result.fat)
        
        print("✅ [SmartFoodSearchView] Populated manual entry form with: \(result.name)")
        dismiss()
    }
}

struct SearchResult: Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let category: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let servingSize: String
    let type: SearchResultType
    let confidence: Double
}

enum SearchResultType {
    case fastFood
    case general
}

struct SearchResultRow: View {
    let result: SearchResult
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Type Icon
            Image(systemName: result.type == .fastFood ? "building.2" : "leaf")
                .foregroundColor(result.type == .fastFood ? .orange : .green)
                .font(.title2)
                .frame(width: 30)
            
            // Main Content
            VStack(alignment: .leading, spacing: 8) {
                // Item Name - Cleaner layout
                Text(result.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Brand and Category - Better spacing
                HStack(spacing: 6) {
                    Text(result.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if result.brand != "Generic" {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(result.category)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Serving Size - Smaller, less prominent
                Text(result.servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Nutrition Info - Right aligned
            VStack(alignment: .trailing, spacing: 8) {
                // Calories - More prominent
                Text("\(result.calories) cal")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                // Macros - Stacked vertically for clarity
                VStack(spacing: 4) {
                    MacroChip(label: "P", value: String(result.protein), color: .blue, progress: 0.0)
                    MacroChip(label: "C", value: String(result.carbs), color: .green, progress: 0.0)
                    MacroChip(label: "F", value: String(result.fat), color: .red, progress: 0.0)
                }
                
                // Confidence (for general foods) - Smaller
                if result.type == .general {
                    Text("Est. \(Int(result.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Add Button - Larger touch target
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MacroEntry.self, Recipe.self, NutritionCacheEntry.self, configurations: config)
    SmartFoodSearchView(
        macroEntryStore: MacroEntryStore(modelContext: container.mainContext),
        macroAIManager: MacroAIManager(
            foodVision: MockFoodVisionService(),
            nutrition: MockNutritionService(),
            barcode: BarcodeService(nutritionService: MockNutritionService())
        ),
        foodName: .constant(""),
        calories: .constant(""),
        protein: .constant(""),
        carbs: .constant(""),
        fat: .constant(""),
        isLoadingNutrition: .constant(false)
    )
} 
 