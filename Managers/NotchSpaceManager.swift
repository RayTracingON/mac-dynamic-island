import Combine
//
//  NotchSpaceManager.swift
//  boringNotch
//
//  Created by Alexander on 2025-09-20.
//

import Foundation
import AppKit

// CGSSpace management for keeping notch window visible across spaces
class NotchSpaceManager {
    static let shared = NotchSpaceManager()
    
    struct NotchSpace {
        var windows: Set<NSWindow> = []
    }
    
    var notchSpace = NotchSpace()
    
    private init() {}
    
    func addWindow(_ window: NSWindow) {
        notchSpace.windows.insert(window)
        configureWindowForAllSpaces(window)
    }
    
    func removeWindow(_ window: NSWindow) {
        notchSpace.windows.remove(window)
    }
    
    private func configureWindowForAllSpaces(_ window: NSWindow) {
        window.collectionBehavior.insert(.canJoinAllSpaces)
        window.collectionBehavior.insert(.stationary)
        window.collectionBehavior.insert(.fullScreenAuxiliary)
    }
}
