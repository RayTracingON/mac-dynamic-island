import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var selectedScreenUUID = "Unknown"
    
    // Sizing state
    @State private var notchHeightMode: Int = SettingsDefaults.shared.get(SettingsDefaults.notchHeight)
    @State private var nonNotchHeightValue: Double = SettingsDefaults.shared.get(SettingsDefaults.nonNotchHeight)
    
    var body: some View {
        Form {
            // 0. Permissions
            Section(header: Text("权限管理 (Permissions)")) {
                HStack {
                    Image(systemName: "accessibility")
                        .font(.system(size: 24))
                        .foregroundColor(appState.isAXAuthorized ? .green : .orange)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("辅助功能 (Accessibility)")
                            .font(.headline)
                        Text(appState.isAXAuthorized ? "已授权" : "未授权")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !appState.isAXAuthorized {
                        Button("授予访问权限") {
                            appState.requestAXPermission()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 4)
                
                if !appState.isAXAuthorized {
                    Text("需要此权限以从 QQ音乐、网易云音乐等第三方应用获取音乐状态。")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 1. System Features
            Section(header: Text(L("settings.startup.header"))) {
                ToggleSettingsRow(
                    key: SettingsDefaults.launchAtLogin,
                    title: L("settings.startup.launch_at_login"),
                    help: "电脑重启后自动启动灵动岛"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.menubarIcon,
                    title: "显示菜单栏图标",
                    help: "切换菜单栏状态图标的可见性"
                )
            }
            
            // 2. Display
            Section(header: Text(L("settings.display.header"))) {
                ToggleSettingsRow(
                    key: SettingsDefaults.showOnAllDisplays,
                    title: L("settings.display.mode.all"),
                    help: "在每个连接的屏幕上都显示灵动岛"
                )
                
                Picker(L("settings.display.show_on"), selection: $selectedScreenUUID) {
                    Text("默认显示器").tag("Unknown")
                    if let screen = NSScreen.main {
                        Text(screen.localizedName).tag(screen.localizedName)
                    }
                }
                
                ToggleSettingsRow(
                    key: SettingsDefaults.automaticallySwitchDisplay,
                    title: "自动切换显示器",
                    help: "根据当前活跃窗口自动移动灵动岛"
                )
            }
            
            // 3. Notch Behavior
            Section(header: Text(L("settings.behavior.header"))) {
                ToggleSettingsRow(
                    key: SettingsDefaults.openNotchOnHover,
                    title: L("settings.behavior.show_on_hover"),
                    help: L("settings.behavior.show_on_hover_help")
                )
                
                HStack {
                    Text(L("settings.behavior.hover_delay"))
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { SettingsDefaults.shared.get(SettingsDefaults.minimumHoverDuration) },
                            set: { SettingsDefaults.shared.set(SettingsDefaults.minimumHoverDuration, value: $0) }
                        ),
                        in: 0.0...1.0
                    )
                    .frame(width: 150)
                }
                
                ToggleSettingsRow(
                    key: SettingsDefaults.enableHaptics,
                    title: L("settings.behavior.haptic_feedback"),
                    help: L("settings.behavior.haptic_feedback_help")
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.rememberLastTab,
                    title: "记住最后使用的标签页",
                    help: "展开时重新打开上次使用的部分"
                )
            }
            
            // 4. Auto Close
            Section(header: Text("自动收起")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.autoCloseEnabled,
                    title: "闲置时自动收起",
                    help: "在一段时间没有活动后自动收起灵动岛"
                )
                
                HStack {
                    Text("收起延迟")
                    Spacer()
                    TextField("", value: Binding(
                        get: { SettingsDefaults.shared.get(SettingsDefaults.autoCloseTimeout) },
                        set: { SettingsDefaults.shared.set(SettingsDefaults.autoCloseTimeout, value: $0) }
                    ), formatter: NumberFormatter())
                        .frame(width: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text(L("settings.media.timeout_unit"))
                        .foregroundStyle(.secondary)
                }
            }
            
            // 5. Gestures
            Section(header: Text("手势操作 (Beta)")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.enableGestures,
                    title: "启用手势控制",
                    help: "允许上滑或下滑手势展开/收起灵动岛"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.closeGestureEnabled,
                    title: "上滑收起",
                    help: "通过上滑手势快速收起灵动岛"
                )
                
                HStack {
                    Text("手势灵敏度")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { SettingsDefaults.shared.get(SettingsDefaults.gestureSensitivity) },
                            set: { SettingsDefaults.shared.set(SettingsDefaults.gestureSensitivity, value: $0) }
                        ),
                        in: 20...200
                    )
                    .frame(width: 150)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
