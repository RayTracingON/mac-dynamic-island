import SwiftUI

struct BatterySettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("电池设置")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.showBatteryIndicator,
                    title: "显示电池图标",
                    help: "收起状态时在灵动岛内显示电量图标"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showPowerStatusNotifications,
                    title: "电源状态通知",
                    help: "当接入电源或断开电源时，灵动岛自动展开并做出提示"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showBatteryPercentage,
                    title: "显示百分比",
                    help: "在电池图标旁显示具体电量百分比"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.showTimeRemaining,
                    title: "显示剩余使用时间",
                    help: "根据当前功耗估算电池剩余可用时间"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.colorizeBatteryLevel,
                    title: "电量颜色区分",
                    help: "根据电量水平改变电池图标颜色 (绿/黄/红)"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.lowPowerModeAlert,
                    title: "低电量提醒",
                    help: "当电量低于 20% 时发出警报通知"
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
