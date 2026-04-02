import Combine
import SwiftUI

/// Empty state view for shelf
struct ShelfEmptyStateView: View {
    let onAddFiles: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            // Title
            Text("No Files Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            // Description
            Text("Drag and drop files here or click the button below")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            // Add Button
            Button(action: onAddFiles) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Files")
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Hint
            Text("Tip: You can also drag files directly to the notch")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
