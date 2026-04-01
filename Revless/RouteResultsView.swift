// RouteResultsView.swift
// Revless
//
// Displays the filtered itinerary list returned by the Eligibility Engine.
// Tapping a card with requires_verification == true opens VerificationModal.

import SwiftUI

struct RouteResultsView: View {

    @Bindable var viewModel: SearchViewModel
    @Environment(AuthViewModel.self) private var auth
    @Environment(RecentSearchStore.self) private var recentActivity
    @Environment(ThemeManager.self) private var theme

    private let subtleText  = Color.white.opacity(0.45)
    private var accentColor: Color { theme.accent }

    // MARK: - Body

    var body: some View {
        ZStack {
            AtmosphericBackground()

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
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task { await viewModel.fetchRoutes(auth: auth, recentActivity: recentActivity) }
        .sheet(item: $viewModel.selectedStaleRule) { rule in
            VerificationModal(
                rule: rule,
                travelerType: viewModel.travelerType
            ) { isAccurate in
                Task {
                    await viewModel.submitVerification(
                        ruleId: rule.ruleId,
                        isAccurate: isAccurate,
                        auth: auth,
                        recentActivity: recentActivity
                    )
                }
            }
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                statsHeader.padding(.top, 4)

                ForEach(viewModel.itineraries) { itinerary in
                    ItineraryCard(itinerary: itinerary) { rule in
                        viewModel.verifyingTravelerType = viewModel.travelerType
                        viewModel.selectedStaleRule = rule
                    }
                }

                if viewModel.isLoading {
                    ProgressView().tint(accentColor).padding()
                }

                decisionSupportDisclaimer
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
            Button {
                HapticEngine.select()
                Task { await viewModel.fetchRoutes(auth: auth, recentActivity: recentActivity) }
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

    // MARK: - Loading state (TakeoffLoader replaces ProgressView)

    private var loadingView: some View {
        VStack(spacing: 32) {
            TakeoffLoader(message: "Searching eligible routes…")
            decisionSupportDisclaimer
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Empty state (aviation-themed illustration)

    private var emptyView: some View {
        VStack(spacing: 0) {
            Spacer()

            // SVG-style scene drawn with SwiftUI shapes
            BoredomPilotIllustration()
                .frame(width: 220, height: 160)
                .padding(.bottom, 28)

            VStack(spacing: 8) {
                Text("Nothing on the gate board.")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("All itineraries were filtered by your agreement rules — or no ZED agreements exist for this route pair.")
                    .font(.system(size: 14))
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 28)

            Button {
                HapticEngine.select()
                Task { await viewModel.fetchRoutes(auth: auth, recentActivity: recentActivity) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Try a different hub")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(accentColor.opacity(0.35), lineWidth: 0.5)
                        }
                }
            }
            .buttonStyle(.plain)

            Spacer().frame(height: 24)
            decisionSupportDisclaimer.padding(.horizontal, 40)
            Spacer()
        }
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
                HapticEngine.select()
                Task { await viewModel.fetchRoutes(auth: auth, recentActivity: recentActivity) }
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

            decisionSupportDisclaimer.padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }

    private var decisionSupportDisclaimer: some View {
        Text(
            "Revless uses crowdsourced agreement data and live flight feeds for planning only. "
                + "Standby outlook percentages are heuristic estimates, not live load factors. "
                + "Always confirm standby and ZED rules with your airline before you travel."
        )
        .font(.system(size: 11, weight: .regular))
        .foregroundStyle(subtleText)
        .multilineTextAlignment(.center)
        .padding(.top, 4)
    }
}

// MARK: - Bored-pilot-fishing illustration (pure SwiftUI)

private struct BoredomPilotIllustration: View {

    @State private var bobOffset: CGFloat = 0
    @State private var lineLength: CGFloat = 55

    private let accent = Color(red: 0.55, green: 0.60, blue: 0.98)

    var body: some View {
        ZStack {
            // Cloud
            cloudShape
                .foregroundStyle(Color.white.opacity(0.06))
                .offset(x: -40, y: -60)

            // Wing (stylised aircraft silhouette lying flat)
            airplaneWing
                .offset(x: 20, y: -30)

            // Pilot head
            Circle()
                .fill(Color(red: 0.98, green: 0.85, blue: 0.70))
                .frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                .offset(x: -14, y: -38)

            // Cap brim
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.15, green: 0.18, blue: 0.38))
                .frame(width: 32, height: 7)
                .offset(x: -14, y: -50)

            // Fishing rod arm
            rodArm
                .offset(x: 12, y: -20 + bobOffset * 0.3)

            // Fishing line (vertical)
            Rectangle()
                .fill(accent.opacity(0.55))
                .frame(width: 1, height: lineLength)
                .offset(x: 62, y: lineLength / 2 - 22 + bobOffset * 0.5)

            // Bobber
            Circle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(x: 62, y: lineLength - 16 + bobOffset)

            // "No flights" text below illustration
            VStack(spacing: 2) {
                Text("🎣")
                    .font(.system(size: 18))
                Text("The gate is empty, captain.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.40))
            }
            .offset(y: 80)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                bobOffset = 6
            }
        }
    }

    private var cloudShape: some View {
        ZStack {
            Ellipse().frame(width: 80, height: 32)
            Ellipse().frame(width: 55, height: 28).offset(x: -15, y: -10)
            Ellipse().frame(width: 45, height: 24).offset(x: 18, y: -8)
        }
    }

    private var airplaneWing: some View {
        // Tiny stylised aircraft nose + delta wing
        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.10))
                .frame(width: 50, height: 14)
                .offset(x: -4, y: 0)
            Triangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 36, height: 22)
                .rotationEffect(.degrees(-10))
                .offset(x: 14, y: -2)
        }
    }

    private var rodArm: some View {
        ZStack {
            // Rod body diagonal
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 50, y: -30))
            }
            .stroke(Color(red: 0.60, green: 0.42, blue: 0.22).opacity(0.85),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
