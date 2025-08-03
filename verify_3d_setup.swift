import SwiftUI
import SceneKit

/// Verification view for 3D setup
struct Verify3DSetupView: View {
    @State private var fileStatus = "Checking..."
    @State private var sceneStatus = "Checking..."
    @State private var canShow3D = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔍 3D Setup Verification")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("File Status:")
                    Spacer()
                    Text(fileStatus)
                        .foregroundColor(fileStatus.contains("✅") ? .green : .red)
                }
                
                HStack {
                    Text("Scene Status:")
                    Spacer()
                    Text(sceneStatus)
                        .foregroundColor(sceneStatus.contains("✅") ? .green : .red)
                }
                
                HStack {
                    Text("3D Ready:")
                    Spacer()
                    Text(canShow3D ? "✅ Yes" : "❌ No")
                        .foregroundColor(canShow3D ? .green : .red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if canShow3D {
                VStack {
                    Text("🎄 Premium 3D Tree")
                        .font(.headline)
                    
                    ChristmasTree3DView()
                        .frame(height: 250)
                        .cornerRadius(12)
                        .shadow(radius: 8)
                }
            }
            
            Button("Test Again") {
                verifySetup()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
        .onAppear {
            verifySetup()
        }
    }
    
    private func verifySetup() {
        fileStatus = "Checking..."
        sceneStatus = "Checking..."
        canShow3D = false
        
        // Check if file exists
        if let treeURL = Bundle.main.url(forResource: "christmas_tree_premium", withExtension: "glb", subdirectory: "Resources/3D_Assets/christmas") {
            fileStatus = "✅ File found"
            print("✅ File found at: \(treeURL)")
            
            // Try to load scene
            do {
                let scene = try SCNScene(url: treeURL, options: nil)
                sceneStatus = "✅ Scene loaded (\(scene.rootNode.childNodes.count) nodes)"
                print("✅ Scene loaded successfully")
                
                canShow3D = true
            } catch {
                sceneStatus = "❌ Scene failed: \(error.localizedDescription)"
                print("❌ Scene loading failed: \(error)")
            }
        } else {
            fileStatus = "❌ File not found"
            sceneStatus = "❌ Cannot test"
            print("❌ File not found in bundle")
        }
    }
}

#Preview {
    Verify3DSetupView()
} 