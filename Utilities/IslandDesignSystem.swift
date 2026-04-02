import SwiftUI

// MARK: - 灵动岛设计系统
// 基于 iPhone Dynamic Island 设计理念的完整规范

/// 灵动岛设计令牌 - 所有视觉参数的唯一来源
enum IslandDesign {
    
    // MARK: - 1) 几何参数（iPhone 灵动岛精确比例）
    // iPhone 原始: 紧凑 126×37, 展开 350×160
    // Mac 缩放: 1.3x (考虑观看距离)
    
    enum Geometry {
        // =====================================================
        // 紧凑模式（Compact）- 动态适配 MacBook 硬件刘海
        // Source: boring.notch/sizing/matters.swift - getClosedNotchSize()
        // =====================================================
        
        /// 获取当前屏幕刘海的动态尺寸
        static func dynamicCompactSize(for screen: NSScreen?) -> CGSize {
            guard let screen = screen else { return CGSize(width: 185, height: 32) }
            
            var notchWidth: CGFloat = 185
            var notchHeight: CGFloat = 32
            
            // 1. 计算宽度：利用 auxiliaryTopLeftArea (仅 macOS 12+)
            // Source: matters.swift lines 45-48
            if #available(macOS 12.0, *) {
                if let leftWidth = screen.auxiliaryTopLeftArea?.width,
                   let rightWidth = screen.auxiliaryTopRightArea?.width {
                    // 刘海宽度 = 屏幕宽度 - 左侧可用区 - 右侧可用区 + 修正值
                    notchWidth = screen.frame.width - leftWidth - rightWidth + 4
                }
            }
            
            // 2. 计算高度：如果有刘海，使用 safeAreaInsets.top
            // Source: matters.swift lines 51-59
            if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
                notchHeight = screen.safeAreaInsets.top
            } else {
                // 无刘海屏幕使用菜单栏高度
                notchHeight = screen.frame.maxY - screen.visibleFrame.maxY
            }
            
            return CGSize(width: max(120, notchWidth), height: max(24, notchHeight))
        }

        static let compactWidth: CGFloat = 185    // 默认回退值
        static let compactHeight: CGFloat = 32    // 默认回退值
        static let compactCornerRadius: CGFloat = 14  // 匹配 closed.bottom
        
        // =====================================================
        // 展开模式（Expanded）- 精确匹配 Boring Notch
        // Source: boring.notch/sizing/matters.swift lines 11-13
        // let openNotchSize: CGSize = .init(width: 640, height: 190)
        // let shadowPadding: CGFloat = 20
        // let windowSize = CGSize(width: 640, height: 210)
        // =====================================================
        static let expandedWidth: CGFloat = 640
        static let expandedHeight: CGFloat = 190   // 精确值: 190
        static let expandedCornerRadius: CGFloat = 24  // 匹配 opened.bottom
        
        static let shadowPadding: CGFloat = 20
        static var windowWidth: CGFloat { expandedWidth }
        static var windowHeight: CGFloat { expandedHeight + shadowPadding }
        
        // =====================================================
        // 圆角参数 - 精确匹配 Boring Notch
        // Source: matters.swift line 14
        // cornerRadiusInsets = (opened: (top: 19, bottom: 24), closed: (top: 6, bottom: 14))
        // =====================================================
        static let cornerRadiusOpened: (top: CGFloat, bottom: CGFloat) = (19, 24)
        static let cornerRadiusClosed: (top: CGFloat, bottom: CGFloat) = (6, 14)
        
        static let compactPadding: CGFloat = 4
        static let expandedPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 10
        
        static let albumArtCompact: CGFloat = 22
        static let albumArtExpanded: CGFloat = 80
        
        // 图标尺寸
        static let iconSizeSmall: CGFloat = 12
        static let iconSizeMedium: CGFloat = 16
        static let iconSizeLarge: CGFloat = 24
    }
    
    // MARK: - 2) 颜色系统（硬件黑 + 高对比）
    
    enum Colors {
        // 核心色
        static let hardwareBlack = Color.black                      // 硬件黑（针对物理刘海）
        static let surfaceBlack = Color(white: 0.08)               // 表面黑
        
        // 1px Subtle Border
        static let borderAlpha: Double = 0.15
        static let borderWhite = Color.white.opacity(borderAlpha)
        static let borderBlack = Color.black.opacity(0.3)
        
        // 文字层级
        static let textPrimary = Color.white                        // 主要文字
        static let textSecondary = Color.white.opacity(0.7)        // 次要文字
        static let textTertiary = Color.white.opacity(0.45)        // 辅助文字
        
        // 交互反馈
        static let hoverOverlay = Color.white.opacity(0.1)         // 悬停态
        static let pressedOverlay = Color.white.opacity(0.18)      // 按压态
        static let activeAccent = Color(red: 0.0, green: 0.48, blue: 1.0)  // 系统蓝
        
        // 状态指示器
        static let statusPlaying = Color.green                      // 播放中
        static let statusRecording = Color.red                      // 录音中
        static let statusActive = Color.orange                      // 活动中
        static let statusIdle = Color.gray                          // 空闲
    }
    
    // MARK: - 3) 动效参数（参考 BoringViewModel）
    
    enum Motion {
        // 展开动画 - 0.42 / 0.8
        static var expandAnimation: Animation {
            .spring(response: 0.42, dampingFraction: 0.8)
        }
        
        // 收起动画 - 0.45 / 1.0
        static var collapseAnimation: Animation {
            .spring(response: 0.45, dampingFraction: 1.0)
        }
        
        // 内容切换动画
        static var contentTransition: Animation {
            .easeInOut(duration: 0.25)
        }
        
        // 悬停反馈
        static var hoverAnimation: Animation {
            .easeOut(duration: 0.12)
        }
        
        // 按压反馈
        static var pressAnimation: Animation {
            .easeOut(duration: 0.08)
        }
        
        // 时长参数（毫秒）
        static let expandDuration: Double = 420
        static let collapseDuration: Double = 450
        static let contentFadeDuration: Double = 150
    }
    
    // MARK: - 4) 字体系统（SF Pro 层级）
    
    enum Typography {
        // 紧凑模式
        static let compactTitle = Font.system(size: 13, weight: .medium)
        static let compactSubtitle = Font.system(size: 11, weight: .regular)
        static let compactValue = Font.system(size: 13, weight: .semibold, design: .rounded)
        
        // 展开模式
        static let expandedTitle = Font.system(size: 14, weight: .semibold)
        static let expandedSubtitle = Font.system(size: 12, weight: .regular)
        static let expandedBody = Font.system(size: 13, weight: .regular)
        
        // 数值/时间
        static let timeDisplay = Font.system(size: 12, weight: .medium, design: .monospaced)
    }
}

