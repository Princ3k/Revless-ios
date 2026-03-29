//
//  ContentView.swift
//  Revless
//
//  Created by Atif Khan on 2026-03-28.
//

import SwiftUI

struct ContentView: View {

    @Environment(AuthViewModel.self) private var auth

    /// Persists across launches via UserDefaults. Set to true when the user
    /// taps "Start Exploring" on the final onboarding slide.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        // Shown once on first launch, regardless of auth state.
        // Binding inverts hasSeenOnboarding so the cover is presented when false.
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { _ in }
        )) {
            OnboardingView {
                withAnimation(.easeInOut(duration: 0.4)) {
                    hasSeenOnboarding = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
