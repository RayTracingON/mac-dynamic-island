//
//  SneakContentType.swift
//  Mac灵动岛
//
//  Stage 1: Sneak peek notification types
//

import Foundation

enum SneakContentType: Equatable {
    case none
    case music
    case download(String, Float, String) // filename, progress, speed
    case volume
    case brightness
    case backlight
    case mic
    case battery
    
    static func == (lhs: SneakContentType, rhs: SneakContentType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.music, .music),
             (.volume, .volume),
             (.brightness, .brightness),
             (.backlight, .backlight),
             (.mic, .mic),
             (.battery, .battery):
            return true
        case (.download(let lName, let lProgress, let lSpeed),
              .download(let rName, let rProgress, let rSpeed)):
            return lName == rName && lProgress == rProgress && lSpeed == rSpeed
        default:
            return false
        }
    }
}

// MARK: - Sneak Peek Styles

enum SneakPeekStyle: String, Codable, CaseIterable {
    case standard = "Standard"
    case inline = "Inline"
}
