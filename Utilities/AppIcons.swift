import Combine
//
//  AppIcons.swift
//  boringNotch
//
//  Created by Richard Kunkli on 2024-09-08.
//

import AppKit
import SwiftUI

struct AppIcon: View {
    let bundleIdentifier: String
    
    var body: some View {
        if let icon = getAppIcon(bundleIdentifier: bundleIdentifier) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
    
    init(for bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }
    
    private func getAppIcon(bundleIdentifier: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

func getAppIcon(for bundleIdentifier: String) -> NSImage? {
    guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
        return nil
    }
    return NSWorkspace.shared.icon(forFile: appURL.path)
}
