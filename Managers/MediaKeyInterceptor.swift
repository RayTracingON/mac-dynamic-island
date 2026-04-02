import Foundation
import AppKit

#if APP_STORE
/// Stub implementation for App Store builds (media key interception not available in sandbox)
class MediaKeyInterceptor {
    static let shared = MediaKeyInterceptor()
    
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onFastForward: (() -> Void)?
    var onRewind: (() -> Void)?
    
    private init() {}
    
    func start() {}
    func stop() {}
    func reset() {}
    var isRunning: Bool { false }
}
#else
import Combine
import MediaPlayer

/// Interceptor for hardware media keys
/// Note: CGEventTap is not allowed in sandboxed App Store apps
class MediaKeyInterceptor {
    static let shared = MediaKeyInterceptor()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onPlayPause: (() -> Void)?
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onFastForward: (() -> Void)?
    var onRewind: (() -> Void)?
    
    private init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Control
    
    func start() {
        guard eventTap == nil else { return }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let interceptor = Unmanaged<MediaKeyInterceptor>.fromOpaque(refcon).takeUnretainedValue()
                return interceptor.eventCallback(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func stop() {
        guard let tap = eventTap else { return }
        
        CGEvent.tapEnable(tap: tap, enable: false)
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        
        CFMachPortInvalidate(tap)
        eventTap = nil
    }
    
    // MARK: - Event Handling
    
    private func eventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passRetained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Media key codes
        switch keyCode {
        case 16: // Play/Pause (F8)
            DispatchQueue.main.async { [weak self] in
                self?.onPlayPause?()
            }
            return nil // Consume event
            
        case 17: // Next (F9)
            DispatchQueue.main.async { [weak self] in
                self?.onNext?()
            }
            return nil
            
        case 18: // Previous (F7)
            DispatchQueue.main.async { [weak self] in
                self?.onPrevious?()
            }
            return nil
            
        case 19: // Fast Forward (F10)
            DispatchQueue.main.async { [weak self] in
                self?.onFastForward?()
            }
            return nil
            
        case 20: // Rewind (F6)
            DispatchQueue.main.async { [weak self] in
                self?.onRewind?()
            }
            return nil
            
        default:
            break
        }
        
        return Unmanaged.passRetained(event)
    }
    
    // MARK: - Utilities
    
    var isRunning: Bool {
        return eventTap != nil
    }
    
    func reset() {
        stop()
        start()
    }
}
#endif
