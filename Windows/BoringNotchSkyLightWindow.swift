//
//  BoringNotchSkyLightWindow.swift
//  boringNotch
//
//  Created by Alexander on 2025-10-20.
//

import Cocoa
import Combine

// Note: SkyLightWindow will be added in next file
// For now, using placeholder until we add the SkyLight bridge

class BoringNotchSkyLightWindow: NSPanel {
    private var isSkyLightEnabled: Bool = false
    private var observers: Set<AnyCancellable> = []
    
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: styleMask,
            backing: backing,
            defer: flag
        )
        
        configureWindow()
        setupObservers()
    }
    
    private func configureWindow() {
        isFloatingPanel = true
        isOpaque = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        backgroundColor = .clear
        isMovable = false
        level = .mainMenu + 3
        hasShadow = false
        isReleasedWhenClosed = false
        
        // Force dark appearance regardless of system setting
        appearance = NSAppearance(named: .darkAqua)
        
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]
        
        // Apply initial sharing type setting
        updateSharingType()
    }
    
    private func setupObservers() {
        // Listen for UserDefaults changes to hideFromScreenRecording
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateSharingType()
            }
            .store(in: &observers)
    }
    
    private func updateSharingType() {
        let hideFromRecording = UserDefaults.standard.bool(forKey: "hideFromScreenRecording")
        // .readWrite deprecated in macOS 15, use .readOnly to allow recording access
        sharingType = hideFromRecording ? .none : .readOnly
    }
    
    func enableSkyLight() {
        // Will be implemented with SkyLightOperator
        // if !isSkyLightEnabled {
        //     SkyLightOperator.shared.delegateWindow(self)
        //     isSkyLightEnabled = true
        // }
    }
    
    func disableSkyLight() {
        // Will be implemented with SkyLightOperator
        // if isSkyLightEnabled {
        //     SkyLightOperator.shared.undelegateWindow(self)
        //     isSkyLightEnabled = false
        // }
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
