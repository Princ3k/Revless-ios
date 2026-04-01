// ThemeManager.swift
// Revless
//
// Tenant-aware accent colour + atmospheric background helpers.
// Shared app-wide via @Environment so every view gets the same token values.

import SwiftUI
import Observation

// MARK: - Tenant theme

enum AirlineTheme {
    case porter       // Dark avocado-green
    case generic      // Electric indigo (default)

    // Primary accent: the colour used for selected pills, CTA borders, badges.
    var accent: Color {
        switch self {
        case .porter:  return Color(red: 0.10, green: 0.22, blue: 0.52)   // Porter dark navy-blue
        case .generic: return Color(red: 0.55, green: 0.60, blue: 0.98)   // indigo
        }
    }

    // CTA gradient (buttons, icon badges, tab indicator glow).
    var ctaGradient: LinearGradient {
        switch self {
        case .porter:
            return LinearGradient(
                colors: [Color(red: 0.14, green: 0.28, blue: 0.62),
                         Color(red: 0.07, green: 0.15, blue: 0.40)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        case .generic:
            return LinearGradient(
                colors: [Color(red: 0.38, green: 0.44, blue: 0.98),
                         Color(red: 0.55, green: 0.28, blue: 0.92)],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }

    /// Derive theme from email domain.
    static func from(email: String) -> AirlineTheme {
        let domain = email.lowercased().components(separatedBy: "@").last ?? ""
        if domain.contains("flyporter") || domain.contains("porter") { return .porter }
        return .generic
    }
}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    var theme: AirlineTheme = .generic

    var accent: Color      { theme.accent }
    var ctaGradient: LinearGradient { theme.ctaGradient }

    func update(for email: String?) {
        theme = AirlineTheme.from(email: email ?? "")
    }
}

// MARK: - Atmospheric animated background

/// A time-aware sky gradient that slowly shifts colours.
/// Use as a full-screen ZStack background in lieu of the static `bg` gradient.
struct AtmosphericBackground: View {

    /// Animates every 8 seconds to a new sky state.
    @State private var phase: Double = 0

    private let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()

    private var skyColors: [Color] {
        let hour = Double(Calendar.current.component(.hour, from: Date()))
        // Midnight-dawn: deep navy → very dark blue-grey
        if hour < 5 || hour >= 22 {
            return [Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.16)]
        }
        // Dawn / dusk: midnight blue → muted twilight purple
        if (hour >= 5 && hour < 7) || (hour >= 19 && hour < 22) {
            return [Color(red: 0.06, green: 0.06, blue: 0.18),
                    Color(red: 0.14, green: 0.08, blue: 0.22)]
        }
        // Day: deep navy → dark indigo-teal
        return [Color(red: 0.04, green: 0.07, blue: 0.15),
                Color(red: 0.08, green: 0.10, blue: 0.24)]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: skyColors,
                startPoint: UnitPoint(x: 0.5 + 0.15 * sin(phase),
                                      y: 0.0 + 0.1  * cos(phase * 0.7)),
                endPoint: UnitPoint(x: 0.5 - 0.15 * sin(phase),
                                    y: 1.0 - 0.05 * sin(phase * 1.3))
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 7), value: phase)
        }
        .onReceive(timer) { _ in
            phase = phase + 1
        }
        .onAppear { phase = 0.1 }
    }
}

// MARK: - Glassomorphic card background

/// Multi-layered frosted glass with a faint accent-coloured border glow.
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var accent: Color = Color(red: 0.55, green: 0.60, blue: 0.98)

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
                    // Outer accent glow
                    .shadow(color: accent.opacity(0.18), radius: 14, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(accent.opacity(0.28), lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, accent: Color = Color(red: 0.55, green: 0.60, blue: 0.98)) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, accent: accent))
    }
}
