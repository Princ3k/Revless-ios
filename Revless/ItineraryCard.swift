// ItineraryCard.swift
// Revless

import SwiftUI

struct ItineraryCard: View {

    let itinerary: Itinerary
    var onVerifyTap: (StaleRule) -> Void = { _ in }

    @State private var zedHoldActive       = false
    @State private var companionHoldActive = false
    @State private var xrayVisible         = false   // long-press X-Ray overlay

    // MARK: - Palette

    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)
    private let subtleText  = Color.white.opacity(0.50)

    // MARK: - Derived values

    private var firstLeg: FlightLeg? { itinerary.legs.first }
    private var lastLeg:  FlightLeg? { itinerary.legs.last }

    private var carrierLine: String {
        var seen = Set<String>()
        return itinerary.legs
            .filter { seen.insert($0.carrierIata).inserted }
            .map(\.carrierIata)
            .joined(separator: " · ")
    }

    private var viaSummary: String {
        let stops = itinerary.legs.count - 1
        guard stops > 0 else { return "Nonstop" }
        let cities = itinerary.legs.dropLast().map(\.destination).joined(separator: ", ")
        return stops == 1 ? "via \(cities)" : "\(stops) stops · \(cities)"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            cardContent

            if xrayVisible {
                xrayOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background {
            // Multi-layered glass: ultraThinMaterial + subtle tint + accent glow border
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .shadow(
                    color: (itinerary.requiresVerification ? Color.orange : accentColor).opacity(0.22),
                    radius: 16, y: 5
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(accentColor.opacity(0.30), lineWidth: 0.5)
                }
        }
        .animation(.easeOut(duration: 0.25), value: xrayVisible)
        .onLongPressGesture(minimumDuration: 0.55) {
            HapticEngine.select()
            withAnimation { xrayVisible.toggle() }
        }
    }

    // MARK: - Card content

    private var cardContent: some View {
        VStack(spacing: 18) {
            flightSummary
            Divider().background(Color.white.opacity(0.08))
            footer
        }
        .padding(18)
    }

    // MARK: - Flight summary row

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
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(firstLeg?.departureTime.flightTime ?? "--:--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.5)
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
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(lastLeg?.arrivalTime.flightTime ?? "--:--")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1).minimumScaleFactor(0.5)
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
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(itinerary.totalDurationFormatted)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(subtleText)
        }
        .padding(.horizontal, 10)
    }

    private var connectorLine: some View {
        HStack(spacing: 0) {
            Circle().fill(accentColor).frame(width: 7, height: 7)
            ForEach(Array(itinerary.legs.enumerated()), id: \.offset) { index, _ in
                Rectangle()
                    .fill(accentColor.opacity(0.30))
                    .frame(height: 1).frame(maxWidth: .infinity)
                if index < itinerary.legs.count - 1 {
                    Circle()
                        .fill(Color(red: 0.10, green: 0.11, blue: 0.20))
                        .overlay(Circle().strokeBorder(accentColor.opacity(0.75), lineWidth: 1.5))
                        .frame(width: 6, height: 6)
                } else {
                    Circle().fill(accentColor).frame(width: 7, height: 7)
                }
            }
        }
    }

    // MARK: - Footer badges

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                zedBadge
                Spacer()
                verificationBadge
            }
            standbyOutlookChip
        }
    }

    private var standbyOutlookChip: some View {
        let pct = Int((itinerary.boardingProbability * 100).rounded())
        return HStack(spacing: 6) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption2)
            Text("Standby outlook ~\(pct)%")
                .font(.caption2.weight(.semibold))
            Text("· planning estimate")
                .font(.caption2)
                .foregroundStyle(subtleText)
            Spacer()
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 10))
                .foregroundStyle(subtleText.opacity(0.5))
        }
        .foregroundStyle(Color.white.opacity(0.82))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Standby outlook about \(pct) percent. Long-press card for details.")
    }

    private var zedBadge: some View {
        let (fg, bg): (Color, Color) = {
            switch itinerary.totalZedTier {
            case .low:    return (.orange, Color.orange.opacity(0.15))
            case .medium: return (accentColor, accentColor.opacity(0.15))
            case .high:   return (.green, Color.green.opacity(0.15))
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
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(bg, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .animation(.easeOut(duration: 0.18), value: zedHoldActive)
        .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 44,
                            pressing: { pressing in zedHoldActive = pressing }, perform: {})
        .accessibilityHint("Hold for a short explanation of this ZED tier.")
    }

    private var zedTierHoldBrief: String {
        switch itinerary.totalZedTier {
        case .low:    return "ZED Low is the lowest standby bucket for this routing."
        case .medium: return "ZED Medium is a mid-level standby tier on these carriers."
        case .high:   return "ZED High is the strongest tier reflected for this itinerary."
        }
    }

    @ViewBuilder
    private var verificationBadge: some View {
        if itinerary.requiresVerification, let rule = itinerary.staleRules.first {
            Button {
                HapticEngine.notifyWarning()
                onVerifyTap(rule)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Verify Rules")
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 10).padding(.vertical, 6)
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
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .animation(.easeOut(duration: 0.18), value: companionHoldActive)
            .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 44,
                                pressing: { pressing in companionHoldActive = pressing }, perform: {})
            .accessibilityHint("Hold to see traveler eligibility notes.")
        }
    }

    private static let companionHoldBrief =
        "Route rules look current. ZED travel typically covers employee, spouse, and eligible dependents. Always confirm with crew travel."

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
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay { RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5) }
            }
            .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }

    // MARK: - X-Ray overlay (long-press "probability gauge")

    private var xrayOverlay: some View {
        ZStack {
            // Blurred backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color.black.opacity(0.45))

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                    Text("X-Ray · Boarding Analysis")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { withAnimation { xrayVisible = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }

                BoardingProbabilityGauge(probability: itinerary.boardingProbability)

                VStack(alignment: .leading, spacing: 8) {
                    xrayRow("Route complexity", value: "\(itinerary.legs.count) leg\(itinerary.legs.count == 1 ? "" : "s")",
                            icon: "map", positive: itinerary.legs.count == 1)
                    xrayRow("Agreement confidence", value: itinerary.requiresVerification ? "Needs verification" : "Verified",
                            icon: itinerary.requiresVerification ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                            positive: !itinerary.requiresVerification)
                    xrayRow("ZED tier", value: itinerary.totalZedTier.displayName.capitalized,
                            icon: "ticket.fill",
                            positive: itinerary.totalZedTier == .high)
                }

                Text("Heuristic estimate only — not live load data. Confirm with your airline.")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.38))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .frame(height: 320)
    }

    private func xrayRow(_ label: String, value: String, icon: String, positive: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(positive ? Color.green : Color.orange)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Boarding probability semi-circle gauge

struct BoardingProbabilityGauge: View {

    let probability: Double  // 0.0 – 1.0

    @State private var animatedValue: Double = 0
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)

    private var gaugeColor: Color {
        switch probability {
        case 0..<0.35: return .red.opacity(0.85)
        case 0.35..<0.60: return .orange
        default: return Color(red: 0.30, green: 0.85, blue: 0.55)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Track arc
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(180))

                // Fill arc
                Circle()
                    .trim(from: 0, to: animatedValue * 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [gaugeColor.opacity(0.7), gaugeColor],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(180))
                    .shadow(color: gaugeColor.opacity(0.5), radius: 6)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedValue)

                // Centre text
                VStack(spacing: 0) {
                    Spacer()
                    Text("\(Int(animatedValue * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                    Text("boarding outlook")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .frame(height: 80)
            }
            .frame(height: 76)
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                animatedValue = probability
            }
        }
    }
}

