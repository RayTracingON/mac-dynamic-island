//
//  ClipboardGridView.swift
//  Mac灵动岛
//
//  Grid layout mode for clipboard items with adaptive columns
//

import SwiftUI

struct ClipboardGridView: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @Binding var selectedItemID: UUID?
    
    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16, alignment: .top)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(hubStore.displayItems.prefix(10)) { item in
                    ClipboardItemCardV2(
                        item: item,
                        isSelected: selectedItemID == item.id,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedItemID = item.id
                            }
                        },
                        onCopy: {
                            hubStore.copyToClipboard(item)
                            // Provide haptic feedback
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                        },
                        onPin: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                hubStore.togglePin(for: item)
                            }
                        },
                        onDelete: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                hubStore.removeItem(item)
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .onAppear {
            hubStore.recordActivity()
        }
        // Keyboard navigation
        .onKeyPress(.delete) {
            if let selectedID = selectedItemID,
               let item = hubStore.displayItems.first(where: { $0.id == selectedID }) {
                withAnimation {
                    hubStore.removeItem(item)
                    selectedItemID = nil
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            if let selectedID = selectedItemID,
               let item = hubStore.displayItems.first(where: { $0.id == selectedID }) {
                hubStore.copyToClipboard(item)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                return .handled
            }
            return .ignored
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ClipboardGridView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardGridView(selectedItemID: .constant(nil))
            .environmentObject({
                let store = ClipboardHubStore()
                // Mock data
                store.addItem(ClipboardItemV2.createText("Hello, world! This is a longer text to show wrapping behavior.", sourceApp: nil))
                store.addItem(ClipboardItemV2.createText("https://github.com/example/repo", sourceApp: nil))
                store.addItem(ClipboardItemV2.createText("#FF5733", sourceApp: nil))
                store.addItem(ClipboardItemV2.createText("Short text", sourceApp: nil))
                return store
            }())
            .frame(width: 800, height: 600)
    }
}
#endif
