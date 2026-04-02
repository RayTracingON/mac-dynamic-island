import SwiftUI

// MARK: - Zone 3 Unified Content
struct Zone3ContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var zone3Manager = Zone3StateManager.shared
    
    let onClose: () -> Void
    
    var body: some View {
        // 🧼 PURIFIED: Transparent bridge
        Group {
            switch zone3Manager.currentMode {
            case .quickActions:
                QuickActionsZoneView(onClose: onClose)
            case .scratchpad:
                ScratchpadZoneView(onClose: onClose)
            }
        }
        .background(Color.clear)
    }
}

// MARK: - Quick Actions Zone
struct QuickActionsZoneView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                Zone3ActionIcon(title: "Clipboard", icon: "doc.on.clipboard")
                Zone3ActionIcon(title: "Files", icon: "tray.fill")
                Zone3ActionIcon(title: "Downloads", icon: "arrow.down.circle")
                Zone3ActionIcon(title: "Desktop", icon: "macwindow")
            }
        }
        .padding(16)
        .background(Color.clear) // PURIFIED
    }
}

// MARK: - Scratchpad
struct ScratchpadZoneView: View {
    @ObservedObject private var scratchpad = ScratchpadStore.shared
    let onClose: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextEditor(text: $scratchpad.text)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
        .padding(16)
        .onAppear { isFocused = true }
        .background(Color.clear) // PURIFIED
    }
}

private struct Zone3ActionIcon: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            Text(title).font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
    }
}
