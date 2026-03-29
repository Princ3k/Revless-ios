// RouteResultsView.swift
// Revless
//
// Displays the filtered itinerary list returned by the Eligibility Engine.
// Tapping a card with requires_verification == true opens VerificationModal.

import SwiftUI

struct RouteResultsView: View {

    @Bindable var viewModel: SearchViewModel
    @Environment(AuthViewModel.self) private var auth

    // MARK: - Palette
    //
    // Deep navy → dark indigo-purple. The gradient bleeds through the
    // ultraThinMaterial on each ItineraryCard, giving the frosted-glass
    // effect real depth against a non-black background.

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top,
        endPoint: .bottom
    )
    private let subtleText  = Color.white.opacity(0.45)
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if viewModel.isLoading && viewModel.itineraries.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if viewModel.itineraries.isEmpty {
                emptyView
            } else {
                resultsList
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color(hex: "#0A0E17"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        // Fetch on first appearance
        .task { await viewModel.fetchRoutes(auth: auth) }
        // VerificationModal sheet — driven by viewModel.selectedStaleRule
        .sheet(item: $viewModel.selectedStaleRule) { rule in
            VerificationModal(
                rule: rule,
                travelerType: viewModel.travelerType
            ) { isAccurate in
                Task {
                    await viewModel.submitVerification(ruleId: rule.ruleId, isAccurate: isAccurate, auth: auth)
                }
            }
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                statsHeader
                    .padding(.top, 4)

                ForEach(viewModel.itineraries) { itinerary in
                    ItineraryCard(itinerary: itinerary) { rule in
                        // When user taps the yellow badge, store the rule and
                        // the traveler type so VerificationModal has both
                        viewModel.verifyingTravelerType = viewModel.travelerType
                        viewModel.selectedStaleRule = rule
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                        .tint(accentColor)
                        .padding()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Stats header

    private var statsHeader: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.filteredBanner)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(viewModel.origin) → \(viewModel.destination)")
                    .font(.caption)
                    .foregroundStyle(subtleText)
            }
            Spacer()
            // Refresh button
            Button {
                Task { await viewModel.fetchRoutes(auth: auth) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(accentColor)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Loading state

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(accentColor)
            Text("Searching eligible routes…")
                .font(.subheadline)
                .foregroundStyle(subtleText)
        }
    }

    // MARK: - Empty state

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(accentColor.opacity(0.6))

            VStack(spacing: 6) {
                Text("No eligible routes")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("All itineraries were filtered by your\ncurrent agreement rules.")
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.fetchRoutes(auth: auth) }
            } label: {
                Text("Try Again")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Error state

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(.orange.opacity(0.8))

            VStack(spacing: 6) {
                Text("Something went wrong")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.fetchRoutes(auth: auth) }
            } label: {
                Text("Retry")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.orange.opacity(0.30), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Color(hex:) convenience initialiser

private extension Color {
    /// Accepts "#RRGGBB", "RRGGBB", "#RGB", or "RGB" hex strings.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r, g, b: UInt64
        switch hex.count {
        case 3:
            (r, g, b) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:
            (r, g, b) = (value >> 16, value >> 8 & 0xFF, value & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: 1)
    }
}
