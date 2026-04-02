
//
//  SettingsPickerRow.swift
//  Mac灵动岛
//
//  Created by User on 2026-01-23.
//

import SwiftUI

struct SettingsPickerRow<T: Hashable>: View {
    let key: SettingsKey<T>
    let title: String
    let options: [T: String] // Value : Display Name
    let help: String
    
    @State private var selectedValue: T
    
    // Sort options by key (if T is Comparable) or just iterate
    // Since Dictionary is unordered, we might want an ordered list of keys if order matters.
    // However, for T=Int options like [0, 1, 2], simple keys sorting usually works.
    
    init(key: SettingsKey<T>, title: String, options: [T: String], help: String) {
        self.key = key
        self.title = title
        self.options = options
        self.help = help
        _selectedValue = State(initialValue: SettingsDefaults.shared.get(key))
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: $selectedValue) {
                // Try to sort keys if they are comparable (like Int), otherwise random order
                // Quick hack for Int keys which is our current use case (0,1,2)
                ForEach(options.keys.sorted { "\($0)" < "\($1)" }, id: \.self) { optKey in
                    Text(options[optKey] ?? "").tag(optKey)
                }
            }
            .labelsHidden()
            .frame(width: 150)
        }
        .help(help)
        .onChange(of: selectedValue) { _, newValue in
            SettingsDefaults.shared.set(key, value: newValue)
        }
    }
}
