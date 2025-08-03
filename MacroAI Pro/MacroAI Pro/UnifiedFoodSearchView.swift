import SwiftUI
import SwiftData

struct UnifiedFoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var macroEntryStore: MacroEntryStore
    @ObservedObject var macroAIManager: MacroAIManager
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedTab = 0 // 0 = Search, 1 = Browse
    @State private var selectedBrand: String? = nil
    @State private var selectedCategory: FastFoodCategory? = nil
    @State private var showingBrandPicker = false
    @State private var showingCategoryPicker = false
    
    private let fastFoodDB = FastFoodDatabase.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Search Type", selection: $selectedTab) {
                    Text("Search").tag(0)
                    Text("Browse").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // Search Tab
                    searchTab
                } else {
                    // Browse Tab
                    browseTab
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingBrandPicker) {
            BrandPickerView(selectedBrand: $selectedBrand)
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(selectedCategory: $selectedCategory)
        }
    }
    
    // MARK: - Search Tab
    private var searchTab: some View {
        VStack(spacing: 0) {
            // Search Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search for food...", text: $searchText)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Quick Search Suggestions
                if searchText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popular Searches:")
                            .font(.headline)
                            .padding(.horizontal)
                        
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
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
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
                            Task { await addFoodItem(result) }
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
                        Text("Search for Food")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Find fast food, restaurant items, or general foods")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    // MARK: - Browse Tab
    private var browseTab: some View {
        VStack(spacing: 0) {
            // Filter Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Brand Filter
                    Button(action: {
                        showingBrandPicker = true
                    }) {
                        HStack {
                            Image(systemName: "building.2")
                            Text(selectedBrand ?? "All Brands")
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedBrand != nil ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedBrand != nil ? .white : .primary)
                        .cornerRadius(8)
                    }
                    
                    // Category Filter
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            Image(systemName: "tag")
                            Text(selectedCategory?.rawValue ?? "All Categories")
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory != nil ? Color.green : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory != nil ? .white : .primary)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Clear Filters
                    if selectedBrand != nil || selectedCategory != nil {
                        Button("Clear") {
                            selectedBrand = nil
                            selectedCategory = nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Browse Results
            List {
                ForEach(filteredBrowseItems) { item in
                    FastFoodItemRow(item: item) {
                        Task { await addFastFoodItem(item) }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // MARK: - Computed Properties
    private var filteredBrowseItems: [FastFoodItem] {
        var items = fastFoodDB.fastFoodItems
        
        // Filter by selected brand
        if let brand = selectedBrand {
            items = items.filter { $0.brand == brand }
        }
        
        // Filter by selected category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        return items
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
    
    // MARK: - Search Methods
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
                name: item.name, // Just use the item name, not brand - name
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
    
    // MARK: - Add Methods
    private func addFoodItem(_ result: SearchResult) async {
        // Create a new macro entry
        let newEntry = MacroEntry(
            timestamp: Date(),
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fats: result.fat
        )
        
        // Add to the store
        let _ = await macroEntryStore.addEntry(newEntry)
        
        print("✅ [UnifiedFoodSearchView] Added to daily macros: \(result.name)")
        dismiss()
    }
    
    private func addFastFoodItem(_ item: FastFoodItem) async {
        // Create a new macro entry
        let newEntry = MacroEntry(
            timestamp: Date(),
            name: "\(item.brand) \(item.name)", // Cleaner format without dash
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fats: item.fat
        )
        
        // Add to the store
        let _ = await macroEntryStore.addEntry(newEntry)
        
        print("✅ [UnifiedFoodSearchView] Added to daily macros: \(item.brand) \(item.name)")
        dismiss()
    }
}

// MARK: - Reusable Components
struct FastFoodItemRow: View {
    let item: FastFoodItem
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Food Icon
            Text(item.category.icon)
                .font(.title2)
                .frame(width: 30)
            
            // Main Content
            VStack(alignment: .leading, spacing: 8) {
                // Item Name - Cleaner layout
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Brand and Category - Better spacing
                HStack(spacing: 6) {
                    Text(item.brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Serving Size - Smaller, less prominent
                Text(item.servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Nutrition Info - Right aligned
            VStack(alignment: .trailing, spacing: 8) {
                // Calories - More prominent
                Text("\(item.calories) cal")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                // Macros - Stacked vertically for clarity
                VStack(spacing: 4) {
                    MacroChip(label: "P", value: String(item.protein), color: .blue, progress: 0.0)
                    MacroChip(label: "C", value: String(item.carbs), color: .green, progress: 0.0)
                    MacroChip(label: "F", value: String(item.fat), color: .red, progress: 0.0)
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

struct BrandPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBrand: String?
    
    private let brands = FastFoodDatabase.shared.getAllBrands()
    
    var body: some View {
        NavigationView {
            List {
                Button("All Brands") {
                    selectedBrand = nil
                    dismiss()
                }
                
                ForEach(brands, id: \.self) { brand in
                    Button(brand) {
                        selectedBrand = brand
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Brand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: FastFoodCategory?
    
    private let categories = FastFoodCategory.allCases
    
    var body: some View {
        NavigationView {
            List {
                Button("All Categories") {
                    selectedCategory = nil
                    dismiss()
                }
                
                ForEach(categories, id: \.self) { category in
                    Button("\(category.icon) \(category.rawValue)") {
                        selectedCategory = category
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UnifiedFoodSearchView(
        macroEntryStore: MacroEntryStore(modelContext: try! ModelContainer(for: MacroEntry.self).mainContext),
        macroAIManager: MacroAIManager(
            foodVision: MockFoodVisionService(),
            nutrition: MockNutritionService(),
            barcode: BarcodeService(nutritionService: MockNutritionService())
        )
    )
} 
 