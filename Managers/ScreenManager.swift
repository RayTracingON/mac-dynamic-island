import Cocoa

enum ScreenManager {
    /// Detect the screen containing the mouse cursor
    static func activeScreenContainingMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first {
            $0.frame.contains(mouseLocation)
        }
    }

    /// Detect the screen containing the frontmost application
    static func activeScreenForFrontmostApp() -> NSScreen? {
        guard NSScreen.screens.first != nil else { return nil }
        // Heuristic: use screen containing most of the frontmost app's windows
        // For now, simpler approach: use screen where mouse is, or main screen
        return activeScreenContainingMouse() ?? NSScreen.main
    }

    /// Get all connected screens
    static func allConnectedScreens() -> [NSScreen] {
        return NSScreen.screens
    }

    /// Get primary/main screen
    static func mainScreen() -> NSScreen? {
        return NSScreen.main
    }

    /// Determine the active screen based on display mode
    /// - activeOnly: use screen containing mouse, fallback to main
    /// - mainOnly: always use main screen
    static func activeScreen(displayMode: DisplayMode = .activeOnly) -> NSScreen? {
        switch displayMode {
        case .mainOnly:
            return mainScreen()
        case .activeOnly:
            return activeScreenContainingMouse() ?? mainScreen()
        }
    }
}

enum DisplayMode {
    case mainOnly        // Always show overlay on main/primary screen
    case activeOnly      // Show overlay on active screen (where mouse is)
}
