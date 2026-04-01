// HomeDashboardView.swift
// Revless
//
// Home tab — greets the crew member, surfaces their search-credit balance,
// and offers a one-tap shortcut into the Search flow.
//
// Credits are read from auth.currentUser (populated after login).
// Falls back to 5 (the DB default) until a /auth/me endpoint is wired up.

import SwiftUI

struct HomeDashboardView: View {

    /// Injected by MainTabView so the "Start a Search" button can switch tabs.
    @Binding var selectedTab: Int

    @Environment(AuthViewModel.self) private var auth
    @Environment(RecentSearchStore.self) private var recentActivity
    @Environment(ThemeManager.self) private var theme

    @State private var serverSearchHistory: [SearchHistoryItem] = []
    @State private var didAttemptServerHistory = false
    @State private var prevCredits: Int = 0

    private var accentColor: Color  { theme.accent }
    private var ctaGradient: LinearGradient { theme.ctaGradient }
    private let subtleText  = Color.white.opacity(0.45)

    // MARK: - Derived values

    private var credits: Int { auth.currentUser?.searchCredits ?? 5 }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Good night"
        }
    }

    private var displayName: String {
        // Use the portion of the email before @ as a friendly identifier
        auth.currentUser?.email.components(separatedBy: "@").first
            ?? auth.currentUser?.email
            ?? "Crew member"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AtmosphericBackground()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    creditsCard
                    quickActionsSection
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .preferredColorScheme(.dark)
        .task {
            prevCredits = auth.currentUser?.searchCredits ?? 0
            await auth.refreshCurrentUser()
            let newCredits = auth.currentUser?.searchCredits ?? 0
            if newCredits > prevCredits { HapticEngine.notifySuccess() }
            prevCredits = newCredits
        }
        .onAppear { Task { await loadServerSearchHistory() } }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting + ",")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(subtleText)

                Text(displayName.capitalized)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            // Gradient airplane badge
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ctaGradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: accentColor.opacity(0.45), radius: 14, y: 5)

                Image(systemName: "airplane.departure")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Credits card

    private var creditsCard: some View {
        VStack(spacing: 0) {
            // ── Top row: icon badge + balance ────────────────────────────
            HStack(alignment: .center, spacing: 16) {
                // Glowing gradient icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.80, blue: 0.20),
                                         Color(red: 1.0, green: 0.50, blue: 0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.orange.opacity(0.45), radius: 12, y: 5)

                    Image(systemName: "star.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Search Credits")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subtleText)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text("\(credits)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .overlay(alignment: .topTrailing) {
                            CreditPopEffect(trigger: credits)
                                .frame(width: 1, height: 1)
                        }
                }

                Spacer()

                // Credit coin stack decoration
                VStack(spacing: -6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.orange.opacity(0.12 + Double(i) * 0.06))
                            .overlay(Circle().strokeBorder(Color.orange.opacity(0.25), lineWidth: 0.5))
                            .frame(width: 28 - CGFloat(i) * 4, height: 28 - CGFloat(i) * 4)
                    }
                }
            }
            .padding(.bottom, 18)

            Divider().background(Color.white.opacity(0.10))

            // ── Earn-more prompt ──────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Earn +5 credits per verification")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Flag a stale route agreement to help the community and earn credits.")
                        .font(.system(size: 12))
                        .foregroundStyle(subtleText)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background { glass() }
    }

    // MARK: - Quick actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Quick Actions")

            // Primary: Start a search (switches tab)
            Button {
                HapticEngine.select()
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = 1 }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(ctaGradient)
                            .frame(width: 36, height: 36)
                            .shadow(color: accentColor.opacity(0.40), radius: 8, y: 3)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Start a New Search")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Find ZED-eligible routes for your crew")
                            .font(.system(size: 12))
                            .foregroundStyle(subtleText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subtleText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background { glass() }
            }
            .buttonStyle(.plain)

            // Secondary: Verify agreements (placeholder — navigates to Search)
            Button {
                HapticEngine.select()
                withAnimation(.easeInOut(duration: 0.25)) { selectedTab = 1 }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.opacity(0.20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.green.opacity(0.30), lineWidth: 0.5)
                            )
                            .frame(width: 36, height: 36)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Verify a Route")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Earn +5 credits by confirming an agreement")
                            .font(.system(size: 12))
                            .foregroundStyle(subtleText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(subtleText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background { glass() }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Recent activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Recent Activity")

            if !serverSearchHistory.isEmpty {
                VStack(spacing: 8) {
                    ForEach(serverSearchHistory) { item in
                        serverSearchHistoryRow(item)
                    }
                }
            } else if !recentActivity.items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(recentActivity.items) { item in
                        recentActivityRow(item)
                    }
                }
            } else if didAttemptServerHistory {
                HStack(spacing: 14) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(accentColor.opacity(0.5))
                        .frame(width: 36)

                    Text("Your recent searches will appear here after you find routes.")
                        .font(.system(size: 13))
                        .foregroundStyle(subtleText)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background { glass() }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(accentColor)
                    Spacer()
                }
                .padding(.vertical, 24)
                .background { glass() }
            }
        }
    }

    @MainActor
    private func loadServerSearchHistory() async {
        defer { didAttemptServerHistory = true }
        do {
            serverSearchHistory = try await NetworkManager.shared.getSearchHistory(limit: 20)
        } catch {
            serverSearchHistory = []
        }
    }

    private static let searchedRelativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private func serverSearchHistoryRow(_ item: SearchHistoryItem) -> some View {
        let when = item.searchedAtDate ?? Date.distantPast
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.routeLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(item.departureDisplay) · \(item.travelerType.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(subtleText)

                Text(item.resultSummary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(subtleText.opacity(0.9))
            }

            Spacer(minLength: 8)

            Text(Self.searchedRelativeFormatter.localizedString(for: when, relativeTo: Date()))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(subtleText.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background { glass() }
    }

    private func recentActivityRow(_ item: RecentSearchActivity) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.routeLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(item.departureDisplay) · \(item.travelerDisplay)")
                    .font(.system(size: 12))
                    .foregroundStyle(subtleText)

                Text(item.resultSummary)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(subtleText.opacity(0.9))
            }

            Spacer(minLength: 8)

            Text(Self.searchedRelativeFormatter.localizedString(for: item.searchedAt, relativeTo: Date()))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(subtleText.opacity(0.75))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background { glass() }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(subtleText)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func glass(_ cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.05))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(color: accentColor.opacity(0.14), radius: 12, y: 3)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(accentColor.opacity(0.28), lineWidth: 0.5)
            }
    }
}

// MARK: - Preview

#Preview {
    HomeDashboardView(selectedTab: .constant(0))
        .environment(AuthViewModel())
        .environment(RecentSearchStore())
        .environment(ThemeManager())
}
