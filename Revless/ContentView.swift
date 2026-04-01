//
//  ContentView.swift
//  Revless
//
//  Created by Atif Khan on 2026-03-28.
//

import SwiftUI

struct ContentView: View {

    @Environment(AuthViewModel.self) private var auth

    private let accentBlue = Color(red: 0.38, green: 0.44, blue: 0.98)

    var body: some View {
        Group {
            if auth.isAuthenticated {
                if auth.currentUser == nil {
                    profileLoadingOrError
                } else if auth.currentUser?.tenantId == nil {
                    NavigationStack {
                        TenantRequestGateView()
                    }
                } else {
                    MainTabView()
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: auth.currentUser?.tenantId)
    }

    @ViewBuilder
    private var profileLoadingOrError: some View {
        ZStack {
            Color(red: 0.04, green: 0.06, blue: 0.14).ignoresSafeArea()
            if let msg = auth.profileError {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(accentBlue.opacity(0.8))
                    Text(msg)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try again") {
                        Task { await auth.loadProfileIfNeeded() }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentBlue)
                    Button("Sign out", role: .cancel) { auth.logout() }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
            } else {
                ProgressView("Loading profile…")
                    .tint(accentBlue)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await auth.loadProfileIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
        .environment(RecentSearchStore())
        .environment(ThemeManager())
}
