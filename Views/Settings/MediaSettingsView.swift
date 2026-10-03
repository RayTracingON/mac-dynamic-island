import SwiftUI

struct MediaSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("正在播放")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.showMusicLiveActivity,
                    title: "启用实时活动",
                    help: "收起状态时在灵动岛显示歌曲信息"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.playerColorTinting,
                    title: "控件着色",
                    help: "使用专辑封面颜色为控制按钮和背景着色"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.useMusicVisualizer,
                    title: "启用音乐动效",
                    help: "在灵动岛展开时显示播放动效"
                )
            }
            
            Section(header: Text("歌词设置")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.enableLyrics,
                    title: "显示歌词",
                    help: "如果可用，在歌曲下方显示同步歌词"
                )
                
                Picker("歌词来源", selection: Binding(
                    get: { SettingsDefaults.shared.get(SettingsDefaults.lyricsSource) },
                    set: { SettingsDefaults.shared.set(SettingsDefaults.lyricsSource, value: $0) }
                )) {
                    Text("自动 (最佳匹配)").tag("auto")
                    Text("LrcLib").tag("lrclib")
                    Text("网易云音乐").tag("netease")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
