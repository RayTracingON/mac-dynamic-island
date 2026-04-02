import Combine
import SwiftUI

/// Battery status view for the notch
struct BoringBatteryView: View {
    @ObservedObject var batteryManager = BatteryActivityManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Battery icon with percentage
            BatteryIcon(
                percentage: batteryManager.batteryPercentage,
                isCharging: batteryManager.isCharging,
                isPluggedIn: batteryManager.isPluggedIn
            )
            
            VStack(alignment: .leading, spacing: 4) {
                // Status text
                Text(batteryManager.batteryStatusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Time remaining or additional info
                if SettingsDefaults.shared.get(SettingsDefaults.showTimeRemaining) {
                    HStack(spacing: 6) {
                        if batteryManager.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                        
                        Text(batteryManager.timeRemainingText)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        if batteryManager.isLowPowerMode {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Percentage text
            if SettingsDefaults.shared.get(SettingsDefaults.showBatteryPercentage) {
                Text("\(Int(batteryManager.batteryPercentage))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(batteryColor)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .background(Material.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var batteryColor: Color {
        if !SettingsDefaults.shared.get(SettingsDefaults.colorizeBatteryLevel) {
            return .primary
        }
    
        if batteryManager.isCharging {
            return .green
        }
        
        if batteryManager.batteryPercentage < 20 {
            return .red
        } else if batteryManager.batteryPercentage < 50 {
            return .orange
        } else {
            return .green
        }
    }
}

/// Custom battery icon with fill level
struct BatteryIcon: View {
    let percentage: Double
    let isCharging: Bool
    let isPluggedIn: Bool
    
    private let width: CGFloat = 40
    private let height: CGFloat = 20
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Battery outline
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                .frame(width: width, height: height)
            
            // Battery fill
            RoundedRectangle(cornerRadius: 2)
                .fill(fillColor)
                .frame(width: max(0, (width - 4) * CGFloat(percentage / 100)), height: height - 4)
                .padding(.leading, 2)
            
            // Battery terminal
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.primary.opacity(0.3))
                .frame(width: 3, height: 10)
                .offset(x: width + 1)
            
            // Charging bolt
            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .shadow(color: .white, radius: 2)
                    .offset(x: width / 2 - 6, y: 0)
            }
        }
        .frame(width: width + 4, height: height)
    }
    
    private var fillColor: Color {
        if !SettingsDefaults.shared.get(SettingsDefaults.colorizeBatteryLevel) {
            return .primary
        }

        if isCharging {
            return .green
        }
        
        if percentage < 20 {
            return .red
        } else if percentage < 50 {
            return .orange
        } else {
            return .green
        }
    }
}

/// Detailed battery info popover
struct BatteryDetailView: View {
    @ObservedObject var batteryManager = BatteryActivityManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "battery.100")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Battery")
                        .font(.headline)
                    Text(batteryManager.batteryStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(batteryManager.batteryPercentage))%")
                    .font(.system(size: 32, weight: .bold))
                    .monospacedDigit()
            }
            
            Divider()
            
            // Details grid
            VStack(spacing: 8) {
                DetailRow(label: "Time Remaining", value: batteryManager.timeRemainingText)
                DetailRow(label: "Health", value: batteryManager.batteryHealth)
                DetailRow(label: "Cycle Count", value: "\(batteryManager.cycleCount)")
                DetailRow(label: "Temperature", value: String(format: "%.1f°C", batteryManager.temperature))
                
                if batteryManager.isLowPowerMode {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.yellow)
                        Text("Low Power Mode is On")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
        .background(Material.ultraThickMaterial)
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BoringBatteryView()
        BatteryDetailView()
    }
    .padding()
    .background(Color.black)
}
