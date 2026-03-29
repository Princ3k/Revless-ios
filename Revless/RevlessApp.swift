//
//  RevlessApp.swift
//  Revless
//
//  Created by Atif Khan on 2026-03-28.
//

import SwiftUI

@main
struct RevlessApp: App {

    /// Single source of truth for authentication state.
    /// @State on App owns the instance; .environment() makes it available
    /// to every view in the hierarchy via @Environment(AuthViewModel.self).
    @State private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
    }
}
