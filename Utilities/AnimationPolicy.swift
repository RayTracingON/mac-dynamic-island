import SwiftUI

struct AnimationPolicy {
    static func standardAnimation(
        reduceMotionEnabled: Bool = false
    ) -> Animation {
        if reduceMotionEnabled {
            return .linear(duration: 0.15)
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
}
