// AuthViewModel.swift
// Revless
//
// Authentication state manager using the iOS 17 @Observable macro.
// Owns the JWT lifecycle: login → Keychain storage → app-wide auth flag.
//
// Usage in views:
//   @Environment(AuthViewModel.self) private var auth
//   @Bindable var auth = ...   (when you need two-way bindings)

import SwiftUI
import Observation

@Observable
final class AuthViewModel {

    // MARK: - Published state

    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentUser: User? = nil

    // MARK: - Init

    init() {
        // Restore session if a valid token is already stored
        isAuthenticated = KeychainHelper.get(KeychainHelper.jwtTokenKey) != nil
    }

    // MARK: - Auth actions

    /// Authenticate with the backend and persist the JWT on success.
    @MainActor
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await NetworkManager.shared.login(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
            KeychainHelper.save(response.accessToken, for: KeychainHelper.jwtTokenKey)
            isAuthenticated = true
            // Eagerly fetch the user profile so views can access tenant_id / credits
            await fetchCurrentUser()
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }

    /// Register a new account, then auto-login so the user lands directly in the app.
    @MainActor
    func register(email: String, password: String, confirmPassword: String) async {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let _ = try await NetworkManager.shared.register(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                password: password
            )
            // Auto-login so user is immediately in the app after registration
            await login(email: email, password: password)
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Registration failed. Please try again."
        }
    }

    /// Sign out: wipe the Keychain token and reset all state.
    func logout() {
        KeychainHelper.delete(KeychainHelper.jwtTokenKey)
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }

    // MARK: - Private helpers

    @MainActor
    private func fetchCurrentUser() async {
        do {
            currentUser = try await NetworkManager.shared.getMe()
        } catch {
            // Non-fatal — dashboard degrades gracefully to default values.
        }
    }

    /// Call this after a verification so the credit balance refreshes immediately.
    @MainActor
    func refreshCurrentUser() async {
        await fetchCurrentUser()
    }
}
