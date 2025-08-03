import SwiftUI
import SwiftData

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entryStore: MacroEntryStore
    
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var servingAmount = "1"
    @State private var servingType = "whole"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Food Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FOOD INFORMATION")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            TextField("Food Name (e.g., Chicken Breast)", text: $foodName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: { /* Search */ }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Nutritional Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NUTRITIONAL INFORMATION")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 8) {
                            TextField("Calories", text: $calories)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            TextField("Protein (g)", text: $protein)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            TextField("Carbs (g)", text: $carbs)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                            
                            TextField("Fat (g)", text: $fats)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    // Serving Size
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SERVING SIZE")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: "bag")
                                .foregroundColor(.blue)
                            Text("Serving Size")
                                .font(.headline)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Amount")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("1", text: $servingAmount)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Type")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(servingType)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Selected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(servingAmount) \(servingType)")
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Quick Select
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Select")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach(["0.2", "0.5", "0.8", "1.0", "1.2", "1.5", "2.0", "2.5", "3.0"], id: \.self) { amount in
                                    Button(action: { servingAmount = amount }) {
                                        Text(amount)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(servingAmount == amount ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(servingAmount == amount ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let caloriesValue = Double(calories),
              let proteinValue = Double(protein),
              let carbsValue = Double(carbs),
              let fatsValue = Double(fats),
              let amountValue = Double(servingAmount) else { return }
        
        let entry = MacroEntry(
            name: foodName.isEmpty ? "Manual Entry" : foodName,
            calories: Int(caloriesValue * amountValue),
            protein: Int(proteinValue * amountValue),
            carbs: Int(carbsValue * amountValue),
            fats: Int(fatsValue * amountValue),
            source: .manual
        )
        
        Task { @MainActor in
            await entryStore.addEntry(entry)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MacroEntry.self, Recipe.self, NutritionCacheEntry.self, configurations: config)
    ManualEntryView(entryStore: MacroEntryStore(modelContext: container.mainContext))
} 