import SwiftUI

/// Wrapper view was replacing NotchHomeView.
/// This file is now deprecated as the functionality has moved to DynamicIslandView.
/// Kept as placeholder to prevent build errors.
struct NotchContentWrapper: View {
    // These properties kept just in case some legacy code tries to inject them
    @EnvironmentObject private var vm: BoringViewModel
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        // Return clear color to be invisible if accidentally used
        Color.clear
            .frame(width: 0, height: 0)
    }
}
