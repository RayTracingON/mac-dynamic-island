import SwiftUI
import UniformTypeIdentifiers

/// Utility for detecting drag gestures
struct DragDetector: ViewModifier {
    let onDragStarted: () -> Void
    let onDragEnded: () -> Void
    
    @State private var isDragging = false
    
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { _ in
                        if !isDragging {
                            isDragging = true
                            onDragStarted()
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        onDragEnded()
                    }
            )
    }
}

extension View {
    func onDrag(started: @escaping () -> Void, ended: @escaping () -> Void) -> some View {
        modifier(DragDetector(onDragStarted: started, onDragEnded: ended))
    }
}

/// Drop area view modifier
struct DropArea: ViewModifier {
    let onDrop: ([URL]) -> Void
    @State private var isTargeted = false
    
    func body(content: Content) -> some View {
        content
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: isTargeted ? 2 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            var urls: [URL] = []
            
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    if let data = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                }
            }
            
            if !urls.isEmpty {
                // ✅ Swift 6: 避免在并发闭包里捕获可变变量
                let finalURLs = urls
                await MainActor.run {
                    onDrop(finalURLs)
                }
            }
        }
        
        return true
    }
}

extension View {
    func dropArea(onDrop: @escaping ([URL]) -> Void) -> some View {
        modifier(DropArea(onDrop: onDrop))
    }
}
