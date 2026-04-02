import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ExpandedPanelView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isTargeted = false

    private var btnPrimary: String { NSLocalizedString("btn_primary", comment: "") }
    private var btnOpen: String { NSLocalizedString("btn_open", comment: "") }
    private var btnCopy: String { NSLocalizedString("btn_copy", comment: "") }

    private var canCopySomething: Bool {
        !appState.payloadSummary.isEmpty
    }

    private var canOpenSomething: Bool {
        guard let url = URL(string: appState.payloadSummary), url.scheme != nil else { return false }
        return true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with pin and close buttons
            HStack {
                Text(appState.localizedTitle)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()
                
                // Pin button (close button is provided by NotchOverlayView overlay)
                Button(action: { togglePin() }) {
                    Image(systemName: appState.interactionState == .pinned ? "pin.fill" : "pin")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appState.interactionState == .pinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .help(appState.interactionState == .pinned ? "Unpin" : "Pin")
            }
            .frame(height: 24)

            Divider()

            // Content area
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.localizedSubtitle)
                    .font(.system(size: 12, weight: .regular))
                    .opacity(0.7)
                    .lineLimit(3)

                if !appState.payloadSummary.isEmpty {
                    Text(appState.payloadSummary)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .opacity(0.6)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }

            // Buttons
            HStack(spacing: 8) {
                Button(btnOpen) { primaryOpenAction() }
                    .buttonStyle(.bordered)
                    .opacity(canOpenSomething ? 1 : 0.4)
                    .disabled(!canOpenSomething)

                Button(btnCopy) { copyAction() }
                    .buttonStyle(.bordered)
                    .opacity(canCopySomething ? 1 : 0.4)
                    .disabled(!canCopySomething)

                Spacer()
            }

            Divider()

            // Tray View
            TrayView()
                .frame(maxHeight: 150)

            Spacer(minLength: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(radius: 12, y: 6)
        .transition(reduceMotion ? .opacity : .asymmetric(insertion: .scale, removal: .opacity))
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            handleDropInExpandedPanel(providers)
        }
    }

    private func togglePin() {
        if appState.interactionState == .pinned {
            appState.unpinOverlay()
        } else if appState.interactionState == .active {
            appState.pinOverlay()
        }
    }

    private func primaryOpenAction() {
        guard let url = URL(string: appState.payloadSummary), url.scheme != nil else { return }
        NSWorkspace.shared.open(url)
        appState.hint = NSLocalizedString("hint_drop_received", comment: "")
    }

    private func copyAction() {
        guard !appState.payloadSummary.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(appState.payloadSummary, forType: .string)
        appState.markCopied()
    }

    private func handleDropInExpandedPanel(_ providers: [NSItemProvider]) -> Bool {
        var handled = 0
        let total = providers.count
        
        for provider in providers {
            // CRITICAL SECURITY FIX: Use loadDataRepresentation to avoid NSObject class spam
            // This prevents "NSSecureCoding allowed classes list contains [NSObject class]" warnings
            provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                if let error = error {
                    DispatchQueue.main.async {
                        Log.performanceWarning("Drop failed: \(error.localizedDescription)")
                        let errorActivity = Activity(
                            kind: .info,
                            title: L("activity.drop.error.title"),
                            message: error.localizedDescription,
                            iconName: "exclamationmark.circle",
                            progress: nil,
                            isPersistent: false,
                            expiresAt: Date().addingTimeInterval(4),
                            priority: 70
                        )
                        Task { @MainActor in
                            ActivityCenter.shared.post(errorActivity)
                        }
                    }
                    return
                }
                
                // Parse URL from data representation
                if let data = data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        Log.trayItemDropped(url.lastPathComponent)
                        appState.addToTray(url: url)
                        handled += 1
                        
                        // Post drop activity when all items loaded
                        if handled == total {
                            let activity = Activity(
                                kind: .drop,
                                title: L("activity.drop.title"),
                                message: L("activity.drop.message", "\(total)"),
                                iconName: "arrow.down.doc",
                                progress: nil,
                                isPersistent: false,
                                expiresAt: Date().addingTimeInterval(4),
                                priority: 80
                            )
                            Task { @MainActor in
                                ActivityCenter.shared.post(activity)
                            }
                        }
                    }
                }
            }
        }
        return total > 0
    }
}

#Preview {
    ExpandedPanelView()
        .environmentObject(AppState())
        .frame(width: 380, height: 400)
        .padding()
}
