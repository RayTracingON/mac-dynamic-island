import SwiftUI
import Combine

/// Main integrated content view with all features
/// Supports compact (pill) and expanded (panel) modes
/// Includes: Music, Clipboard, Files, Zone3
struct IntegratedContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var musicManager = MusicManager.shared
    @Namespace var animation // Namespace
    
    // Explicitly reference the Unified Container's implementation if using it,
    // OR create a legacy version here if this file is still needed for something else.
    // Given the architecture shift, this file might be deprecated, but to fix the build error
    // while keeping it, we rename the internal struct.
    
    private var isExpanded: Bool {
        appState.overlayMode == .expanded
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // 展开模式：显示完整功能
                LegacyExpandedContentView()
            } else {
                // 紧凑模式：显示音乐播放器或等待提示
                LegacyCompactPillView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: isExpanded ? 20 : 24, style: .continuous)
                .fill(Color.black.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: isExpanded ? 20 : 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 15, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
    }
}

// MARK: - Legacy Compact Pill View (Renamed)

private struct LegacyCompactPillView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var musicManager = MusicManager.shared
    
    var body: some View {
        HStack(spacing: 10) {
            if !musicManager.isPlayerIdle {
                // 音乐正在播放 - 显示专辑封面和控制
                LegacyCompactMusicPill()
            } else {
                // 普通模式
                defaultPillContent
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                appState.activateOverlay(reason: .userExpanded)
            }
        }
    }
    
    private var defaultPillContent: some View {
        HStack(spacing: 10) {
            // 状态指示器
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // 标题
            Text(appState.localizedTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // 当前区域图标
            Image(systemName: appState.currentSection.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var statusColor: Color {
        switch appState.payload {
        case .none: return .gray
        case .clipboard: return .green
        case .file, .url: return .blue
        case .text: return .orange
        }
    }
}

// MARK: - Legacy Compact Music Pill (Renamed)

private struct LegacyCompactMusicPill: View {
    @ObservedObject private var musicManager = MusicManager.shared
    
    var body: some View {
        HStack(spacing: 10) {
            // 专辑封面
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 2) {
                Text(musicManager.songTitle)
                // ... (rest of implementation)
            }
        }
    }
}

// MARK: - Legacy Expanded Content View (Renamed to fix redeclaration error)

private struct LegacyExpandedContentView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var musicManager = MusicManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            SectionTabBar()
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // 主内容区域
            SectionContentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Section Tab Bar (区域选项卡)

private struct SectionTabBar: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppState.IslandSection.allCases, id: \.self) { section in
                IntegratedSectionTab(section: section)
            }
            
            Spacer()
            
            // 关闭按钮
            Button {
                withAnimation(.spring(response: 0.3)) {
                    appState.deactivateOverlay()
                }
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .contentShape(Circle())
            }
            .buttonStyle(IntegratedButtonStyle())
        }
    }
}

private struct IntegratedSectionTab: View {
    @EnvironmentObject private var appState: AppState
    let section: AppState.IslandSection
    
    @State private var isHovered = false
    
    private var isSelected: Bool {
        appState.currentSection == section
    }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.currentSection = section
            }
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: section.iconName)
                    .font(.system(size: 12, weight: .medium))
                
                Text(section.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.15) : (isHovered ? Color.white.opacity(0.08) : Color.clear))
            )
            .foregroundColor(isSelected ? .white : .white.opacity(isHovered ? 0.8 : 0.6))
            .contentShape(Rectangle())
        }
        .buttonStyle(IntegratedButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Section Content View (内容视图)

private struct SectionContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        switch appState.currentSection {
        case .music:
            // 音乐播放器 (Placeholder for legacy view)
             Text("Music Player")
        case .clipboard:
            // 剪贴板历史
            ClipboardSectionView()
        case .files:
            // 文件岛
            FilesSectionView()
        case .calendar:
            // 日历视图
             CalendarView()
        case .zone3:
            // 自定义区域
            Zone3SectionView()
        }
    }
}

// MARK: - Legacy Button Style

private struct IntegratedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Legacy Clipboard Section

private struct ClipboardSectionView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 12) {
             Text("Clipboard Section")
        }
        .padding(12)
    }
}

// MARK: - Legacy Files Section

private struct FilesSectionView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 12) {
             Text("Files Section")
        }
        .padding(12)
    }
}

// MARK: - Legacy Zone3 Section

private struct Zone3SectionView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Text("Zone 3")
        .padding(12)
    }
}
