//
//  ContentType.swift
//  Mac灵动岛
//
//  Stage 1: Core enums from boringNotch
//

import Foundation

// MARK: - NotchState

enum NotchState: Equatable {
    case closed
    case open
}

// MARK: - NotchViews

enum NotchViews: String, CaseIterable {
    case home
    case shelf
    case music
    case calendar
    case settings
}

// MARK: - Style

enum Style: String, Codable, CaseIterable {
    case shadowed = "Shadowed"
    case floating = "Floating"
}

// MARK: - ContentType

enum ContentType: String, CaseIterable, Identifiable {
    case none = "None"
    case music = "Music"
    case download = "Download"
    case mic = "Microphone"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .music: return "Music"
        case .download: return "Download"
        case .mic: return "Microphone"
        }
    }
}

// MARK: - SliderColorEnum

enum SliderColorEnum: String, Codable, CaseIterable {
    case albumArt = "Album Art"
    case accent = "Accent"
    case white = "White"
}
