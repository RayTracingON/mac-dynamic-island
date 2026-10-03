import SwiftUI

struct AdvancedSettingsView: View {
    @State private var showingResetConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("故障排除")) {
                Button("重启应用") {
                    relaunch()
                }
            }
            
            Section(header: Text("危险区域")) {
                Button("重置所有设置") {
                    showingResetConfirmation = true
                }
                .foregroundStyle(.red)
                .alert("重置设置?", isPresented: $showingResetConfirmation) {
                    Button("取消", role: .cancel) { }
                    Button("确认重置", role: .destructive) {
                        resetSettings()
                    }
                } message: {
                    Text("这将恢复所有设置为默认值（剪贴板历史会保留）。应用随后会自动重启。")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func resetSettings() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let defaults = UserDefaults.standard
        // The clipboard history is yours, not a setting
        let history = defaults.data(forKey: ClipboardHubStore.historyKey)
        // Off by default; clearing the key alone would leave the login item registered
        SettingsDefaults.shared.set(SettingsDefaults.launchAtLogin, value: false)
        defaults.removePersistentDomain(forName: bundleID)
        if let history {
            defaults.set(history, forKey: ClipboardHubStore.historyKey)
        }
        relaunch()
    }

    /// Opens the app again once this copy has quit. Opening it while it still runs would only bring this copy forward
    private func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c", "while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done; open \"$0\"",
            Bundle.main.bundlePath,
        ]
        guard (try? process.run()) != nil else { return }
        NSApp.terminate(nil)
    }
}
