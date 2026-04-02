import SwiftUI
import AppKit

/// Menu bar icon view with two circles (一大一小)
/// Two filled black circles side by side
struct MenuBarIconView: View {
    var body: some View {
        HStack(spacing: 2) {
            // Large circle
            Circle()
                .fill(Color.primary)
                .frame(width: 10, height: 10)
            
            // Small circle
            Circle()
                .fill(Color.primary)
                .frame(width: 6, height: 6)
        }
        .frame(width: 18, height: 12)
    }
}

/// Helper to create an NSImage from the SwiftUI view
func createMenuBarIcon() -> NSImage {
    let view = MenuBarIconView()
    let hostingView = NSHostingView(rootView: view)
    hostingView.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
    
    let image = NSImage(size: NSSize(width: 16, height: 16))
    image.lockFocus()
    hostingView.layer?.render(in: NSGraphicsContext.current!.cgContext)
    image.unlockFocus()
    image.isTemplate = true  // Makes it adapt to dark/light mode
    
    return image
}

#Preview {
    MenuBarIconView()
        .padding()
        .frame(width: 100, height: 100)
}
