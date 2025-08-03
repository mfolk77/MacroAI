import SwiftUI
import SceneKit

/// Simple test view for the premium Christmas tree
struct PremiumTreeTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🎄 Premium Christmas Tree Test")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Testing the new premium 3D model")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 3D View
            ChristmasTree3DView()
                .frame(height: 300)
                .cornerRadius(12)
                .shadow(radius: 8)
            
            // AR Button
            ChristmasTreeARView()
                .frame(height: 100)
            
            // File info
            VStack(alignment: .leading, spacing: 5) {
                Text("Model: christmas_tree_premium.glb")
                Text("Size: 997KB")
                Text("Features: Premium materials, animations, ornaments")
                Text("Status: Ready for iOS AR")
            }
            .font(.caption)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    PremiumTreeTestView()
} 