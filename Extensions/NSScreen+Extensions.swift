//
//  NSScreen+Extensions.swift
//  Mac灵动岛
//
//  Stage 1: Screen utilities for multi-display support
//

import AppKit

extension NSScreen {
    /// Get unique identifier for screen
    var displayUUID: String? {
        return deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? String
            ?? String(describing: deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")])
    }
    
    /// Find screen by UUID
    static func screen(withUUID uuid: String?) -> NSScreen? {
        guard let uuid = uuid else { return nil }
        return NSScreen.screens.first { $0.displayUUID == uuid }
    }
    
    /// Check if screen has a notch
    var hasNotch: Bool {
        if #available(macOS 12.0, *) {
            return safeAreaInsets.top > 0
        }
        return false
    }
    
    /// Get notch height for screen
    var notchHeight: CGFloat {
        if #available(macOS 12.0, *) {
            return safeAreaInsets.top
        }
        return 0
    }
}
