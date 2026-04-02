import SwiftUI

struct HUDSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("系统 HUD 替换")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.hudReplacement,
                    title: "替换系统默认 HUD",
                    help: "隐藏 macOS 默认的音量、亮度调节悬浮窗"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.inlineHUD,
                    title: "在灵动岛内显示",
                    help: "调节音量或亮度时，在灵动岛区域显示指示器"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showHUDPercentage,
                    title: "显示百分比数值",
                    help: "在指示条旁显示具体数值"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showOpenNotchHUD,
                    title: "展开时依然显示",
                    help: "即使灵动岛处于展开状态，也允许显示 HUD 指示器"
                )
            }
            
            Section(header: Text("视觉风格")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.enableGradient,
                    title: "渐变样式",
                    help: "使用平滑渐变色替代纯色填充"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.systemEventIndicatorShadow,
                    title: "发光效果",
                    help: "在指示器背后添加细微的发光动效"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.systemEventIndicatorUseAccent,
                    title: "使用系统强调色",
                    help: "使用系统设置中的强调色为指示器着色"
                )
            }
            .disabled(!SettingsDefaults.shared.get(SettingsDefaults.hudReplacement))

            Section(header: Text("高级行为")) {
                 SettingsPickerRow(
                    key: SettingsDefaults.optionKeyAction,
                    title: "Option 键行为",
                    options: [
                        0: "默认 (无)",
                        1: "微调 (1/4 步长)",
                        2: "瞬间最大/最小"
                    ],
                    help: "按住 Option 键调节音量或亮度时的行为"
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