// MARK: - ISO 8601 string helpers

private extension String {

    var flightTime: String {
        Self.parse(self).map { Self.timeFmt.string(from: $0) } ?? "--:--"
    }

    var flightDate: String {
        Self.parse(self).map { Self.dateFmt.string(from: $0) } ?? ""
    }

    private static func parse(_ s: String) -> Date? {
        withTZ.date(from: s) ?? noTZ.date(from: s)
    }

    private static let withTZ: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f
    }()

    private static let noTZ: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = TimeZone(abbreviation: "UTC")
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    private static let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        f.locale = Locale(identifier: "en_US_POSIX"); return f
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
            ItineraryCard(
                itinerary: Itinerary(
                    legs: [
                        FlightLeg(carrierIata: "TK", carrierName: "Turkish Airlines",
                                  origin: "YYZ", destination: "IST",
                                  departureTime: "2026-05-11T23:00:00",
                                  arrivalTime: "2026-05-12T17:00:00",
                                  durationMinutes: 600),
                        FlightLeg(carrierIata: "TK", carrierName: "Turkish Airlines",
                                  origin: "IST", destination: "KUL",
                                  departureTime: "2026-05-12T20:30:00",
                                  arrivalTime: "2026-05-13T12:00:00",
                                  durationMinutes: 570),
                    ],
                    totalDurationMinutes: 1170, totalZedTier: .medium,
                    requiresVerification: false, staleRules: [],
                    boardingProbability: 0.72
                )
            )
            ItineraryCard(
                itinerary: Itinerary(
                    legs: [
                        FlightLeg(carrierIata: "QR", carrierName: "Qatar Airways",
                                  origin: "YYZ", destination: "DOH",
                                  departureTime: "2026-05-11T22:15:00",
                                  arrivalTime: "2026-05-12T18:45:00",
                                  durationMinutes: 630),
                    ],
                    totalDurationMinutes: 630, totalZedTier: .low,
                    requiresVerification: true,
                    staleRules: [StaleRule(ruleId: UUID(), carrierIata: "QR",
                                          carrierName: "Qatar Airways", confidenceScore: 2)],
                    boardingProbability: 0.38
                )
            )
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
