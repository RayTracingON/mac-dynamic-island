import SwiftUI

/// Badge view for counts and indicators
struct BadgeView: View {
    let count: Int
    var style: BadgeStyle = .red
    var size: BadgeSize = .small
    
    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, size.horizontalPadding)
                .padding(.vertical, size.verticalPadding)
                .background(style.color)
                .cornerRadius(size.cornerRadius)
        }
    }
    
    private var displayText: String {
        if count > 99 {
            return "99+"
        }
        return "\(count)"
    }
}

enum BadgeStyle {
    case red
    case blue
    case green
    case orange
    case gray
    
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .gray: return .gray
        }
    }
}

enum BadgeSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .body
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            BadgeView(count: 5, style: .red, size: .small)
            BadgeView(count: 10, style: .blue, size: .medium)
            BadgeView(count: 100, style: .green, size: .large)
        }
        
        HStack(spacing: 20) {
            HStack {
                Image(systemName: "bell")
                BadgeView(count: 3, style: .red)
            }
            
            HStack {
                Image(systemName: "message")
                BadgeView(count: 99, style: .blue)
            }
        }
    }
    .padding()
}
