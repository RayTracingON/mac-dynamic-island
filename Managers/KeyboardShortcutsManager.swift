import AppKit
import Carbon

/// Manager for app-wide keyboard shortcuts
class KeyboardShortcutsManager {
    static let shared = KeyboardShortcutsManager()
    
    private var shortcuts: [String: KeyboardShortcut] = [:]
    private var eventMonitor: Any?
    
    private init() {}
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Registration
    
    func register(
        _ shortcut: KeyboardShortcut,
        identifier: String,
        action: @escaping () -> Void
    ) {
        var updatedShortcut = shortcut
        updatedShortcut.action = action
        shortcuts[identifier] = updatedShortcut
        
        if eventMonitor == nil {
            startMonitoring()
        }
    }
    
    func unregister(identifier: String) {
        shortcuts.removeValue(forKey: identifier)
        
        if shortcuts.isEmpty {
            stopMonitoring()
        }
    }
    
    func unregisterAll() {
        shortcuts.removeAll()
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            for (_, shortcut) in self.shortcuts {
                if shortcut.matches(event) {
                    shortcut.action?()
                    return nil // Consume event
                }
            }
            
            return event
        }
    }
    
    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    // MARK: - Query
    
    func shortcut(for identifier: String) -> KeyboardShortcut? {
        return shortcuts[identifier]
    }
    
    var allShortcuts: [String: KeyboardShortcut] {
        return shortcuts
    }
}

// MARK: - Keyboard Shortcut

struct KeyboardShortcut {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags
    var action: (() -> Void)?
    
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, action: (() -> Void)? = nil) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.action = action
    }
    
    func matches(_ event: NSEvent) -> Bool {
        return event.keyCode == keyCode && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers
    }
    
    var displayString: String {
        var parts: [String] = []
        
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        
        if let keyString = keyCodeToString(keyCode) {
            parts.append(keyString)
        }
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Delete: return "⌫"
        case kVK_Escape: return "⎋"
        case kVK_Tab: return "⇥"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default:
            // Try to get character from key code
            let source = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
            if let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) {
                let data = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data
                let keyLayout = data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) }
                
                var deadKeyState: UInt32 = 0
                var chars = [UniChar](repeating: 0, count: 4)
                var length = 0
                
                let error = UCKeyTranslate(
                    keyLayout,
                    keyCode,
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    UInt32(kUCKeyTranslateNoDeadKeysMask),
                    &deadKeyState,
                    4,
                    &length,
                    &chars
                )
                
                if error == noErr && length > 0 {
                    return String(utf16CodeUnits: chars, count: length).uppercased()
                }
            }
            return nil
        }
    }
}

// MARK: - Predefined Shortcuts

extension KeyboardShortcut {
    static let toggleNotch = KeyboardShortcut(
        keyCode: 49, // Space
        modifiers: .option
    )
    
    static let openSettings = KeyboardShortcut(
        keyCode: 39, // S
        modifiers: [.command, .shift]
    )
    
    static let openShelf = KeyboardShortcut(
        keyCode: 37, // L
        modifiers: [.command, .shift]
    )
    
    static let toggleMusic = KeyboardShortcut(
        keyCode: 46, // M
        modifiers: [.command, .shift]
    )
}
