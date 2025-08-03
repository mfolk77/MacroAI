import SwiftUI
import SwiftData

struct FastFoodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var macroEntryStore: MacroEntryStore
    @ObservedObject var macroAIManager: MacroAIManager
    
    @State private var searchText = ""
    @State private var selectedBrand: String? = nil
    @State private var selectedCategory: FastFoodCategory? = nil
    @State private var showingBrandPicker = false
    @State private var showingCategoryPicker = false
    
    private let fastFoodDB = FastFoodDatabase.shared
    
    var filteredItems: [FastFoodItem] {
        var items = fastFoodDB.fastFoodItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = fastFoodDB.searchFastFood(query: searchText)
        }
        
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search fast food...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Filter Buttons
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
                
                // Results List
                List {
                    ForEach(filteredItems) { item in
                        FastFoodItemRow(item: item) {
                            addFastFoodItem(item)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Fast Food")
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
    
    private func addFastFoodItem(_ item: FastFoodItem) {
        Task { @MainActor in
            let _ = NutritionMacros(
                calories: Double(item.calories),
                protein: Double(item.protein),
                carbs: Double(item.carbs),
                fat: Double(item.fat)
            )
            
            let _ = await macroEntryStore.addEntry(
                foodName: "\(item.brand) - \(item.name)",
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fats: item.fat,
                servingSize: 1.0,
                servingSizeType: .whole,
                baseServingSize: 1.0,
                baseServingSizeType: .whole
            )
            
            print("✅ [FastFoodSelectionView] Added fast food item: \(item.brand) - \(item.name)")
            dismiss()
        }
    }
}

#Preview {
    FastFoodSelectionView(
        macroEntryStore: MacroEntryStore(modelContext: try! ModelContainer(for: MacroEntry.self).mainContext),
        macroAIManager: MacroAIManager(
            foodVision: MockFoodVisionService(),
            nutrition: MockNutritionService(),
            barcode: BarcodeService(nutritionService: MockNutritionService())
        )
    )
}
