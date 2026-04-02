import Combine
import SwiftUI
import UniformTypeIdentifiers
import os

/// Advanced drag and drop manager with visual feedback
class InteractiveDragDropManager: NSObject, ObservableObject {
    static let shared = InteractiveDragDropManager()
    
    @Published var isDraggingOver = false
    @Published var draggedItems: [DraggedItem] = []
    @Published var dropTargetFrame: CGRect = .zero
    @Published var showDropIndicator = false
    
    private var acceptedTypes: [UTType] = [.fileURL, .url, .text, .image]
    private var dropHandlers: [String: ([URL]) -> Void] = [:]
    
    private override init() {
        super.init()
    }
    
    // MARK: - Drag State
    
    struct DraggedItem: Identifiable {
        let id = UUID()
        let url: URL?
        let text: String?
        let image: NSImage?
        let type: UTType
        
        var displayName: String {
            url?.lastPathComponent ?? text ?? "Item"
        }
    }
    
    // MARK: - Configuration
    
    func setAcceptedTypes(_ types: [UTType]) {
        self.acceptedTypes = types
    }
    
    func registerDropHandler(id: String, handler: @escaping ([URL]) -> Void) {
        dropHandlers[id] = handler
    }
    
    func unregisterDropHandler(id: String) {
        dropHandlers.removeValue(forKey: id)
    }
    
    // MARK: - Drag Validation
    
    func canAcceptDrag(_ providers: [NSItemProvider]) -> Bool {
        return providers.contains { provider in
            acceptedTypes.contains { type in
                provider.hasItemConformingToTypeIdentifier(type.identifier)
            }
        }
    }
    
    // MARK: - Drag Enter
    
    func handleDragEnter() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isDraggingOver = true
            showDropIndicator = true
        }
        
        GestureHandler.shared.performHaptic(.generic)
    }
    
    // MARK: - Drag Over
    
    func handleDragOver(at location: CGPoint) {
        // Update visual feedback based on location
        dropTargetFrame.origin = location
    }
    
    // MARK: - Drag Exit
    
    func handleDragExit() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            isDraggingOver = false
            showDropIndicator = false
        }
    }
    
    // MARK: - Drop Processing
    
    func processDrop(providers: [NSItemProvider], handlerId: String? = nil) async -> Bool {
        var urls: [URL] = []
        
        for provider in providers {
            // Handle URLs
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                do {
                    let data = try await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil)
                    if let url = data as? URL {
                        urls.append(url)
                    } else if let data = data as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                } catch {
                    let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "DragDrop")
                    logger.error("Failed to load file URL: \(error.localizedDescription, privacy: .public)")
                }
            }
            
            // Handle URLs (web)
            else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                do {
                    let data = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil)
                    if let url = data as? URL {
                        urls.append(url)
                    }
                } catch {
                    let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "DragDrop")
                    logger.error("Failed to load URL: \(error.localizedDescription, privacy: .public)")
                }
            }
            
            // Handle text
            else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                do {
                    let text = try await provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) as? String
                    if let text = text, let url = URL(string: text) {
                        urls.append(url)
                    }
                } catch {
                    let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "app", category: "DragDrop")
                    logger.error("Failed to load text: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        
        // ✅ Swift 6: 避免在并发闭包里捕获可变变量
        let finalURLs = urls
        let hasURLs = !finalURLs.isEmpty

        await MainActor.run {
            handleDragExit()

            if hasURLs {
                GestureHandler.shared.performAlignmentHaptic()

                // Call registered handler
                if let handlerId = handlerId, let handler = dropHandlers[handlerId] {
                    handler(finalURLs)
                } else {
                    // Default handling
                    NotificationCenter.default.post(
                        name: .filesDropped,
                        object: nil,
                        userInfo: ["urls": finalURLs]
                    )
                }
            }
        }

        return hasURLs
    }
    
    // MARK: - Visual Feedback
    
    func createDropIndicator() -> some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 3, dash: [10, 5])
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.1))
            )
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    
                    Text("Drop files here")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            )
            .opacity(showDropIndicator ? 1 : 0)
            .scaleEffect(showDropIndicator ? 1 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showDropIndicator)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    func onDropWithFeedback(
        of supportedTypes: [UTType] = [.fileURL, .url],
        handlerId: String? = nil,
        isTargeted: Binding<Bool>? = nil
    ) -> some View {
        self.onDrop(of: supportedTypes.map { $0.identifier }, isTargeted: isTargeted) { providers in
            Task {
                let success = await InteractiveDragDropManager.shared.processDrop(
                    providers: providers,
                    handlerId: handlerId
                )
                return success
            }
            return true
        }
    }
    
    func dropDestination(
        id: String,
        handler: @escaping ([URL]) -> Void
    ) -> some View {
        InteractiveDragDropManager.shared.registerDropHandler(id: id, handler: handler)
        
        return self.onDropWithFeedback(handlerId: id)
            .onAppear {
                InteractiveDragDropManager.shared.registerDropHandler(id: id, handler: handler)
            }
            .onDisappear {
                InteractiveDragDropManager.shared.unregisterDropHandler(id: id)
            }
    }
}

// MARK: - Notifications


extension Notification.Name {
    static let filesDropped = Notification.Name("filesDropped")
}
