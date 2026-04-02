import SwiftUI

struct MediaSettingsView: View {
    @State private var slotLimit: Double = Double(SettingsDefaults.shared.get(SettingsDefaults.musicControlSlotLimit))
    
    var body: some View {
        Form {
            Section(header: Text("正在播放")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.showMusicLiveActivity,
                    title: "启用实时活动",
                    help: "收起状态时在灵动岛显示歌曲信息"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.coloredSpectrogram,
                    title: "多彩频谱仪",
                    help: "从专辑封面提取颜色生成音频频谱动画"
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
            
            Section(header: Text("控制按钮配置")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("显示的控制槽位数量")
                        Spacer()
                        Text("\(Int(slotLimit))")
                            .foregroundStyle(.secondary)
                    }
                    
                    Slider(value: $slotLimit, in: 3...7, step: 1) {
                        EmptyView()
                    } onEditingChanged: { editing in
                        if !editing {
                            SettingsDefaults.shared.set(SettingsDefaults.musicControlSlotLimit, value: Int(slotLimit))
                        }
                    }
                    
                    Text("可以调整灵动岛展开后显示的媒体控制按钮数量。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
