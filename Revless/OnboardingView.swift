// OnboardingView.swift
// Revless
//
// Token-economy onboarding: paged TabView on the app gradient. Final slide
// uses a full-width glassmorphic "Start Exploring" CTA.

import SwiftUI

// MARK: - Data model

private struct OnboardingSlide: Identifiable {
    let id: Int
    let icon: String
    let iconGradient: LinearGradient
    let iconShadowColor: Color
    let message: String
}

// MARK: - Main view

struct OnboardingView: View {

    var onFinish: () -> Void

    @State private var currentPage: Int = 0
    /// Required on the final slide before "Start Exploring" (decision-support / not legal advice).
    @State private var hasAcceptedDisclaimer: Bool = false

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top, endPoint: .bottom
    )

    private let orangeGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.55, blue: 0.12),
                 Color(red: 1.0, green: 0.35, blue: 0.08)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let indigoGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.44, blue: 0.98),
                 Color(red: 0.55, green: 0.28, blue: 0.92)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let skyGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.72, blue: 0.98),
                 Color(red: 0.38, green: 0.44, blue: 0.98)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    private var slides: [OnboardingSlide] {[
        OnboardingSlide(
            id: 0,
            icon: "airplane.circle.fill",
            iconGradient: skyGradient,
            iconShadowColor: Color(red: 0.25, green: 0.72, blue: 0.98),
            message: "Welcome to Revless. The modern engine for crew travel."
        ),
        OnboardingSlide(
            id: 1,
            icon: "bolt.shield.fill",
            iconGradient: indigoGradient,
            iconShadowColor: Color(red: 0.38, green: 0.44, blue: 0.98),
            message: "Smart Filtering. We scan live flight data against your airline's specific ZED agreements."
        ),
        OnboardingSlide(
            id: 2,
            icon: "star.fill",
            iconGradient: orangeGradient,
            iconShadowColor: Color.orange,
            message: "Community Driven. Searches cost 1 credit. Verify stale route agreements to earn +5 credits."
        ),
    ]}

    private var isLastSlide: Bool { currentPage == slides.count - 1 }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(slides) { slide in
                        SlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page)
                .frame(maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                bottomControls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 52)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 28) {
            if isLastSlide {
                Text("Terms of Use")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                termsAcknowledgment
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                startButton
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                nextButton
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLastSlide)
    }

    private var termsAcknowledgment: some View {
        Button {
            hasAcceptedDisclaimer.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: hasAcceptedDisclaimer ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(
                        hasAcceptedDisclaimer
                            ? Color(red: 1.0, green: 0.55, blue: 0.12)
                            : Color.white.opacity(0.35)
                    )
                Text(
                    "Revless is decision support only—not legal or HR advice. "
                        + "Agreement data is crowdsourced; I will confirm rules with my airline's official sources before I travel."
                )
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.78))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Terms acknowledgment")
        .accessibilityAddTraits(hasAcceptedDisclaimer ? [.isSelected] : [])
    }

    private var nextButton: some View {
        Button {
            withAnimation { currentPage += 1 }
        } label: {
            HStack(spacing: 8) {
                Text("Next")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background { glassButtonBackground() }
        }
        .buttonStyle(.plain)
    }

    /// Full-width glassmorphic CTA on the final slide only.
    private var startButton: some View {
        Button(action: onFinish) {
            Text("Start Exploring")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background { glassButtonBackground() }
        }
        .buttonStyle(.plain)
        .disabled(!hasAcceptedDisclaimer)
        .opacity(hasAcceptedDisclaimer ? 1 : 0.45)
    }

    private func glassButtonBackground() -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            }
    }
}

// MARK: - Slide

private struct SlideView: View {

    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(slide.iconGradient)
                    .opacity(0.15)
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)

                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 32, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    }
                    .frame(width: 110, height: 110)
                    .shadow(color: slide.iconShadowColor.opacity(0.40), radius: 28, y: 12)

                Image(systemName: slide.icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(slide.iconGradient)
            }
            .padding(.bottom, 44)

            Text(slide.message)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Color(hex:)

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

#Preview {
    OnboardingView(onFinish: {})
}
