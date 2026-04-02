import SwiftUI

/// Custom separator component
struct SeparatorView: View {
    var color: Color = Color.secondary.opacity(0.3)
    var thickness: CGFloat = 1
    var padding: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
            .padding(.horizontal, padding)
    }
}

/// Vertical separator
struct VerticalSeparator: View {
    var color: Color = Color.secondary.opacity(0.3)
    var thickness: CGFloat = 1
    var padding: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: thickness)
            .padding(.vertical, padding)
    }
}

/// Separator with label
struct LabeledSeparator: View {
    let label: String
    var color: Color = Color.secondary.opacity(0.3)
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(height: 1)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            
            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        VStack(spacing: 16) {
            Text("Item 1")
            SeparatorView()
            Text("Item 2")
            SeparatorView(color: .blue, thickness: 2)
            Text("Item 3")
        }
        .padding()
        
        HStack(spacing: 16) {
            Text("Left")
            VerticalSeparator()
            Text("Middle")
            VerticalSeparator(color: .blue, thickness: 2)
            Text("Right")
        }
        .padding()
        
        LabeledSeparator(label: "OR")
            .padding()
    }
    .frame(width: 300)
}
