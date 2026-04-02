//
//  BatteryStatusViewModel.swift
//  boringNotch
//
//  Created by Alexander on 2025-08-20.
//

import Foundation
import Combine

class BatteryStatusViewModel: ObservableObject {
    static let shared = BatteryStatusViewModel()
    
    @Published var levelBattery: Double = 100
    @Published var isCharging: Bool = false
    @Published var isPluggedIn: Bool = false
    @Published var timeToFullCharge: Int = 0
    @Published var maxCapacity: Int = 100
    @Published var isInLowPowerMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        updateBatteryStatus()
    }
    
    func updateBatteryStatus() {
        // Battery monitoring will be implemented with BatteryActivityManager
        // For now, provide default values
    }
    
    var statusText: String {
        if isCharging {
            if timeToFullCharge > 0 {
                let hours = timeToFullCharge / 60
                let minutes = timeToFullCharge % 60
                if hours > 0 {
                    return "\(hours)h \(minutes)m until full"
                } else {
                    return "\(minutes)m until full"
                }
            } else {
                return "Charging"
            }
        } else if isPluggedIn {
            return "Plugged in"
        } else {
            let hours = Int(levelBattery * 10) / 60
            let minutes = Int(levelBattery * 10) % 60
            if hours > 0 {
                return "\(hours)h \(minutes)m remaining"
            } else {
                return "\(minutes)m remaining"
            }
        }
    }
    
    var batteryColor: String {
        if isCharging {
            return "green"
        } else if levelBattery < 20 {
            return "red"
        } else if levelBattery < 50 {
            return "orange"
        } else {
            return "white"
        }
    }
}
