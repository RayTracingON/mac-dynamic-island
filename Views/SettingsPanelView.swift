import SwiftUI

struct SettingsPanelView: View {
    @ObservedObject var settings: AppSettings
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Overlay Settings")
                .font(.system(size: 16, weight: .semibold))
            
            Divider()
            
            // Feature toggles
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Drag & Drop", isOn: $settings.dragDropEnabled)
                    .toggleStyle(.switch)
                
                Toggle("Enable Now Playing", isOn: $settings.mediaEnabled)
                    .toggleStyle(.switch)
                
                Toggle("Enable Clipboard Pulse", isOn: $settings.clipboardEnabled)
                    .toggleStyle(.switch)
            }
            
            Divider()
            
            // Overlay scale slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay Scale: \(String(format: "%.0f%%", settings.overlayScale * 100))")
                    .font(.system(size: 12, weight: .medium))
                
                Slider(value: $settings.overlayScale, in: 0.8...1.2, step: 0.1)
                    .frame(maxWidth: 250)
                
                Text("Adjusts the size of the overlay pill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Reset button
            HStack {
                Button("Reset Overlay") {
                    appState.hideOverlay()
                    settings.overlayScale = 1.0
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding(20)
        .frame(width: 320, height: 300)
    }
}

#Preview {
    SettingsPanelView(settings: AppSettings.shared)
        .environmentObject(AppState())
}
