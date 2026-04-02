import Cocoa
import SwiftUI

/// Custom NSView that handles mouse events for the island overlay.
/// Separates CONTENT interaction from WINDOW movement:
/// - Window moves ONLY via designated handle area OR Option+drag
/// - Content drags (files, etc.) NEVER move the window
final class InteractiveIslandView: NSView {
    
    // MARK: - Move Handle Configuration
    
    /// Height of the move handle area at the top edge (in points)
    private let moveHandleHeight: CGFloat = 12.0
    
    /// Whether the mouse is currently in the move handle area
    private var isInMoveHandle = false
    
    /// Whether Option key was held during mouse down (allows move from anywhere)
    private var optionKeyHeldOnMouseDown = false
    
    // MARK: - Properties
    
    weak var appState: AppState?
    private var mouseDownLocation: NSPoint?
    private var mouseDownTime: Date?
    private var initialWindowOrigin: NSPoint?
    private var hasDraggedBeyondThreshold = false
    
    // Drag threshold in points (4-6px feels natural)
    private let dragThreshold: CGFloat = 5.0
    
    // Click callback - called when user clicks without dragging
    var onClickDetected: (() -> Void)?
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        // Accept first mouse so clicks work immediately
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.isOpaque = false
    }
    
    // MARK: - Hit Testing
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        // CRITICAL: Let subviews (NSHostingView / SwiftUI controls) handle hits first.
        // Only accept hits on self if no subview wants the event.
        // This allows SwiftUI buttons, tabs, menus to receive clicks normally.
        
        guard bounds.contains(point) else { return nil }
        
        // Check subviews first (depth-first, front to back)
        for subview in subviews.reversed() {
            let subviewPoint = subview.convert(point, from: self)
            if let hit = subview.hitTest(subviewPoint) {
                return hit  // Subview (or its descendant) accepts the hit
            }
        }
        
        // No subview accepted — handle at this view level (for window dragging)
        return self
    }
    
    // MARK: - Move Handle Detection
    
    /// Returns the move handle rect (top edge strip)
    private var moveHandleRect: NSRect {
        NSRect(
            x: 0,
            y: bounds.height - moveHandleHeight,
            width: bounds.width,
            height: moveHandleHeight
        )
    }
    
    /// Check if a point (in view coordinates) is in the move handle area
    private func isPointInMoveHandle(_ point: NSPoint) -> Bool {
        moveHandleRect.contains(point)
    }
    
    /// Determine if window movement should be allowed for this event
    private func shouldAllowWindowMove(at point: NSPoint, event: NSEvent) -> Bool {
        // Rule 1: Option key held = always allow move (power user gesture)
        if event.modifierFlags.contains(.option) {
            return true
        }
        
        // Rule 2: In designated move handle area = allow move
        if isPointInMoveHandle(point) {
            return true
        }
        
        // Rule 3: Everywhere else = no window move
        return false
    }
    
    // MARK: - Mouse Events
    
    // Track if mouse down was on self (not a subview)
    private var mouseDownWasOnSelf = false
    
    // Track if this mouse down should trigger window movement
    private var shouldMoveWindow = false
    
    override func mouseDown(with event: NSEvent) {
        // Convert to view coordinates
        let locationInView = convert(event.locationInWindow, from: nil)
        let hitView = hitTest(locationInView)
        
        // Check if click is on self (background) vs subview (content)
        mouseDownWasOnSelf = (hitView === self)
        
        // Check Option key state at mouse down
        optionKeyHeldOnMouseDown = event.modifierFlags.contains(.option)
        
        // Determine if this should move the window
        // CRITICAL: Only move if:
        //   1. Click is on background (self), AND
        //   2. Either in move handle OR Option key held
        shouldMoveWindow = mouseDownWasOnSelf && shouldAllowWindowMove(at: locationInView, event: event)
        
        // Track move handle hover state
        isInMoveHandle = isPointInMoveHandle(locationInView)
        
        // If not handling, let it pass through
        guard mouseDownWasOnSelf else { return }
        
        mouseDownLocation = event.locationInWindow
        mouseDownTime = Date()
        hasDraggedBeyondThreshold = false
        
        guard let window = self.window else { return }
        initialWindowOrigin = window.frame.origin
        
        // Update cursor only if we're actually going to move
        if shouldMoveWindow, let appState = appState, appState.isDraggable {
            NSCursor.closedHand.set()
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        // CRITICAL: Only move window if explicitly allowed
        guard shouldMoveWindow else { return }
        guard let appState = appState else { return }
        guard appState.isDraggable else { return }
        
        guard let mouseDownLoc = mouseDownLocation,
              let initialOrigin = initialWindowOrigin,
              let window = self.window else { return }
        
        let currentLocation = event.locationInWindow
        
        // Calculate distance from initial click
        let dx = currentLocation.x - mouseDownLoc.x
        let dy = currentLocation.y - mouseDownLoc.y
        let distance = sqrt(dx * dx + dy * dy)
        
        // Check if we've exceeded threshold
        if distance > dragThreshold {
            hasDraggedBeyondThreshold = true
        }
        
        // Only move window if threshold exceeded
        if hasDraggedBeyondThreshold {
            // Convert window coordinates to screen coordinates
            let mouseInScreen = window.convertPoint(toScreen: currentLocation)
            let initialMouseInScreen = window.convertPoint(toScreen: mouseDownLoc)
            
            let screenDx = mouseInScreen.x - initialMouseInScreen.x
            let screenDy = mouseInScreen.y - initialMouseInScreen.y
            
            var newOrigin = NSPoint(
                x: initialOrigin.x + screenDx,
                y: initialOrigin.y + screenDy
            )
            
            // Clamp to screen bounds with margin
            newOrigin = clampToScreen(origin: newOrigin, windowSize: window.frame.size)
            
            window.setFrameOrigin(newOrigin)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        defer {
            mouseDownLocation = nil
            mouseDownTime = nil
            initialWindowOrigin = nil
            hasDraggedBeyondThreshold = false
            mouseDownWasOnSelf = false
            shouldMoveWindow = false
            optionKeyHeldOnMouseDown = false
            NSCursor.arrow.set()
        }
        
        // Only handle if mouse down was on self
        guard mouseDownWasOnSelf else { return }
        
        if hasDraggedBeyondThreshold && shouldMoveWindow {
            // This was a window drag - save position
            if let window = self.window {
                saveWindowPosition(window.frame.origin)
            }
            #if DEBUG
            print("[DEBUG][HitTest] region=drag_handle (window moved)")
            #endif
        } else if !hasDraggedBeyondThreshold {
            // This was a click on the island background (not a control)
            #if DEBUG
            print("[DEBUG][HitTest] region=island_background")
            #endif
            onClickDetected?()
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // Remove existing tracking areas
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        
        // Add tracking area for the entire view (for hover detection)
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func mouseMoved(with event: NSEvent) {
        // Update cursor based on position relative to move handle
        guard let appState = appState, appState.isDraggable else {
            NSCursor.arrow.set()
            return
        }
        
        let locationInView = convert(event.locationInWindow, from: nil)
        
        // Only show move cursor in the designated handle area
        if isPointInMoveHandle(locationInView) {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        // Initial cursor setup when entering view
        guard let appState = appState, appState.isDraggable else {
            return
        }
        
        let locationInView = convert(event.locationInWindow, from: nil)
        if isPointInMoveHandle(locationInView) {
            NSCursor.openHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        isInMoveHandle = false
    }
    
    // MARK: - Helpers
    
    private func clampToScreen(origin: NSPoint, windowSize: NSSize) -> NSPoint {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return origin
        }
        
        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 24.0  // Keep 24px from edges
        
        var clamped = origin
        
        // Clamp X
        let minX = screenFrame.minX + margin
        let maxX = screenFrame.maxX - windowSize.width - margin
        clamped.x = max(minX, min(clamped.x, maxX))
        
        // Clamp Y
        let minY = screenFrame.minY + margin
        let maxY = screenFrame.maxY - windowSize.height - margin
        clamped.y = max(minY, min(clamped.y, maxY))
        
        return clamped
    }
    
    private func saveWindowPosition(_ origin: NSPoint) {
        UserDefaults.standard.set(origin.x, forKey: "island_position_x")
        UserDefaults.standard.set(origin.y, forKey: "island_position_y")
        UserDefaults.standard.set(true, forKey: "island_position_saved")
        
        // Save screen identifier for multi-screen support
        if let screen = NSScreen.main {
            let screenID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int ?? 0
            UserDefaults.standard.set(screenID, forKey: "island_screen_id")
        }
        
        // Update dock edge for adaptive layout
        if let window = self.window, let screen = NSScreen.main {
            appState?.updateDockEdge(
                windowFrame: window.frame,
                screenFrame: screen.visibleFrame
            )
        }
    }
    
    #if DEBUG
    /// DEBUG: Visualize the drag handle region at the top of the island.
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let handleRect = moveHandleRect
        
        NSColor.systemRed.withAlphaComponent(0.15).setFill()
        NSBezierPath(rect: handleRect).fill()
        
        NSColor.systemRed.withAlphaComponent(0.6).setStroke()
        let path = NSBezierPath(roundedRect: handleRect, xRadius: 4, yRadius: 4)
        path.lineWidth = 1
        path.stroke()
    }
    #endif
}
