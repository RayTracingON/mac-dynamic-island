import SwiftUI

struct AppearanceSettingsView: View {
    // Observed so the values shown here follow your changes
    @ObservedObject private var settings = SettingsDefaults.shared

    var body: some View {
        Form {
            Section(header: Text(L("settings.appearance.header"))) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L("settings.appearance.corner_radius"))
                        Spacer()
                        Text(String(format: "%.2f", settings.get(SettingsDefaults.cornerRadiusScaling)))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { settings.get(SettingsDefaults.cornerRadiusScaling) },
                        set: { settings.set(SettingsDefaults.cornerRadiusScaling, value: $0) }
                    ), in: 0.5...2.0, step: 0.05)
                }
                .padding(.vertical, 4)

                ToggleSettingsRow(
                    key: SettingsDefaults.enableBlur,
                    title: "背景模糊 (毛玻璃)",
                    help: "为灵动岛背景应用高斯模糊效果"
                )

                Picker("岛屿背景颜色", selection: Binding(
                    get: { settings.get(SettingsDefaults.islandBackgroundColor) },
                    set: { settings.set(SettingsDefaults.islandBackgroundColor, value: $0) }
                )) {
                    Text("经典全黑").tag("black")
                    Text("深灰色").tag("darkgray")
                    Text("深蓝色").tag("deepblue")
                    Text("深红色").tag("deepred")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
