import SwiftUI
import SwiftData

struct EditMacroEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var macroEntryStore: MacroEntryStore
    @StateObject private var themeManager = ThemeManager.shared
    
    let entry: MacroEntry
    
    @State private var foodName: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showDeleteConfirmation: Bool = false
    
    // MARK: - Serving Size State
    @State private var servingSize: Double
    @State private var servingSizeType: ServingSizeType
    @State private var baseServingSize: Double
    @State private var baseServingSizeType: ServingSizeType
    
    init(entry: MacroEntry, macroEntryStore: MacroEntryStore) {
        self.entry = entry
        self.macroEntryStore = macroEntryStore
        
        // Initialize state variables with current entry values
        _foodName = State(initialValue: entry.foodName)
        _calories = State(initialValue: String(entry.calories))
        _protein = State(initialValue: String(entry.protein))
        _carbs = State(initialValue: String(entry.carbs))
        _fat = State(initialValue: String(entry.fats))
        
        // Initialize serving size state
        _servingSize = State(initialValue: entry.servingSize)
        _servingSizeType = State(initialValue: entry.servingSizeType)
        _baseServingSize = State(initialValue: entry.baseServingSize)
        _baseServingSizeType = State(initialValue: entry.baseServingSizeType)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo section (if available)
                    if let imageData = entry.imageData,
                       let image = UIImage(data: imageData) {
                        VStack(spacing: 12) {
                            Text("Food Photo")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Warning message about AI accuracy
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("AI Detection Notice")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        
                        Text("The AI may have incorrectly identified the nutrition values. Please review and correct any inaccurate information below.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Nutrition data powered by Spoonacular API")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Edit form
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Text("Food Information")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            CustomTextField(
                                title: "Food Name",
                                text: $foodName,
                                placeholder: "e.g., Chicken Sandwich"
                            )
                        }
                        
                        VStack(spacing: 12) {
                            Text("Nutritional Information")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                CustomTextField(
                                    title: "Calories",
                                    text: $calories,
                                    placeholder: "e.g., 350",
                                    keyboardType: .numberPad
                                )
                                
                                CustomTextField(
                                    title: "Protein (g)",
                                    text: $protein,
                                    placeholder: "e.g., 25",
                                    keyboardType: .decimalPad
                                )
                                
                                CustomTextField(
                                    title: "Carbs (g)",
                                    text: $carbs,
                                    placeholder: "e.g., 30",
                                    keyboardType: .decimalPad
                                )
                                
                                CustomTextField(
                                    title: "Fat (g)",
                                    text: $fat,
                                    placeholder: "e.g., 15",
                                    keyboardType: .decimalPad
                                )
                            }
                        }
                        
                        // MARK: - Serving Size Section
                        VStack(spacing: 12) {
                            Text("Serving Size")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ServingSizeSelector(
                                servingSize: $servingSize,
                                servingSizeType: $servingSizeType
                            )
                            
                            // Show adjusted nutrition based on serving size
                            if !calories.isEmpty && servingSize != 1.0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Adjusted Nutrition (\(servingSizeDisplay))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Calories")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(adjustedCalories)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Protein")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(adjustedProtein)g")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Carbs")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(adjustedCarbs)g")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Fat")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(adjustedFat)g")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Quick fix suggestions for common foods
                        VStack(spacing: 12) {
                            Text("Quick Fix Suggestions")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                QuickFixButton(
                                    title: "Chicken Sandwich",
                                    calories: "420",
                                    protein: "35",
                                    carbs: "32",
                                    fat: "18"
                                ) { calories, protein, carbs, fat in
                                    self.calories = calories
                                    self.protein = protein
                                    self.carbs = carbs
                                    self.fat = fat
                                }
                                
                                QuickFixButton(
                                    title: "Chicken Breast (6oz)",
                                    calories: "280",
                                    protein: "52",
                                    carbs: "0",
                                    fat: "6"
                                ) { calories, protein, carbs, fat in
                                    self.calories = calories
                                    self.protein = protein
                                    self.carbs = carbs
                                    self.fat = fat
                                }
                                
                                QuickFixButton(
                                    title: "Turkey Sandwich",
                                    calories: "380",
                                    protein: "28",
                                    carbs: "35",
                                    fat: "14"
                                ) { calories, protein, carbs, fat in
                                    self.calories = calories
                                    self.protein = protein
                                    self.carbs = carbs
                                    self.fat = fat
                                }
                                
                                QuickFixButton(
                                    title: "Burger (1/4 lb)",
                                    calories: "540",
                                    protein: "32",
                                    carbs: "38",
                                    fat: "28"
                                ) { calories, protein, carbs, fat in
                                    self.calories = calories
                                    self.protein = protein
                                    self.carbs = carbs
                                    self.fat = fat
                                }
                            }
                            
                            Text("Tap a suggestion to auto-fill typical values for that food")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: saveChanges) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text(isSaving ? "Saving..." : "Save Changes")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.primaryColor)
                                .cornerRadius(12)
                            }
                            .disabled(isSaving || !isValidInput)
                            
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Entry")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Validation Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Delete Entry", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this macro entry? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValidInput: Bool {
        !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Int(calories) != nil && Int(calories) ?? 0 >= 0 &&
        Int(protein) != nil && Int(protein) ?? 0 >= 0 &&
        Int(carbs) != nil && Int(carbs) ?? 0 >= 0 &&
        Int(fat) != nil && Int(fat) ?? 0 >= 0
    }
    
    // MARK: - Serving Size Computed Properties
    
    private var servingSizeDisplay: String {
        if servingSize == 1.0 && servingSizeType == .whole {
            return "1 whole"
        } else if servingSize == 1.0 {
            return "1 \(servingSizeType.displayName)"
        } else {
            return "\(String(format: "%.1f", servingSize)) \(servingSizeType.displayName)"
        }
    }
    
    private var adjustedCalories: Int {
        let baseCalories = Int(calories) ?? 0
        return Int(Double(baseCalories) * servingSize)
    }
    
    private var adjustedProtein: Int {
        let baseProtein = Int(protein) ?? 0
        return Int(Double(baseProtein) * servingSize)
    }
    
    private var adjustedCarbs: Int {
        let baseCarbs = Int(carbs) ?? 0
        return Int(Double(baseCarbs) * servingSize)
    }
    
    private var adjustedFat: Int {
        let baseFat = Int(fat) ?? 0
        return Int(Double(baseFat) * servingSize)
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        guard isValidInput else {
            alertMessage = "Please fill in all fields with valid positive numbers."
            showAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            // Update the entry properties
            entry.foodName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.calories = adjustedCalories
            entry.protein = adjustedProtein
            entry.carbs = adjustedCarbs
            entry.fats = adjustedFat
            
            // Update serving size properties
            entry.servingSize = servingSize
            entry.servingSizeType = servingSizeType
            entry.baseServingSize = baseServingSize
            entry.baseServingSizeType = baseServingSizeType
            
            // Save the changes
            await macroEntryStore.updateEntry(entry)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
    
    private func deleteEntry() {
        Task {
            await macroEntryStore.deleteEntry(entry)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Quick Fix Button

struct QuickFixButton: View {
    let title: String
    let calories: String
    let protein: String
    let carbs: String
    let fat: String
    let action: (String, String, String, String) -> Void
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: {
            action(calories, protein, carbs, fat)
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("\(calories) cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
            .background(themeManager.primaryColor.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(themeManager.primaryColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let sampleEntry = MacroEntry(
        name: "Chicken Sandwich",
        calories: 1, // Wrong value to demonstrate editing
        protein: 1,  // Wrong value
        carbs: 30,
        fats: 0      // Wrong value
    )
    
    let container = try! ModelContainer(for: MacroEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = MacroEntryStore(modelContext: container.mainContext)
    
    EditMacroEntryView(entry: sampleEntry, macroEntryStore: store)
} 