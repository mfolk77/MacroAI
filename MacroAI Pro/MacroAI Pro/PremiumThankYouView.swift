import SwiftUI

struct PremiumThankYouView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.yellow)
                Text("Thank You!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("for upgrading to Premium 🎉")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("You've unlocked:")
                    .font(.headline)
                    .foregroundColor(.primary)
                ThankYouFeatureRow(emoji: "🔒", text: "All premium content unlocked")
                ThankYouFeatureRow(emoji: "⚡️", text: "Faster performance")
                ThankYouFeatureRow(emoji: "📊", text: "Advanced stats and analytics")
                ThankYouFeatureRow(emoji: "🛠", text: "Customization options")
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(16)
            
            Spacer(minLength: 20)
            
            Button(action: {
                dismiss()
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(32)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(24)
        .shadow(radius: 10)
        .padding()
    }
}

private struct ThankYouFeatureRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)
            Text(text)
                .foregroundColor(.primary)
                .font(.body)
            Spacer()
        }
    }
}

struct PremiumThankYouView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumThankYouView()
            .preferredColorScheme(.light)
            .previewLayout(.sizeThatFits)
    }
}
