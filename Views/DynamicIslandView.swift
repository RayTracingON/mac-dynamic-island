import SwiftUI
import UniformTypeIdentifiers

// MARK: - DynamicIslandView (The Unified Magnetic Capsule)
// ============================================================
// ⚠️ THE SINGLE ROOT CONTAINER - SOURCE OF ALL VISUAL LOGIC
// ============================================================
struct DynamicIslandView: View {
    @EnvironmentObject var appState: AppState
    @Namespace var animation
    
    private var isExpanded: Bool { appState.overlayMode == .expanded }
    
    // CLONED: Boring Notch Physics (Magnetic Feel)
    private let magneticSpring = Animation.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0)
    
    var body: some View {
        ZStack(alignment: .top) {
            // THE UNIFIED CAPSULE - ENFORCING STYLE & CLIPPING
            VStack(spacing: 0) {
                if isExpanded {
                    PurifiedExpandedContent(animation: animation)
                        .frame(width: 640)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity).animation(magneticSpring),
                                removal: .opacity.animation(.easeOut(duration: 0.15))
                            )
                        )
                } else {
                    PurifiedCompactContent()
                        .frame(width: 185, height: 32)
                        .transition(.opacity)
                }
            }
            // 🎨 UNIFIED VISUALS (Locked to black, pure corners)
            .background(.ultraThinMaterial)
            .background(
                ZStack {
                    Color.black.opacity(0.95)
                    if appState.isDraggingOver {
                        Color.blue.opacity(0.2)
                            .blur(radius: 10)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 24 : 16, style: .continuous))
            .shadow(color: appState.isDraggingOver ? Color.blue.opacity(0.4) : .black.opacity(0.4), radius: isExpanded ? 15 : 5, y: 5)
        }
        .contentShape(Rectangle()) // FIX: Entire area is now clickable
        // 🧲 MAGNETIC SQUISH EFFECT (The "Boring" Feel)
        .scaleEffect(appState.isNearIsland && !isExpanded ? 1.12 : 1.0)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2), value: appState.isNearIsland)
        .animation(magneticSpring, value: isExpanded)
        .animation(magneticSpring, value: appState.currentSection)
        .animation(.easeInOut(duration: 0.2), value: appState.isDraggingOver)
        .onTapGesture {
            if !isExpanded {
                withAnimation(magneticSpring) {
                    appState.activateOverlay(reason: .userExpanded)
                }
            }
        }
        // 📁 GLOBAL DROP ZONE: High-priority file handling
        .onDrop(of: [.fileURL, .url], isTargeted: Binding(
            get: { appState.isDraggingOver },
            set: { dragging in
                appState.isDraggingOver = dragging
                if dragging && !isExpanded {
                    // Auto-expand to show the shelf
                    withAnimation(magneticSpring) {
                        appState.currentSection = .files
                        appState.activateOverlay(reason: .userExpanded)
                    }
                }
            }
        )) { providers in
            Task {
                await ShelfStateViewModel.shared.handleDrop(providers: providers)
                if appState.currentSection != .files {
                    withAnimation { appState.currentSection = .files }
                }
            }
            return true
        }
    }
}

// MARK: - Purified Compact Content
struct PurifiedCompactContent: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var musicManager = MusicManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            if musicManager.isPlaying {
                Image(systemName: "waveform")
                    .symbolEffect(.bounce, options: .repeating, value: musicManager.isPlaying)
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text(musicManager.songTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } else {
                // 👀 CUTE EYES RESTORED (Boring Notch Style)
                AnimatedFaceView()
                    .frame(width: 28, height: 14)
                    .opacity(1.0) // Ensure visible
                
                Spacer()
                
                // Only show icon if we have a specific reason or active section hint
                if appState.currentSection != .music {
                     Image(systemName: appState.currentSection.iconName)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 14)
        .background(Color.clear) // PURIFIED: NO BACKGROUND
    }
}

// MARK: - Purified Expanded Content
struct PurifiedExpandedContent: View {
    @EnvironmentObject var appState: AppState
    var animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Tabs
            HStack(spacing: 12) {
                ForEach(AppState.IslandSection.allCases, id: \.self) { section in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            appState.currentSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.iconName)
                                .font(.system(size: 11))
                            if appState.currentSection == section {
                                Text(section.displayName).font(.system(size: 11, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(appState.currentSection == section ? Color.white.opacity(0.1) : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(appState.currentSection == section ? .white : .gray)
                }
                Spacer()
                Button { appState.deactivateOverlay() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            
            // CONTENT RECEPTACLE (All child views must be transparent)
            Group {
                switch appState.currentSection {
                case .music:
                    ExpandedMusicView(musicManager: MusicManager.shared, animation: animation)
                case .clipboard:
                    ClipboardHubView(vault: appState.clipVault)
                case .files:
                    ShelfView()
                case .calendar:
                    CalendarView()
                case .zone3:
                    Zone3ContentView(onClose: { appState.deactivateOverlay() })
                        .environmentObject(appState.fileVault)
                        .environmentObject(appState.clipboardHistory)
                }
            }
            .frame(height: 188)
            .background(Color.clear) // PURIFIED: NO BACKGROUND
        }
        .background(Color.clear) // PURIFIED: NO BACKGROUND
    }
}
