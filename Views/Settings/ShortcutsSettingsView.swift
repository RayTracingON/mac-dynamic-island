import SwiftUI

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("全局快捷键")) {
                LabeledContent("切换灵动岛显示", value: "⌘ ⇧ Space")
                LabeledContent("强制收起", value: "⌘ ⌥ Space")
                LabeledContent("剪贴板历史", value: "⌘ ⌥ V")
            }
            
            Section(header: Text("位置与模式")) {
                LabeledContent("切换位置锁定", value: "⌘ ⌥ L")
                LabeledContent("切换移动模式", value: "⌘ ⌥ M")
            }
            
            Section(footer: Text("目前快捷键是固定的，暂不支持自定义修改。")) {
                EmptyView()
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
