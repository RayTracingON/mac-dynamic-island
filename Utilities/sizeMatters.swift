import Combine
//
//  sizeMatters.swift
//  boringNotch
//
//  Created by Richard Kunkli on 06/10/2024.
//

import Foundation
import AppKit

func getClosedNotchSize(screenUUID: String? = nil) -> CGSize {
    let screen: NSScreen
    
    if let uuid = screenUUID {
        screen = NSScreen.screen(withUUID: uuid) ?? NSScreen.main ?? NSScreen.screens.first!
    } else {
        screen = NSScreen.main ?? NSScreen.screens.first!
    }
    
    if #available(macOS 12.0, *) {
        let topInset = screen.safeAreaInsets.top
        if topInset > 0 {
            // 真实刘海存在 - 使用与 boring.notch 一致的标准宽度
            // boring.notch 使用约 185pt 宽度匹配真实 MacBook 刘海
            let standardNotchWidth: CGFloat = 185
            return CGSize(width: standardNotchWidth, height: topInset)
        }
    }
    
    // 无刘海设备 - 使用默认尺寸（与 boring.notch 一致的 38pt 高度）
    return CGSize(width: 185, height: 38)
}

func deviceHasNotch(screen: NSScreen? = nil) -> Bool {
    let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
    guard let targetScreen = targetScreen else { return false }
    
    if #available(macOS 12.0, *) {
        return targetScreen.safeAreaInsets.top > 0
    }
    return false
}

func getNotchHeight(for screen: NSScreen? = nil) -> CGFloat {
    let targetScreen = screen ?? NSScreen.main ?? NSScreen.screens.first
    guard let targetScreen = targetScreen else { return 0 }
    
    if #available(macOS 12.0, *) {
        return targetScreen.safeAreaInsets.top
    }
    return 0
}
