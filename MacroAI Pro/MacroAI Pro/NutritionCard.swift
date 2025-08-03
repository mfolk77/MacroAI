// NutritionCard.swift
// Reusable nutrition information card component

import SwiftUI

struct NutritionCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        NutritionCard(title: "Calories", value: "350", color: .orange)
        NutritionCard(title: "Protein", value: "25g", color: .blue)
        NutritionCard(title: "Carbs", value: "45g", color: .green)
        NutritionCard(title: "Fats", value: "12g", color: .purple)
    }
    .padding()
} 