//
//  ContentView.swift
//  Revless
//
//  Created by Atif Khan on 2026-03-28.
//

import SwiftUI

struct ContentView: View {

    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            if auth.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
        .environment(RecentSearchStore())
}
