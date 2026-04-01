//
//  RevlessApp.swift
//  Revless
//
//  Created by Atif Khan on 2026-03-28.
//

import SwiftUI

@main
struct RevlessApp: App {

    @State private var auth = AuthViewModel()
    @State private var recentSearchStore = RecentSearchStore()
    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
                .environment(recentSearchStore)
                .environment(themeManager)
                // Update theme whenever the authenticated user changes
                .onChange(of: auth.currentUser?.email) { _, email in
                    themeManager.update(for: email)
                }
        }
    }
}
