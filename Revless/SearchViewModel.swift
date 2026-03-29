// SearchViewModel.swift
// Revless
//
// Manages all state for the Search & Discover flow.
// Owned by SearchFormView and shared by reference with RouteResultsView.

import Foundation
import Observation

@Observable
final class SearchViewModel {

    // MARK: - Search inputs

    var origin: String      = "YYZ"
    var destination: String = "KUL"
    var departureDate: Date = {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }()
    var travelerType: TravelerType = .companion

    // MARK: - Results

    var itineraries: [Itinerary] = []
    var totalRaw: Int      = 0
    var totalFiltered: Int = 0

    // MARK: - UI state

    var isLoading: Bool       = false
    var errorMessage: String? = nil

    /// Triggered by a 402 response — drives the "out of credits" alert on SearchFormView.
    var showOutOfCreditsAlert: Bool = false

    // Tracks the stale rule the user is currently verifying
    var selectedStaleRule: StaleRule? = nil

    // Tracks which itinerary triggered the verification modal (so we can
    // display the traveler-type context inside VerificationModal)
    var verifyingTravelerType: TravelerType = .companion

    // MARK: - Computed helpers

    var hasResults: Bool { !itineraries.isEmpty }

    var filteredBanner: String {
        guard totalRaw > 0 else { return "" }
        let dropped = totalRaw - totalFiltered
        if dropped == 0 { return "All \(totalRaw) route\(totalRaw == 1 ? "" : "s") eligible" }
        return "\(totalFiltered) of \(totalRaw) routes eligible · \(dropped) filtered"
    }

    // MARK: - Date formatter (shared, thread-safe after init)

    private static let apiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale     = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Airport swap

    func swapAirports() {
        let tmp   = origin
        origin      = destination
        destination = tmp
    }

    // MARK: - Fetch routes

    /// `auth` is passed so credits can be decremented optimistically after a
    /// successful search, keeping the Home dashboard number in sync without
    /// waiting for the next /auth/me round-trip.
    func fetchRoutes(auth: AuthViewModel) async {
        isLoading             = true
        errorMessage          = nil
        showOutOfCreditsAlert = false
        defer { isLoading = false }

        let dateString = Self.apiDateFormatter.string(from: departureDate)
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "origin",        value: origin.uppercased().trimmingCharacters(in: .whitespaces)),
            URLQueryItem(name: "destination",   value: destination.uppercased().trimmingCharacters(in: .whitespaces)),
            URLQueryItem(name: "date",          value: dateString),
            URLQueryItem(name: "traveler_type", value: travelerType.rawValue),
        ]

        do {
            let response: RouteSearchResponse = try await NetworkManager.shared.get(
                "search/routes",
                queryItems: queryItems
            )
            itineraries   = response.itineraries
            totalRaw      = response.totalRaw
            totalFiltered = response.totalFiltered

            // Optimistically mirror the -1 deduction the backend just applied.
            // The .contentTransition(.numericText()) on the dashboard animates this.
            if let user = auth.currentUser, user.searchCredits > 0 {
                auth.currentUser?.searchCredits = user.searchCredits - 1
            }
        } catch NetworkError.paymentRequired {
            showOutOfCreditsAlert = true
        } catch let error as NetworkError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to fetch routes. Please try again."
        }
    }

    // MARK: - Verification

    /// Called by VerificationModal. Submits the crowdsourced answer, refreshes
    /// routes so badge states update, and pulls fresh user credits from /auth/me
    /// so the dashboard balance reflects the +5 reward immediately.
    func submitVerification(ruleId: UUID, isAccurate: Bool, auth: AuthViewModel) async {
        let body = AgreementVerificationRequest(ruleId: ruleId, isAccurate: isAccurate)
        do {
            let _: AgreementVerificationResponse = try await NetworkManager.shared.post(
                "agreements/verify",
                body: body
            )
        } catch {
            // Non-critical — still refresh routes and credits
        }
        await fetchRoutes(auth: auth)
        await auth.refreshCurrentUser()
    }
}
