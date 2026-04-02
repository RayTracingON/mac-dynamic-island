import SwiftUI

/// View modifier that adds system event indicators to any view
struct SystemEventIndicatorModifier: ViewModifier {
    @ObservedObject var volumeManager = VolumeManager.shared
    @ObservedObject var brightnessManager = BrightnessManager.shared
    @ObservedObject var batteryManager = BatteryActivityManager.shared
    @ObservedObject var webcamManager = WebcamManager.shared
    
    @State private var currentEvent: SystemEventType?
    @State private var eventStartTime: Date?
    @State private var showIndicator: Bool = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            // Event indicator overlay
            if showIndicator, let event = currentEvent {
                VStack {
                    SystemEventIndicator(event: event)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .zIndex(1000)
            }
        }
        .onChange(of: volumeManager.currentVolume) { _, newValue in
            handleVolumeChange(newValue)
        }
        .onChange(of: volumeManager.isMuted) { _, _ in
            handleVolumeChange(volumeManager.currentVolume)
        }
        .onChange(of: brightnessManager.currentBrightness) { _, newValue in
            handleBrightnessChange(newValue)
        }
        .onChange(of: batteryManager.isCharging) { _, newValue in
            if newValue {
                showEvent(.charging)
            }
        }
        .onChange(of: batteryManager.isLowBattery) { _, newValue in
            if newValue {
                showEvent(.lowBattery)
            }
        }
        .onChange(of: webcamManager.isSessionRunning) { _, newValue in
            showEvent(newValue ? .cameraOn : .cameraOff)
        }
    }
    
    private func handleVolumeChange(_ volume: Float) {
        if !shouldShowHUD { return }
        let eventType: SystemEventType = volumeManager.isMuted ? .volumeMuted : .volume(volume)
        showEvent(eventType, duration: 1.0)
    }
    
    private func handleBrightnessChange(_ brightness: Float) {
        if !shouldShowHUD { return }
        showEvent(.brightness(brightness), duration: 1.0)
    }
    
    private var shouldShowHUD: Bool {
        return SettingsDefaults.shared.get(SettingsDefaults.showOpenNotchHUD) || 
               SettingsDefaults.shared.get(SettingsDefaults.hudReplacement)
    }
    
    private func showEvent(_ event: SystemEventType, duration: TimeInterval = 2.0) {
        currentEvent = event
        eventStartTime = Date()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showIndicator = true
        }
        
        // Auto-hide
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [eventStartTime] in
            // Only hide if this is still the same event
            if self.eventStartTime == eventStartTime {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showIndicator = false
                }
            }
        }
    }
}

/// System event types
enum SystemEventType: Equatable {
    case volume(Float)
    case volumeMuted
    case brightness(Float)
    case charging
    case lowBattery
    case cameraOn
    case cameraOff
    case microphoneOn
    case microphoneOff
    case screenRecording
    case airDrop
    
    var icon: String {
        switch self {
        case .volume:
            return "speaker.wave.3.fill"
        case .volumeMuted:
            return "speaker.slash.fill"
        case .brightness:
            return "sun.max.fill"
        case .charging:
            return "bolt.fill"
        case .lowBattery:
            return "battery.0"
        case .cameraOn, .cameraOff:
            return "video.fill"
        case .microphoneOn, .microphoneOff:
            return "mic.fill"
        case .screenRecording:
            return "record.circle.fill"
        case .airDrop:
            return "airplayaudio"
        }
    }
    
    var color: Color {
        switch self {
        case .volume:
            return .blue
        case .volumeMuted:
            return .red
        case .brightness:
            return .yellow
        case .charging:
            return .green
        case .lowBattery:
            return .red
        case .cameraOn:
            return .green
        case .cameraOff:
            return .gray
        case .microphoneOn:
            return .red
        case .microphoneOff:
            return .gray
        case .screenRecording:
            return .red
        case .airDrop:
            return .blue
        }
    }
    
    var displayValue: String? {
        guard SettingsDefaults.shared.get(SettingsDefaults.showHUDPercentage) else { return nil }
        
        switch self {
        case .volume(let value):
            return "\(Int(value * 100))%"
        case .brightness(let value):
            return "\(Int(value * 100))%"
        default:
            return nil
        }
    }
    
    var displayText: String {
        switch self {
        case .volume:
            return "Volume"
        case .volumeMuted:
            return "Muted"
        case .brightness:
            return "Brightness"
        case .charging:
            return "Charging"
        case .lowBattery:
            return "Low Battery"
        case .cameraOn:
            return "Camera On"
        case .cameraOff:
            return "Camera Off"
        case .microphoneOn:
            return "Microphone On"
        case .microphoneOff:
            return "Microphone Off"
        case .screenRecording:
            return "Recording"
        case .airDrop:
            return "AirDrop"
        }
    }
    
    var progress: Double? {
        switch self {
        case .volume(let value):
            return Double(value)
        case .brightness(let value):
            return Double(value)
        default:
            return nil
        }
    }
}

/// Visual indicator for system events
struct SystemEventIndicator: View {
    let event: SystemEventType
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(event.color)
                .symbolRenderingMode(.hierarchical)
            
            // Progress bar or value
            if let progress = event.progress {
                ProgressBarView(progress: progress, color: event.color)
                    .frame(width: 100, height: 4)
            } else if let value = event.displayValue {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .monospacedDigit()
            } else {
                Text(event.displayText)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Material.ultraThinMaterial)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(event.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Simple progress bar
struct ProgressBarView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                
                // Fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: progress)
    }
}

// Extension to apply the modifier
extension View {
    func systemEventIndicators() -> some View {
        modifier(SystemEventIndicatorModifier())
    }
}

#Preview {
    VStack(spacing: 20) {
        SystemEventIndicator(event: .volume(0.5))
        SystemEventIndicator(event: .brightness(0.75))
        SystemEventIndicator(event: .charging)
        SystemEventIndicator(event: .cameraOn)
    }
    .padding()
    .background(Color.black)
}
