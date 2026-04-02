import SwiftUI

struct ShelfSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("智能架子 (Smart Shelf)")) {
                ToggleSettingsRow(
                    key: SettingsDefaults.boringShelf,
                    title: "启用临时存放架",
                    help: "允许将文件拖拽到灵动岛区域进行临时存放"
                )
                
                ToggleSettingsRow(
                    key: SettingsDefaults.expandedDragDetection,
                    title: "扩大拖拽响应区域",
                    help: "通过扩大感应范围，使拖放文件更加容易"
                )
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
