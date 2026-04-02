import Combine
import SwiftUI

/// Compact inline HUD for quick system feedback
struct InlineHUD: View {
    let icon: String
    let value: String
    let color: Color
    let showBar: Bool
    let progress: Double
    
    @State private var appear: Bool = false
    
    init(
        icon: String = "info.circle",
        value: String = "",
        color: Color = .white,
        showBar: Bool = true,
        progress: Double = 0.5
    ) {
        self.icon = icon
        self.value = value
        self.color = color
        self.showBar = showBar
        self.progress = progress
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .symbolEffect(.bounce, value: appear)
            
            // Progress bar or value
            if showBar {
                progressBar
            } else {
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Material.hudMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(appear ? 1 : 0.8)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                appear = true
            }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                
                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: progress)
            }
        }
        .frame(width: 100, height: 4)
    }
}

/// HUD manager for displaying inline notifications
@MainActor
class InlineHUDManager: ObservableObject {
    static let shared = InlineHUDManager()
    
    @Published var isVisible: Bool = false
    @Published var currentIcon: String = ""
    @Published var currentValue: String = ""
    @Published var currentColor: Color = .white
    @Published var showBar: Bool = true
    @Published var progress: Double = 0.5
    
    private var hideTask: Task<Void, Never>?
    
    private init() {}
    
    func show(
        icon: String,
        value: String,
        color: Color = .white,
        showBar: Bool = true,
        progress: Double = 0.5,
        duration: TimeInterval = 1.5
    ) {
        // Cancel any pending hide
        hideTask?.cancel()
        
        // Update values
        currentIcon = icon
        currentValue = value
        currentColor = color
        self.showBar = showBar
        self.progress = progress
        isVisible = true
        
        // Auto-hide after duration
        hideTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            if !Task.isCancelled {
                hide()
            }
        }
    }
    
    func hide() {
        isVisible = false
        hideTask?.cancel()
    }
    
    // MARK: - Convenience Methods
    
    func showVolume(_ volume: Float) {
        let isMuted = volume == 0
        show(
            icon: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill",
            value: "\(Int(volume * 100))%",
            color: isMuted ? .red : .blue,
            showBar: true,
            progress: Double(volume)
        )
    }
    
    func showBrightness(_ brightness: Float) {
        show(
            icon: "sun.max.fill",
            value: "\(Int(brightness * 100))%",
            color: .yellow,
            showBar: true,
            progress: Double(brightness)
        )
    }
    
    func showBattery(percentage: Double, isCharging: Bool) {
        let icon = isCharging ? "bolt.battery.100" : "battery.100"
        let color: Color = isCharging ? .green : (percentage < 20 ? .red : .white)
        
        show(
            icon: icon,
            value: "\(Int(percentage))%",
            color: color,
            showBar: true,
            progress: percentage / 100
        )
    }
    
    func showCamera(isActive: Bool) {
        show(
            icon: "video.fill",
            value: isActive ? "Active" : "Inactive",
            color: isActive ? .green : .gray,
            showBar: false
        )
    }
    
    func showMicrophone(isActive: Bool) {
        show(
            icon: "mic.fill",
            value: isActive ? "Recording" : "Muted",
            color: isActive ? .red : .gray,
            showBar: false
        )
    }
    
    func showAirDrop() {
        show(
            icon: "airplayaudio",
            value: "Ready",
            color: .blue,
            showBar: false,
            duration: 2.0
        )
    }
}

/// View modifier for displaying inline HUD
struct InlineHUDModifier: ViewModifier {
    @ObservedObject var manager = InlineHUDManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if manager.isVisible {
                VStack {
                    InlineHUD(
                        icon: manager.currentIcon,
                        value: manager.currentValue,
                        color: manager.currentColor,
                        showBar: manager.showBar,
                        progress: manager.progress
                    )
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: manager.isVisible)
    }
}

extension View {
    func inlineHUD() -> some View {
        modifier(InlineHUDModifier())
    }
}

// Add HUD material
extension Material {
    static var hudMaterial: Material {
        .ultraThinMaterial
    }
}

#Preview {
    VStack(spacing: 20) {
        InlineHUD(
            icon: "speaker.wave.3.fill",
            value: "50%",
            color: .blue,
            showBar: true,
            progress: 0.5
        )
        
        InlineHUD(
            icon: "sun.max.fill",
            value: "75%",
            color: .yellow,
            showBar: true,
            progress: 0.75
        )
        
        InlineHUD(
            icon: "mic.fill",
            value: "Recording",
            color: .red,
            showBar: false,
            progress: 0
        )
    }
    .padding()
    .background(Color.black)
}
