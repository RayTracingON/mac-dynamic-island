import Combine
//
//  ApplicationRelauncher.swift
//  boringNotch
//
//  Created by Richard Kunkli on 2024-10-13.
//

import Foundation
import AppKit

class ApplicationRelauncher {
    static func restart() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.2; open '\(Bundle.main.bundlePath)'"]
        task.launch()
        NSApp.terminate(nil)
    }
}
