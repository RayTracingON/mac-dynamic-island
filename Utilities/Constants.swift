//
//  Constants.swift
//  Mac灵动岛
//
//  Stage 1: Global constants from boringNotch
//

import Foundation
import AppKit
import SwiftUI

// MARK: - Window Sizing

/// 窗口总尺寸 - 需足够大以容纳展开状态
let windowSize = CGSize(width: 900, height: 350)

/// 展开后的灵动岛尺寸 - 比 boring.notch (660x250) 更大以容纳剪切板历史功能
let openNotchSize = CGSize(width: 700, height: 280)

// MARK: - Corner Radius
// Note: CornerRadiusInsets is defined in Animations/BoringAnimationPhysics.swift
// to avoid duplicate declarations

// MARK: - Music Player Sizing
// Note: MusicPlayerImageSizes is defined in Animations/BoringAnimationPhysics.swift
// to avoid duplicate declarations
