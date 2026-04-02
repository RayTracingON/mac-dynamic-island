import SwiftUI

struct AdvancedSettingsView: View {
    @State private var showingResetConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("故障排除")) {
                Button("重启应用") {
                     let url = URL(fileURLWithPath: Bundle.main.bundlePath)
                     NSWorkspace.shared.open(url)
                     NSApp.terminate(nil)
                }
                
                ToggleSettingsRow(
                    key: SettingsDefaults.settingsIconInNotch,
                    title: "在灵动岛内显示设置图标",
                    help: "直接在灵动岛内显示一个齿轮图标用于快速进入设置"
                )
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
                    Text("这将恢复所有设置为默认值。应用随后会自动重启。")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func resetSettings() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            
            // Restart
            let url = URL(fileURLWithPath: Bundle.main.bundlePath)
            NSWorkspace.shared.open(url)
            NSApp.terminate(nil)
        }
    }
}
