import Combine
import SwiftUI

/// Main HUD view that displays system events in the notch area
struct OpenNotchHUD: View {
    @ObservedObject var vm: BoringViewModel
    @State private var isExpanded: Bool = false
    @State private var showDetails: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Leading content
                leadingContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Center content (icon/indicator)
                centerContent
                    .frame(width: 60)
                
                // Trailing content
                trailingContent
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(hudBackground)
            .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 20 : 40))
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            .frame(width: isExpanded ? geometry.size.width : min(200, geometry.size.width))
            .frame(height: isExpanded ? 80 : 50)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    // MARK: - Content Sections
    
    @ViewBuilder
    private var leadingContent: some View {
        if isExpanded {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.eventTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                if !vm.eventSubtitle.isEmpty {
                    Text(vm.eventSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .leading)))
        }
    }
    
    @ViewBuilder
    private var centerContent: some View {
        ZStack {
            // Animated ring for important events
            if vm.isImportantEvent {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .blue],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(vm.animationRotation))
            }
            
            // Event icon
            Image(systemName: vm.eventIcon)
                .font(.system(size: isExpanded ? 20 : 16, weight: .semibold))
                .foregroundColor(vm.eventColor)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    @ViewBuilder
    private var trailingContent: some View {
        if isExpanded {
            HStack(spacing: 8) {
                // Value display (percentage, volume level, etc.)
                if let value = vm.eventValue {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                }
                
                // Additional indicator
                if vm.showProgressIndicator {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    private var hudBackground: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Colored overlay based on event type
            vm.eventColor.opacity(0.15)
                .blur(radius: 20)
        }
    }
}

// MARK: - Event Type Extensions

// Reference to shared managers
private let volumeManager = VolumeManager.shared
private let brightnessManager = BrightnessManager.shared
private let batteryManager = BatteryActivityManager.shared

extension BoringViewModel {
    var eventTitle: String {
        switch currentEvent {
        case .volume:
            return "Volume"
        case .brightness:
            return "Brightness"
        case .battery:
            return "Battery"
        case .charging:
            return "Charging"
        case .camera:
            return "Camera"
        case .microphone:
            return "Microphone"
        case .screenRecording:
            return "Screen Recording"
        case .airDrop:
            return "AirDrop"
        case .none:
            return ""
        }
    }
    
    var eventSubtitle: String {
        switch currentEvent {
        case .charging:
            return "Power Connected"
        case .camera:
            return "Camera Active"
        case .microphone:
            return "Microphone Active"
        case .screenRecording:
            return "Recording"
        default:
            return ""
        }
    }
    
    var eventIcon: String {
        switch currentEvent {
        case .volume:
            return volumeManager.isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill"
        case .brightness:
            return "sun.max.fill"
        case .battery:
            return "battery.100"
        case .charging:
            return "bolt.fill"
        case .camera:
            return "video.fill"
        case .microphone:
            return "mic.fill"
        case .screenRecording:
            return "record.circle.fill"
        case .airDrop:
            return "airplayaudio"
        case .none:
            return "circle"
        }
    }
    
    var eventColor: Color {
        switch currentEvent {
        case .volume:
            return .blue
        case .brightness:
            return .yellow
        case .battery:
            return isLowBattery ? .red : .green
        case .charging:
            return .green
        case .camera:
            return .green
        case .microphone:
            return .red
        case .screenRecording:
            return .red
        case .airDrop:
            return .blue
        case .none:
            return .gray
        }
    }
    
    var eventValue: String? {
        switch currentEvent {
        case .volume:
            return "\(Int(volumeManager.currentVolume * 100))%"
        case .brightness:
            return "\(Int(brightnessManager.currentBrightness * 100))%"
        case .battery:
            return "\(Int(batteryManager.batteryPercentage))%"
        default:
            return nil
        }
    }
    
    var isImportantEvent: Bool {
        switch currentEvent {
        case .camera, .microphone, .screenRecording:
            return true
        default:
            return false
        }
    }
    
    var showProgressIndicator: Bool {
        return currentEvent == .charging && !batteryManager.isFullyCharged
    }
    
    var isLowBattery: Bool {
        return batteryManager.batteryPercentage < 20
    }
}

// Define event types
enum SystemEvent {
    case volume
    case brightness
    case battery
    case charging
    case camera
    case microphone
    case screenRecording
    case airDrop
    case none
}

#Preview {
    OpenNotchHUD(vm: BoringViewModel())
        .frame(width: 400, height: 100)
        .background(Color.black)
}
