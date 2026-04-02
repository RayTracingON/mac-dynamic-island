import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text(L("settings.appearance.header"))) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L("settings.appearance.corner_radius"))
                        Spacer()
                        Text(String(format: "%.2f", SettingsDefaults.shared.get(SettingsDefaults.cornerRadiusScaling)))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { SettingsDefaults.shared.get(SettingsDefaults.cornerRadiusScaling) },
                        set: { SettingsDefaults.shared.set(SettingsDefaults.cornerRadiusScaling, value: $0) }
                    ), in: 0.5...2.0, step: 0.05)
                }
                .padding(.vertical, 4)

                
                ToggleSettingsRow(
                    key: SettingsDefaults.enableShadow,
                    title: "窗口阴影",
                    help: "在展开状态下为灵动岛添加深度阴影"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.enableBlur,
                    title: "背景模糊 (毛玻璃)",
                    help: "为灵动岛背景应用高斯模糊效果"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.enableGradient,
                    title: "渐变背景",
                    help: "为背景添加细微的颜色渐变效果"
                )
            }
            
            Section(header: Text("内容展示")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.lightingEffect,
                    title: L("settings.appearance.lighting_effect"),
                    help: L("settings.appearance.lighting_effect_help")
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.launchAtLogin,
                    title: L("settings.startup.launch_at_login"),
                    help: "电脑重启后自动启动灵动岛"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showNotHumanFace,
                    title: "空闲时显示表情动画",
                    help: "在灵动岛没有活动时显示一个可爱的表情"
                )
            }
            
            Section(header: Text("颜色与风格")) {
                Picker("岛屿背景颜色", selection: Binding(
                    get: { SettingsDefaults.shared.get(SettingsDefaults.islandBackgroundColor) },
                    set: { SettingsDefaults.shared.set(SettingsDefaults.islandBackgroundColor, value: $0) }
                )) {
                    Text("经典全黑").tag("black")
                    Text("深灰色").tag("darkgray")
                    Text("深蓝色").tag("deepblue")
                    Text("深红色").tag("deepred")
                }
                .pickerStyle(.menu)
                
                Picker("进度条颜色", selection: Binding(
                    get: { SettingsDefaults.shared.get(SettingsDefaults.sliderColor) },
                    set: { SettingsDefaults.shared.set(SettingsDefaults.sliderColor, value: $0) }
                )) {
                    Text("纯白色").tag("white")
                    Text("系统强调色").tag("accent")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
