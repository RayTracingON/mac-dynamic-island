import Foundation

/// Why the island was last opened
enum OverlayVisibilityReason: Equatable {
    case dragDetected       // Files dragged to the notch
    case userExpanded       // User explicitly clicked to expand
    case agentPrompt        // An agent asks you something you can answer in the island
    case none
}
