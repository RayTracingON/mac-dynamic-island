import Foundation
import Combine
import AppKit

// MARK: - Zone 3 Mode

/// Available roles for Zone 3 (the user-configurable slot)
/// Designed for extensibility: new modes can be added without breaking existing ones
enum Zone3Mode: String, CaseIterable, Codable {
    case quickActions = "quick_actions"
    case scratchpad = "scratchpad"
    
    /// Human-readable name for UI
    var displayName: String {
        switch self {
        case .quickActions: return "Quick Actions"
        case .scratchpad: return "Scratchpad"
        }
    }
    
    /// Brief description for configuration UI
    var description: String {
        switch self {
        case .quickActions: return "Common actions at your fingertips"
        case .scratchpad: return "Temporary notes and text"
        }
    }
    
    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .quickActions: return "bolt.fill"
        case .scratchpad: return "note.text"
        }
    }
    
    /// Default mode (fallback for unknown values)
    static var defaultMode: Zone3Mode { .quickActions }
}

// MARK: - Zone 3 State Manager

/// Manages Zone 3 configuration and state
final class Zone3StateManager: ObservableObject {
    static let shared = Zone3StateManager()
    
    private let modeKey = "zone3_mode"
    
    @Published private(set) var currentMode: Zone3Mode {
        didSet {
            persistMode()
        }
    }
    
    private init() {
        // Load persisted mode or use default
        if let rawValue = UserDefaults.standard.string(forKey: modeKey),
           let mode = Zone3Mode(rawValue: rawValue) {
            self.currentMode = mode
        } else {
            self.currentMode = .defaultMode
        }
    }
    
    /// Change Zone 3 mode
    func setMode(_ mode: Zone3Mode) {
        guard mode != currentMode else { return }
        currentMode = mode
        
        #if DEBUG
        print("🔧 Zone3: mode changed to \(mode.displayName)")
        #endif
    }
    
    private func persistMode() {
        UserDefaults.standard.set(currentMode.rawValue, forKey: modeKey)
    }
}

// MARK: - Scratchpad Store

/// Manages the scratchpad text buffer
final class ScratchpadStore: ObservableObject {
    static let shared = ScratchpadStore()
    
    private let contentKey = "scratchpad_content"
    private let maxCharacters = 2000
    
    @Published var text: String {
        didSet {
            // Auto-save on change (debounced)
            saveDebounced()
        }
    }
    
    @Published var isFocused: Bool = false
    
    private var saveWorkItem: DispatchWorkItem?
    
    private init() {
        self.text = UserDefaults.standard.string(forKey: contentKey) ?? ""
    }
    
    /// Character count
    var characterCount: Int {
        text.count
    }
    
    /// Whether scratchpad has content
    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Clear scratchpad
    func clear() {
        text = ""
        saveImmediately()
    }
    
    /// Copy content to clipboard
    func copyToClipboard() {
        guard hasContent else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // MARK: - Persistence
    
    private func saveDebounced() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        saveWorkItem = workItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func saveImmediately() {
        UserDefaults.standard.set(text, forKey: contentKey)
    }
}
