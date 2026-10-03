import SwiftUI

struct ClipboardSettingsView: View {
    @ObservedObject var store: ClipboardHubStore
    @State private var showingClearConfirmation = false

    var body: some View {
        Form {
            Section {
                Picker("最多保留", selection: $store.maxItems) {
                    ForEach([10, 20, 50, 100], id: \.self) { count in
                        Text("\(count) 条").tag(count)
                    }
                }

                Picker("保留时长", selection: $store.ttlHours) {
                    Text("1 天").tag(24)
                    Text("3 天").tag(72)
                    Text("1 周").tag(168)
                    Text("永久").tag(0)
                }
            } header: {
                Text("历史记录")
            } footer: {
                Text("超出数量或时长的记录会自动删除。密码管理器复制的密码不会被记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("已保存 \(store.items.count) 条")
                    Spacer()
                    Button("清空历史…", role: .destructive) {
                        showingClearConfirmation = true
                    }
                    .disabled(store.items.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("清空剪贴板历史?", isPresented: $showingClearConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("已保存的记录会全部删除，无法恢复。")
        }
    }
}

#Preview {
    ClipboardSettingsView(store: ClipboardHubStore())
}
