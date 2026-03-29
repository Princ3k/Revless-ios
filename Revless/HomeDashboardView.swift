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

    // MARK: - Palette (matches RouteResultsView / SearchFormView exactly)

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top, endPoint: .bottom
    )
    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.44, blue: 0.98),
            Color(red: 0.55, green: 0.28, blue: 0.92),
        ],
        startPoint: .leading, endPoint: .trailing
    )
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)
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
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    creditsCard
                    quickActionsSection
                    recentActivityPlaceholder
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
        // Sync credits from the server every time the user lands on this tab.
        // Covers: post-search deduction, post-verification reward, and cold launches.
        .task { await auth.refreshCurrentUser() }
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

    // MARK: - Recent activity placeholder

    private var recentActivityPlaceholder: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Recent Activity")

            HStack(spacing: 14) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(accentColor.opacity(0.5))
                    .frame(width: 36)

                Text("Your recent searches will appear here.")
                    .font(.system(size: 13))
                    .foregroundStyle(subtleText)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background { glass() }
        }
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
            .fill(Color.white.opacity(0.08))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
            }
    }
}

// MARK: - Color(hex:) — file-private

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r, g, b: UInt64
        switch hex.count {
        case 3:  (r, g, b) = ((value >> 8) * 17, (value >> 4 & 0xF) * 17, (value & 0xF) * 17)
        case 6:  (r, g, b) = (value >> 16, value >> 8 & 0xFF, value & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// MARK: - Preview

#Preview {
    HomeDashboardView(selectedTab: .constant(0))
        .environment(AuthViewModel())
}