// MARK: - 5) 可复用视觉组件

/// 灵动岛按钮样式 - 立即反馈、无延迟
struct IslandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(IslandDesign.Motion.pressAnimation, value: configuration.isPressed)
    }
}

/// 灵动岛图标按钮
struct IslandIconButton: View {
    let icon: String
    var size: CGFloat = IslandDesign.Geometry.iconSizeMedium
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            action()
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(isActive ? IslandDesign.Colors.activeAccent : IslandDesign.Colors.textPrimary)
                .frame(width: size + 16, height: size + 16)
                .background(
                    Circle()
                        .fill(isHovered ? IslandDesign.Colors.hoverOverlay : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(IslandButtonStyle())
        .onHover { hovering in
            withAnimation(IslandDesign.Motion.hoverAnimation) {
                isHovered = hovering
            }
        }
    }
}

/// 灵动岛进度条（最小信息原则）
struct IslandProgressBar: View {
    let progress: Double  // 0.0 ~ 1.0
    var height: CGFloat = 3
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 背景轨道
                Capsule()
                    .fill(IslandDesign.Colors.textTertiary)
                    .frame(height: height)
                
                // 进度
                Capsule()
                    .fill(IslandDesign.Colors.textPrimary)
                    .frame(width: geo.size.width * min(max(progress, 0), 1), height: height)
            }
        }
        .frame(height: height)
    }
}

/// 灵动岛状态点（播放/录音/活动指示）
struct IslandStatusDot: View {
    enum Status {
        case idle, playing, recording, active
        
        var color: Color {
            switch self {
            case .idle: return IslandDesign.Colors.statusIdle
            case .playing: return IslandDesign.Colors.statusPlaying
            case .recording: return IslandDesign.Colors.statusRecording
            case .active: return IslandDesign.Colors.statusActive
            }
        }
    }
    
    let status: Status
    var size: CGFloat = 8
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(status.color)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing && status == .recording ? 1.2 : 1.0)
            .animation(
                status == .recording 
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - 6) 容器修饰器

extension View {
    /// 应用灵动岛容器样式
    func islandContainer(isExpanded: Bool) -> some View {
        self
            .padding(isExpanded ? IslandDesign.Geometry.expandedPadding : IslandDesign.Geometry.compactPadding)
            .background(
                RoundedRectangle(
                    cornerRadius: isExpanded 
                        ? IslandDesign.Geometry.expandedCornerRadius 
                        : IslandDesign.Geometry.compactCornerRadius,
                    style: .continuous
                )
                .fill(IslandDesign.Colors.hardwareBlack)
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: isExpanded 
                        ? IslandDesign.Geometry.expandedCornerRadius 
                        : IslandDesign.Geometry.compactCornerRadius,
                    style: .continuous
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: isExpanded 
                        ? IslandDesign.Geometry.expandedCornerRadius 
                        : IslandDesign.Geometry.compactCornerRadius,
                    style: .continuous
                )
            )
    }
}
