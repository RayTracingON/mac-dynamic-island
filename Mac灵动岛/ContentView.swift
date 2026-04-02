//
//  ContentView.swift
//  Mac灵动岛
//
//  Created by apple密码1111 on 2026/1/5.
//

import SwiftUI

struct DefaultContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .sheet(isPresented: $appState.isOnboardingPresented) {
            OnboardingView()
                .environmentObject(appState)
        }
        .onAppear {
            if appState.settings.showOnboarding && !appState.isOnboardingPresented {
                appState.isOnboardingPresented = true
            }
        }
    }
}

#Preview {
    DefaultContentView()
}
