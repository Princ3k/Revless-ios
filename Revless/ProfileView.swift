// ProfileView.swift
// Revless
//
// Tab 3 — real user profile, account details, and sign-out.
// Reads live data from auth.currentUser (populated by GET /auth/me after login).

import SwiftUI

struct ProfileView: View {

    @Environment(AuthViewModel.self) private var auth
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSignOutAlert = false
    @State private var verifications: [VerificationHistoryItem] = []
    @State private var verificationsLoaded = false

    // MARK: - Palette

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top, endPoint: .bottom
    )
    private let ctaGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.44, blue: 0.98),
                 Color(red: 0.55, green: 0.28, blue: 0.92)],
        startPoint: .leading, endPoint: .trailing
    )
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)
    private let subtleText  = Color.white.opacity(0.45)

    // MARK: - Derived user values

    private var email: String        { auth.currentUser?.email ?? "—" }
    private var credits: Int         { auth.currentUser?.searchCredits ?? 0 }
    private var tenantId: String     { auth.currentUser?.tenantId?.uuidString.prefix(8).description ?? "—" }
    private var airline: String      {
        // Derive airline name from email domain (e.g. flyporter.com → flyporter)
        let domain = email.components(separatedBy: "@").last ?? ""
        return domain.components(separatedBy: ".").first?.capitalized ?? domain
    }
    private var initials: String {
        let name = email.components(separatedBy: "@").first ?? ""
        return String(name.prefix(2)).uppercased()
    }
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    statsRow
                    accountCard
                    verificationImpactSection
                    appCard
                    signOutButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 48)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .preferredColorScheme(.dark)
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                hasSeenOnboarding = false
                auth.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign back in to access your routes.")
        }
        .onAppear { Task { await loadVerifications() } }
    }

    @MainActor
    private func loadVerifications() async {
        defer { verificationsLoaded = true }
        do {
            verifications = try await NetworkManager.shared.getMyVerifications(limit: 40)
        } catch {
            verifications = []
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 14) {
            ZStack {
                // Outer glow ring
                Circle()
                    .strokeBorder(ctaGradient, lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .shadow(color: accentColor.opacity(0.35), radius: 16)

                // Frosted glass fill
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial, in: Circle())
                    .frame(width: 96, height: 96)

                // Initials
                Text(initials)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(email.components(separatedBy: "@").first?.capitalized ?? "Crew Member")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(email)
                    .font(.system(size: 13))
                    .foregroundStyle(subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statPill(
                icon: "star.fill",
                iconColor: Color(red: 1.0, green: 0.75, blue: 0.20),
                value: "\(credits)",
                label: "Credits"
            )
            statPill(
                icon: "checkmark.shield.fill",
                iconColor: .green,
                value: airline,
                label: "Airline"
            )
        }
    }

    private func statPill(icon: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(subtleText)
                    .textCase(.uppercase)
                    .tracking(0.6)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background { glass() }
    }

    // MARK: - Account card

    private var accountCard: some View {
        VStack(spacing: 0) {
            sectionLabel("Account")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                infoRow(
                    icon: "envelope.fill",
                    iconColor: accentColor,
                    title: "Email",
                    value: email
                )
                rowDivider
                infoRow(
                    icon: "airplane.circle.fill",
                    iconColor: Color(red: 0.55, green: 0.28, blue: 0.92),
                    title: "Airline",
                    value: airline
                )
                rowDivider
                infoRow(
                    icon: "person.text.rectangle.fill",
                    iconColor: Color(red: 1.0, green: 0.75, blue: 0.20),
                    title: "Member ID",
                    value: "…\(tenantId)"
                )
            }
            .background { glass() }
        }
    }

    // MARK: - Verification impact

    private static let verificationRelativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var verificationImpactSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Community impact")
                .frame(maxWidth: .infinity, alignment: .leading)

            if !verifications.isEmpty {
                VStack(spacing: 8) {
                    ForEach(verifications) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.isAccurate ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(item.isAccurate ? Color.green : Color.orange.opacity(0.9))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.carrierIata) · \(item.carrierName)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)

                                Text(item.isAccurate ? "Confirmed rule is accurate" : "Flagged rule as outdated")
                                    .font(.system(size: 12))
                                    .foregroundStyle(subtleText)

                                if let d = item.createdAtDate {
                                    Text(Self.verificationRelativeFormatter.localizedString(for: d, relativeTo: Date()))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(subtleText.opacity(0.8))
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background { glass() }
                    }
                }
            } else if verificationsLoaded {
                Text("When you verify route agreements from search results, your contributions appear here.")
                    .font(.system(size: 13))
                    .foregroundStyle(subtleText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { glass() }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(accentColor)
                    Spacer()
                }
                .padding(.vertical, 20)
                .background { glass() }
            }
        }
    }

    // MARK: - App card

    private var appCard: some View {
        VStack(spacing: 0) {
            sectionLabel("App")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                infoRow(
                    icon: "info.circle.fill",
                    iconColor: Color.cyan.opacity(0.8),
                    title: "Version",
                    value: appVersion
                )
                rowDivider
                infoRow(
                    icon: "doc.text.fill",
                    iconColor: subtleText,
                    title: "Terms of Service",
                    value: "",
                    showChevron: true
                )
                rowDivider
                infoRow(
                    icon: "hand.raised.fill",
                    iconColor: subtleText,
                    title: "Privacy Policy",
                    value: "",
                    showChevron: true
                )
            }
            .background { glass() }
        }
    }

    // MARK: - Sign out button

    private var signOutButton: some View {
        Button {
            showSignOutAlert = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Color.red.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(0.08))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.22), lineWidth: 0.5)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private func infoRow(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        showChevron: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(subtleText.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(subtleText)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    private func glass(_ cornerRadius: CGFloat = 18) -> some View {
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
    ProfileView()
        .environment(AuthViewModel())
}
