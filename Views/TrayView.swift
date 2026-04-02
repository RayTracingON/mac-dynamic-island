import SwiftUI
import AppKit

struct TrayView: View {
    @EnvironmentObject private var appState: AppState

    private var trayTitle: String { L("menu_tray") }
    private var btnClearAll: String { L("tray.clear_all") }
    private var btnReveal: String { L("tray.reveal") }
    private var btnCopyPath: String { L("button.copy") }
    private var btnRemove: String { L("tray.remove") }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(trayTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.8)

                Spacer()

                if !appState.trayItems.isEmpty {
                    Button(action: {
                        Log.trayCleared()
                        appState.clearTray()
                    }) {
                        Text(btnClearAll)
                            .font(.system(size: 10, weight: .regular))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))

            Divider()
                .padding(.vertical, 0)

            // Tray List
            if appState.trayItems.isEmpty {
                VStack(alignment: .center, spacing: 6) {
                    Text("(empty)")
                        .font(.system(size: 11, weight: .regular))
                        .opacity(0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(appState.trayItems) { item in
                            TrayItemRow(item: item, appState: appState)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - TrayItemRow

struct TrayItemRow: View {
    let item: TrayItem
    let appState: AppState

    private var btnReveal: String { L("tray.reveal") }
    private var btnCopyPath: String { L("button.copy") }
    private var btnRemove: String { L("tray.remove") }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Icon
            Image(nsImage: item.getIcon())
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)

            // Name / Status
            VStack(alignment: .leading, spacing: 0) {
                if item.fileExists {
                    Text(item.displayName)
                        .font(.system(size: 11, weight: .regular))
                        .lineLimit(1)
                } else {
                    HStack(spacing: 4) {
                        Text(item.displayName)
                            .font(.system(size: 11, weight: .regular))
                            .lineLimit(1)
                            .strikethrough()

                        Text(L("tray.missing_file"))
                            .font(.system(size: 9, weight: .regular))
                            .opacity(0.5)
                    }
                }
            }

            Spacer(minLength: 4)

            // Actions
            HStack(spacing: 4) {
                if item.fileExists {
                    if item.isApp {
                        // Launch app
                        Button(action: {
                            Log.trayAppLaunched(item.displayName)
                            NSWorkspace.shared.open(item.url)
                        }) {
                            Text("Open")
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 9, weight: .regular))
                    } else {
                        // Reveal file in Finder
                        Button(btnReveal) {
                            Log.trayItemRevealed(item.displayName)
                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 9, weight: .regular))
                    }

                    Button(btnCopyPath) {
                        Log.trayItemCopiedPath(item.displayName)
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(item.filePath, forType: .string)
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 9, weight: .regular))
                }

                Button(btnRemove) {
                    Log.trayItemRemoved(id: item.id.uuidString)
                    appState.removeFromTray(id: item.id)
                }
                .buttonStyle(.borderless)
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    let appState = AppState()
    appState.trayItems = [
        TrayItem(filePath: "/Users/test/Desktop/file.txt", displayName: "file.txt"),
        TrayItem(filePath: "/Users/test/Desktop/missing.pdf", displayName: "missing.pdf"),
    ]
    return TrayView()
        .environmentObject(appState)
        .frame(height: 200)
        .padding()
}
