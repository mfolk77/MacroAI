// MacroChip.swift
// Premium macro display component with progress indication
import SwiftUI

struct MacroChip: View {
    let label: String
    let value: String
    let color: Color
    let progress: Double
    
    @StateObject private var themeManager = ThemeManager.shared
    @State private var animatedProgress: Double = 0
    
    private var isOverTarget: Bool {
        progress > 1.0
    }
    
    private var displayProgress: Double {
        min(progress, 1.2) // Cap visual progress at 120%
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 3)
                
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        isOverTarget ? .red : color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                
                // Center content
                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundColor(isOverTarget ? .red : .secondary)
                }
            }
            .frame(width: 50, height: 50)
            
            // Label
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.secondaryColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isOverTarget ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isOverTarget)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
                animatedProgress = displayProgress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = min(newValue, 1.2)
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        MacroChip(
            label: "Protein",
            value: "85g",
            color: .red,
            progress: 0.75
        )
        MacroChip(
            label: "Carbs", 
            value: "120g",
            color: .green,
            progress: 1.15
        )
        MacroChip(
            label: "Fat",
            value: "45g",
            color: .yellow,
            progress: 0.60
        )
    }
    .padding()
}