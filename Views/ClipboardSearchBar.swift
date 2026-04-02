//
//  ClipboardSearchBar.swift
//  Mac灵动岛
//
//  Search bar with live filtering and keyboard focus support
//

import SwiftUI
import AppKit

struct ClipboardSearchBar: View {
    @EnvironmentObject var hubStore: ClipboardHubStore
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    @State private var eventMonitor: Any?
    
    var body: some View {
        HStack(spacing: 8) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isFocused ? .accentColor : .secondary)
            
            // Text field
            TextField("Search clipboard...", text: $hubStore.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .onSubmit {}
            
            // Clear button (only show when there's text)
            if !hubStore.searchQuery.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hubStore.clearSearch()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isHovered || isFocused ? 1.0 : 0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .task {
            if eventMonitor == nil {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
                        return nil
                    }
                    return event
                }
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ClipboardSearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ClipboardSearchBar()
                .environmentObject(ClipboardHubStore())
                .frame(width: 400)
            
            ClipboardSearchBar()
                .environmentObject({
                    let store = ClipboardHubStore()
                    store.searchQuery = "test query"
                    return store
                }())
                .frame(width: 400)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
#endif
