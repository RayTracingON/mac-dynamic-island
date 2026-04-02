//
//  SharingStateManager.swift
//  boringNotch
//
//  Created by Alexander on 2025-09-15.
//

import Foundation
import Combine

class SharingStateManager: ObservableObject {
    static let shared = SharingStateManager()
    
    @Published var preventNotchClose: Bool = false
    @Published var isSharingActive: Bool = false
    
    private init() {}
    
    func beginSharing() {
        preventNotchClose = true
        isSharingActive = true
        
        NotificationCenter.default.post(name: .sharingDidBegin, object: nil)
    }
    
    func endSharing() {
        preventNotchClose = false
        isSharingActive = false
        
        NotificationCenter.default.post(name: .sharingDidFinish, object: nil)
    }
    
    func temporarilyPreventClose(for duration: TimeInterval = 0.5) {
        preventNotchClose = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.preventNotchClose = false
        }
    }
}

extension Notification.Name {
    static let sharingDidBegin = Notification.Name("sharingDidBegin")
    static let sharingDidFinish = Notification.Name("sharingDidFinish")
}
