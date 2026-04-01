// CommunityRankView.swift
// Revless
//
// "Wings" milestone badge system.
// Unlocks Bronze → Silver → Gold based on approved verification count.

import SwiftUI

// MARK: - Rank definition

enum CommunityRank: CaseIterable {
    case bronze
    case silver
    case gold

    /// Verifications needed to attain (and show) this rank.
    var threshold: Int { switch self { case .bronze: 1; case .silver: 10; case .gold: 30 } }

    var title: String { switch self { case .bronze: "Bronze Wings"; case .silver: "Silver Wings"; case .gold: "Gold Wings" } }

    var subtitle: String {
        switch self {
        case .bronze: "First verified agreement — welcome to the crew."
        case .silver: "10 verifications — trusted voice in the community."
        case .gold:   "30 verifications — elite contributor, thank you!"
        }
    }

    var icon: String { "airplane.circle.fill" }

    var gradient: LinearGradient {
        switch self {
        case .bronze:
            return LinearGradient(
                colors: [Color(red: 0.80, green: 0.50, blue: 0.22),
                         Color(red: 0.60, green: 0.35, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .silver:
            return LinearGradient(
                colors: [Color(red: 0.85, green: 0.87, blue: 0.92),
                         Color(red: 0.60, green: 0.63, blue: 0.72)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [Color(red: 1.00, green: 0.84, blue: 0.20),
                         Color(red: 0.95, green: 0.60, blue: 0.10)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    var glowColor: Color {
        switch self {
        case .bronze: Color(red: 0.80, green: 0.50, blue: 0.22)
        case .silver: Color(red: 0.80, green: 0.82, blue: 0.90)
        case .gold:   Color(red: 1.00, green: 0.84, blue: 0.20)
        }
    }

    static func rank(for count: Int) -> CommunityRank? {
        CommunityRank.allCases.reversed().first { count >= $0.threshold }
    }

    static func nextRank(for count: Int) -> CommunityRank? {
        CommunityRank.allCases.first { count < $0.threshold }
    }
}

// MARK: - Badge view (3-D layered wings)

struct WingsBadge: View {

    let rank: CommunityRank
    var size: CGFloat = 64

    @State private var shine: Bool = false

    var body: some View {
        ZStack {
            // Depth: shadow disc
            Circle()
                .fill(rank.glowColor.opacity(0.20))
                .frame(width: size * 1.15, height: size * 1.15)
                .blur(radius: size * 0.18)

            // Base gradient circle
            Circle()
                .fill(rank.gradient)
                .frame(width: size, height: size)
                .overlay {
                    // Specular highlight
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(shine ? 0.55 : 0.32), .white.opacity(0)],
                                startPoint: .top, endPoint: .center
                            )
                        )
                        .frame(width: size * 0.55, height: size * 0.38)
                        .offset(y: -size * 0.12)
                }
                .overlay {
                    Circle()
                        .strokeBorder(rank.glowColor.opacity(0.50), lineWidth: 1.5)
                }

            // Wing icon
            Image(systemName: rank.icon)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: rank.glowColor.opacity(0.80), radius: 6, y: 2)
        }
        .shadow(color: rank.glowColor.opacity(0.40), radius: size * 0.25, y: size * 0.08)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                shine = true
            }
        }
    }
}

// MARK: - Community rank section (placed inside ProfileView)

struct CommunityRankSection: View {

    let verificationCount: Int
    var accentColor: Color = Color(red: 0.55, green: 0.60, blue: 0.98)

    private var current: CommunityRank? { CommunityRank.rank(for: verificationCount) }
    private var next: CommunityRank?    { CommunityRank.nextRank(for: verificationCount) }

    private let subtleText = Color.white.opacity(0.45)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Community Rank")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(subtleText)
                .textCase(.uppercase)
                .tracking(1.2)

            if let rank = current {
                earnedCard(rank)
            }

            if let n = next {
                progressCard(toward: n)
            } else if current != nil {
                maxRankBanner
            } else {
                lockedCard
            }
        }
    }

    private func earnedCard(_ rank: CommunityRank) -> some View {
        HStack(spacing: 16) {
            WingsBadge(rank: rank, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(rank.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(rank.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .glassCard(cornerRadius: 18, accent: accentColor)
    }

    private func progressCard(toward next: CommunityRank) -> some View {
        let prev = CommunityRank.allCases.last { $0.threshold < next.threshold }
        let lower = prev?.threshold ?? 0
        let upper = next.threshold
        let frac  = min(1, Double(verificationCount - lower) / Double(upper - lower))

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next: \(next.title)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("\(next.threshold - verificationCount) more verification\(next.threshold - verificationCount == 1 ? "" : "s") to unlock")
                        .font(.system(size: 12))
                        .foregroundStyle(subtleText)
                }
                Spacer()
                Text("\(verificationCount) / \(next.threshold)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(next.gradient)
                        .frame(width: geo.size.width * frac, height: 6)
                        .animation(.spring(response: 0.6), value: frac)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .glassCard(cornerRadius: 18, accent: accentColor)
    }

    private var maxRankBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 1.00, green: 0.84, blue: 0.20))
            Text("Max rank achieved — you're legendary crew.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 18, accent: Color(red: 1.00, green: 0.84, blue: 0.20))
    }

    private var lockedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(subtleText)
                .frame(width: 32)
            Text("Verify 1 route agreement to unlock your first Wings badge.")
                .font(.system(size: 13))
                .foregroundStyle(subtleText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 18, accent: accentColor)
    }
}
