import SwiftUI

/// Tooltip view modifier
struct TooltipModifier: ViewModifier {
    let text: String
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                isHovering = hovering
            }
            .overlay(alignment: .top) {
                if isHovering {
                    TooltipContent(text: text)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        .animation(.spring(response: 0.2), value: isHovering)
                }
            }
    }
}

struct TooltipContent: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.8))
            )
            .foregroundColor(.white)
            .offset(y: -30)
    }
}

extension View {
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text))
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Hover me")
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .tooltip("This is a tooltip")
        
        Button("Button") {}
            .tooltip("Click to perform action")
    }
    .frame(width: 400, height: 300)
}
