// ItineraryCard.swift
// Revless

import SwiftUI

struct ItineraryCard: View {

    let itinerary: Itinerary
    var onVerifyTap: (StaleRule) -> Void = { _ in }

    @State private var zedHoldActive = false
    @State private var companionHoldActive = false

    // MARK: - Palette

    private let accentColor  = Color(red: 0.55, green: 0.60, blue: 0.98)
    private let subtleText   = Color.white.opacity(0.50)

    // MARK: - Derived values

    private var firstLeg: FlightLeg? { itinerary.legs.first }
    private var lastLeg:  FlightLeg? { itinerary.legs.last }

    /// Ordered, deduplicated IATA codes across all legs (e.g. "TK · QR")
    private var carrierLine: String {
        var seen = Set<String>()
        return itinerary.legs
            .filter { seen.insert($0.carrierIata).inserted }
            .map(\.carrierIata)
            .joined(separator: " · ")
    }

    /// "Nonstop", "via IST", or "2 stops · IST, DOH"
    private var viaSummary: String {
        let stops = itinerary.legs.count - 1
        guard stops > 0 else { return "Nonstop" }
        let cities = itinerary.legs.dropLast().map(\.destination).joined(separator: ", ")
        return stops == 1 ? "via \(cities)" : "\(stops) stops · \(cities)"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 18) {
            flightSummary
            Divider().background(Color.white.opacity(0.08))
            footer
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                }
        }
        .shadow(
            color: itinerary.requiresVerification
                ? Color.orange.opacity(0.10)
                : Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.10),
            radius: 14, y: 5
        )
    }

    // MARK: - Flight summary row
    //
    // Layout:
    //   [Origin: leading]   [Connector: maxWidth]   [Destination: trailing]
    //      May 11              TK · 1 stop              May 12
    //      23:00           ●────◎────●                  12:00
    //      YYZ               via IST · 19h               KUL

    private var flightSummary: some View {
        HStack(alignment: .center, spacing: 0) {
            originStack
            connectorBlock.frame(maxWidth: .infinity)
            destinationStack
        }
    }

    private var originStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(firstLeg?.departureTime.flightDate ?? "")
                .font(.caption2.weight(.medium))
                .foregroundStyle(subtleText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(firstLeg?.departureTime.flightTime ?? "--:--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(firstLeg?.origin ?? "---")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(subtleText)
        }
    }

    private var destinationStack: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(lastLeg?.arrivalTime.flightDate ?? "")
                .font(.caption2.weight(.medium))
                .foregroundStyle(subtleText)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(lastLeg?.arrivalTime.flightTime ?? "--:--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(lastLeg?.destination ?? "---")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(subtleText)
        }
    }

    private var connectorBlock: some View {
        VStack(spacing: 5) {
            Text(carrierLine)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor)
                .lineLimit(1)

            connectorLine

            Text(viaSummary)
                .font(.system(size: 10))
                .foregroundStyle(subtleText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(itinerary.totalDurationFormatted)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(subtleText)
        }
        .padding(.horizontal, 10)
    }

    // Dot-and-line timeline:
    //   1 leg  → ●──────────────────●
    //   2 legs → ●─────◎─────●
    //   3 legs → ●───◎───◎───●
    private var connectorLine: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(accentColor)
                .frame(width: 7, height: 7)

            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, _ in
                Rectangle()
                    .fill(accentColor.opacity(0.30))
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                if index < itinerary.legs.count - 1 {
                    // Intermediate stop: hollow dot
                    Circle()
                        .fill(Color(red: 0.10, green: 0.11, blue: 0.20))
                        .overlay(
                            Circle().strokeBorder(accentColor.opacity(0.75), lineWidth: 1.5)
                        )
                        .frame(width: 6, height: 6)
                } else {
                    // Final destination: filled dot
                    Circle()
                        .fill(accentColor)
                        .frame(width: 7, height: 7)
                }
            }
        }
    }

    // MARK: - Footer badges

    private var footer: some View {
        HStack(spacing: 10) {
            zedBadge
            Spacer()
            verificationBadge
        }
    }

    private var zedBadge: some View {
        let (fg, bg): (Color, Color) = {
            switch itinerary.totalZedTier {
            case .low:    return (.orange,  Color.orange.opacity(0.15))
            case .medium: return (accentColor, accentColor.opacity(0.15))
            case .high:   return (.green,   Color.green.opacity(0.15))
            }
        }()
        return VStack(alignment: .leading, spacing: 0) {
            if zedHoldActive {
                holdTipBubble(text: zedTierHoldBrief)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            HStack(spacing: 4) {
                Image(systemName: "ticket.fill")
                Text("ZED \(itinerary.totalZedTier.displayName)")
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .animation(.easeOut(duration: 0.18), value: zedHoldActive)
        .onLongPressGesture(
            minimumDuration: 0.35,
            maximumDistance: 44,
            pressing: { pressing in zedHoldActive = pressing },
            perform: {}
        )
        .accessibilityHint("Hold for a short explanation of this ZED tier.")
    }

    /// Short copy shown while the user holds the ZED badge.
    private var zedTierHoldBrief: String {
        switch itinerary.totalZedTier {
        case .low:
            return "ZED Low is the lowest standby bucket for this routing. Fares load in the cheapest non-rev tier—often meaning more competition for open seats."
        case .medium:
            return "ZED Medium is a mid-level standby tier on these carriers. You pay a moderate ZED rate relative to high-tier priority on the same flights."
        case .high:
            return "ZED High is the strongest tier reflected for this itinerary. Standby lists and charges typically favor you versus lower ZED buckets when space is available."
        }
    }

    @ViewBuilder
    private var verificationBadge: some View {
        if itinerary.requiresVerification, let rule = itinerary.staleRules.first {
            Button { onVerifyTap(rule) } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Verify Rules")
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .trailing, spacing: 0) {
                if companionHoldActive {
                    holdTipBubble(text: Self.companionHoldBrief)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Companion OK")
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .animation(.easeOut(duration: 0.18), value: companionHoldActive)
            .onLongPressGesture(
                minimumDuration: 0.35,
                maximumDistance: 44,
                pressing: { pressing in companionHoldActive = pressing },
                perform: {}
            )
            .accessibilityHint("Hold to see which travelers are usually allowed on ZED for verified routes.")
        }
    }

    /// Who may travel when agreement rules are confident (no verify flag).
    private static let companionHoldBrief =
        "Route rules look current on file. ZED travel typically covers you (employee), your spouse or registered partner, and eligible dependents as defined by your airline. Some carriers allow one registered companion; others require separate listings—always confirm with crew travel before listing anyone."

    private func holdTipBubble(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.white.opacity(0.92))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: 280, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    }
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }
}

// MARK: - ISO 8601 string helpers

private extension String {

    /// "HH:mm" extracted from an ISO-8601 datetime string.
    var flightTime: String {
        Self.parse(self).map { Self.timeFmt.string(from: $0) } ?? "--:--"
    }

    /// "MMM d" date label (e.g. "May 11") from an ISO-8601 datetime string.
    var flightDate: String {
        Self.parse(self).map { Self.dateFmt.string(from: $0) } ?? ""
    }

    /// Tries ISO 8601 with timezone first, then falls back to no-timezone format.
    private static func parse(_ s: String) -> Date? {
        withTZ.date(from: s) ?? noTZ.date(from: s)
    }

    // Handles "…T23:00:00Z" and "…T23:00:00+05:30"
    private static let withTZ: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // Handles bare "…T23:00:00" (Duffel test sandbox sometimes omits the Z)
    private static let noTZ: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.timeZone   = TimeZone(abbreviation: "UTC")
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale     = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale     = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.05, blue: 0.09),
                     Color(red: 0.10, green: 0.10, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack(spacing: 16) {
            // Verified – 2 legs via IST
            ItineraryCard(
                itinerary: Itinerary(
                    legs: [
                        FlightLeg(carrierIata: "TK", carrierName: "Turkish Airlines",
                                  origin: "YYZ", destination: "IST",
                                  departureTime: "2026-05-11T23:00:00",
                                  arrivalTime:   "2026-05-12T17:00:00",
                                  durationMinutes: 600),
                        FlightLeg(carrierIata: "TK", carrierName: "Turkish Airlines",
                                  origin: "IST", destination: "KUL",
                                  departureTime: "2026-05-12T20:30:00",
                                  arrivalTime:   "2026-05-13T12:00:00",
                                  durationMinutes: 570),
                    ],
                    totalDurationMinutes: 1170,
                    totalZedTier: .medium,
                    requiresVerification: false,
                    staleRules: []
                )
            )

            // Verification needed – QR via DOH
            ItineraryCard(
                itinerary: Itinerary(
                    legs: [
                        FlightLeg(carrierIata: "QR", carrierName: "Qatar Airways",
                                  origin: "YYZ", destination: "DOH",
                                  departureTime: "2026-05-11T22:15:00",
                                  arrivalTime:   "2026-05-12T18:45:00",
                                  durationMinutes: 630),
                        FlightLeg(carrierIata: "QR", carrierName: "Qatar Airways",
                                  origin: "DOH", destination: "KUL",
                                  departureTime: "2026-05-12T22:00:00",
                                  arrivalTime:   "2026-05-13T10:15:00",
                                  durationMinutes: 495),
                    ],
                    totalDurationMinutes: 1125,
                    totalZedTier: .low,
                    requiresVerification: true,
                    staleRules: [StaleRule(ruleId: UUID(), carrierIata: "QR",
                                          carrierName: "Qatar Airways", confidenceScore: 2)]
                )
            )
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
