//
//  BoringViewModel.swift
//  Mac灵动岛
//
//  Stage 1: Basic view model from boringNotch
//

import SwiftUI
import Combine

@MainActor
class BoringViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var notchState: NotchState = .closed
    @Published var notchSize: CGSize = getClosedNotchSize()
    @Published var closedNotchSize: CGSize = getClosedNotchSize()
    @Published var screenUUID: String?
    @Published var isCameraExpanded: Bool = false
    @Published var isHoveringCalendar: Bool = false
    @Published var isBatteryPopoverActive: Bool = false
    @Published var hideOnClosed: Bool = false
    @Published var chinHeight: CGFloat = 0
    
    // Drop detection
    @Published var anyDropZoneTargeting: Bool = false
    @Published var generalDropTargeting: Bool = false
    @Published var dragDetectorTargeting: Bool = false
    @Published var dropEvent: Bool = false
    
    // HUD event tracking
    @Published var currentEvent: SystemEvent = .none
    @Published var animationRotation: Double = 0
    
    // MARK: - Computed Properties
    
    var effectiveClosedNotchHeight: CGFloat {
        return closedNotchSize.height
    }
    
    // MARK: - Initialization
    
    init(screenUUID: String? = nil) {
        self.screenUUID = screenUUID
        self.notchSize = getClosedNotchSize(screenUUID: screenUUID)
        self.closedNotchSize = getClosedNotchSize(screenUUID: screenUUID)
    }
    
    // MARK: - State Control
    
    func open() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            notchState = .open
            notchSize = openNotchSize
        }
    }
    
    func close() {
        withAnimation(.spring(response: 0.45, dampingFraction: 1.0)) {
            notchState = .closed
            notchSize = closedNotchSize
        }
    }
    
    func toggle() {
        if notchState == .open {
            close()
        } else {
            open()
        }
    }
    
    func closeHello() {
        BoringViewCoordinator.shared.helloAnimationRunning = false
    }
    
    func toggleCameraPreview() {
        withAnimation {
            isCameraExpanded.toggle()
        }
    }
}
