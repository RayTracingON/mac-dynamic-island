import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A robust Drop Zone backed by AppKit's NSView to handle drops in floating panels where SwiftUI might fail.
struct IslandDropZoneView: NSViewRepresentable {
    @Binding var isDraggingOver: Bool
    let onDrop: ([NSItemProvider]) -> Void
    
    func makeNSView(context: Context) -> IslandDropZoneNSView {
        let view = IslandDropZoneNSView()
        view.delegate = context.coordinator
        view.registerForDraggedTypes([
            .fileURL,
            .URL,
            .string,
            .tiff,
            .png
        ])
        return view
    }
    
    func updateNSView(_ nsView: IslandDropZoneNSView, context: Context) {
        context.coordinator.parent = self
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, IslandDropZoneDelegate {
        var parent: IslandDropZoneView
        
        init(parent: IslandDropZoneView) {
            self.parent = parent
        }
        
        func draggingEntered() {
            withAnimation {
                parent.isDraggingOver = true
            }
        }
        
        func draggingExited() {
            withAnimation {
                parent.isDraggingOver = false
            }
        }
        
        func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            let pasteboard = sender.draggingPasteboard
            
            // 1. Prioritize Direct URL Extraction (Most robust in AppKit)
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
                let providers = urls.map { NSItemProvider(object: $0 as NSURL) }
                parent.onDrop(providers)
                return true
            }
            
            // 2. Fallback to Strings/Web Links
            if let strings = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String], !strings.isEmpty {
                let providers = strings.map { NSItemProvider(object: $0 as NSString) }
                parent.onDrop(providers)
                return true
            }
            
            // 3. Last Resort: Generic Providers
            let providers = pasteboard.readObjects(forClasses: [NSItemProvider.self], options: nil) as? [NSItemProvider] ?? []
            if !providers.isEmpty {
                parent.onDrop(providers)
                return true
            }
            
            return false
        }
    }
}

protocol IslandDropZoneDelegate: AnyObject {
    func draggingEntered()
    func draggingExited()
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool
}

class IslandDropZoneNSView: NSView {
    weak var delegate: IslandDropZoneDelegate?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        delegate?.draggingEntered()
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        delegate?.draggingExited()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        delegate?.draggingExited()
        return delegate?.performDragOperation(sender) ?? false
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil // Allow clicks to pass through to content behind
    }
}
