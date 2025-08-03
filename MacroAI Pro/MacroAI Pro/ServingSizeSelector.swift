import SwiftUI

struct ServingSizeSelector: View {
    @Binding var servingSize: Double
    @Binding var servingSizeType: ServingSizeType
    
    // Common serving sizes for quick selection
    private let commonSizes: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.blue)
                Text("Serving Size")
                    .font(.headline)
                Spacer()
            }
            
            // Size and Type Selection
            HStack(spacing: 12) {
                // Size Input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("1.0", value: $servingSize, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        
                        // Type Picker
                        Picker("Type", selection: $servingSizeType) {
                            ForEach(ServingSizeType.allCases, id: \.self) { type in
                                Text(type.displayName)
                                    .tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                }
                
                Spacer()
                
                // Display current selection
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(servingSizeDisplay)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            // Quick Selection Buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Select")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(commonSizes, id: \.self) { size in
                        Button(action: {
                            servingSize = size
                        }) {
                            Text("\(String(format: "%.1f", size))")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(servingSize == size ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(servingSize == size ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Common Serving Sizes by Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Common \(servingSizeType.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(commonSizesForType, id: \.self) { size in
                            Button(action: {
                                servingSize = size
                            }) {
                                Text("\(String(format: "%.1f", size))")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(servingSize == size ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(servingSize == size ? .white : .primary)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var servingSizeDisplay: String {
        if servingSize == 1.0 && servingSizeType == .whole {
            return "1 whole"
        } else if servingSize == 1.0 {
            return "1 \(servingSizeType.displayName)"
        } else {
            return "\(String(format: "%.1f", servingSize)) \(servingSizeType.displayName)"
        }
    }
    
    private var commonSizesForType: [Double] {
        switch servingSizeType {
        case .grams:
            return [50, 100, 150, 200, 250, 300]
        case .ounces:
            return [1, 2, 3, 4, 5, 6, 8, 10, 12]
        case .cups:
            return [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        case .tablespoons:
            return [1, 2, 3, 4, 5, 6, 8, 10, 12]
        case .teaspoons:
            return [0.5, 1, 1.5, 2, 2.5, 3, 4, 5, 6]
        case .pieces:
            return [1, 2, 3, 4, 5, 6, 8, 10, 12]
        case .slices:
            return [1, 2, 3, 4, 5, 6, 8, 10, 12]
        case .whole:
            return [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        }
    }
}

// MARK: - Preview
#Preview {
    ServingSizeSelector(
        servingSize: .constant(1.0),
        servingSizeType: .constant(.whole)
    )
    .padding()
} 