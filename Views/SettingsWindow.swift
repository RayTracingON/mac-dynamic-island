import SwiftUI

struct SettingsWindow: View {
    @State private var selectedTab = "general"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag("general")
            
            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "eye")
                }
                .tag("appearance")
            
            MediaSettingsView()
                .tabItem {
                    Label("Media", systemImage: "play.tv")
                }
                .tag("media")
            
            CalendarSettingsView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag("calendar")
            
            HUDSettingsView()
                .tabItem {
                    Label("HUD", systemImage: "sun.max")
                }
                .tag("hud")
            
            BatterySettingsView()
                .tabItem {
                    Label("Battery", systemImage: "battery.100")
                }
                .tag("battery")
            
            ClipboardSettingsWindow(hubStore: OverlayWindowController.shared.getAppState().clipVault)
                .tabItem {
                    Label("Clipboard", systemImage: "doc.on.clipboard")
                }
                .tag("clipboard")
            
            ShelfSettingsView()
                .tabItem {
                    Label("Shelf", systemImage: "tray.full")
                }
                .tag("shelf")
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag("shortcuts")
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag("advanced")
                
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag("about")
        }
        .frame(width: 700, height: 500) // Increased size slightly for more content
        .padding()
    }
}

#Preview {
    SettingsWindow()
}
