// PlateView.swift
// Premium animated macro dashboard
import SwiftUI

struct PlateView: View {
    @State private var celebrationActive = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                PlateAnimationView()
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(18)
                
                // Special Effects for Plate View
                SpecialEffectsView(celebrationActive: $celebrationActive)
                    .allowsHitTesting(false)
            }
            
            Text("Macro Completion (Premium)")
                .font(.headline)
        }
        .navigationTitle("Your Plate")
        .padding()
    }
}

#Preview {
    PlateView()
} 