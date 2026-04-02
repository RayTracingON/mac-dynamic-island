import Combine
import SwiftUI

/// Loading indicator view
struct LoadingView: View {
    let message: String?
    
    @State private var isAnimating = false
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Spinner
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
            
            // Message
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
    }
}

/// Custom animated loading view
struct CustomLoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                .frame(width: 40, height: 40)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

/// Skeleton loading view
struct SkeletonLoadingView: View {
    @State private var animate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 20)
                .frame(maxWidth: .infinity)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 20)
                .frame(maxWidth: 200)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 20)
                .frame(maxWidth: 150)
        }
        .shimmer()
        .padding()
    }
}

#Preview {
    VStack(spacing: 60) {
        LoadingView(message: "Loading...")
        
        CustomLoadingView()
        
        SkeletonLoadingView()
            .frame(width: 300)
    }
    .frame(width: 400, height: 600)
}
