// OnboardingView.swift
// Revless
//
// First-launch swipeable carousel. Presented as a .fullScreenCover from
// ContentView until the user taps "Start Exploring" on the final slide.
//
// Design: same #0A0E17 → #1A1A2E gradient + Aero-Glass system as the rest
// of the app. Each slide is a self-contained SlideView built from a shared
// OnboardingSlide model.

import SwiftUI

// MARK: - Data model

private struct OnboardingSlide: Identifiable {
    let id: Int
    let icon: String
    let iconGradient: LinearGradient
    let iconShadowColor: Color
    let title: String
    let body: String
}

// MARK: - Main view

struct OnboardingView: View {

    /// Bound to @AppStorage("hasSeenOnboarding") in ContentView.
    var onFinish: () -> Void

    @State private var currentPage: Int = 0

    // MARK: Palette

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top, endPoint: .bottom
    )
    private let indigoGradient = LinearGradient(
        colors: [Color(red: 0.38, green: 0.44, blue: 0.98),
                 Color(red: 0.55, green: 0.28, blue: 0.92)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let amberGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.80, blue: 0.20),
                 Color(red: 1.0, green: 0.50, blue: 0.10)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let skyGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.72, blue: 0.98),
                 Color(red: 0.38, green: 0.44, blue: 0.98)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Slides

    private var slides: [OnboardingSlide] {[
        OnboardingSlide(
            id: 0,
            icon: "airplane.departure",
            iconGradient: skyGradient,
            iconShadowColor: Color(red: 0.25, green: 0.72, blue: 0.98),
            title: "Welcome to Revless",
            body: "The modern engine for non-rev travel.\nFind optimal ZED routes without the guesswork."
        ),
        OnboardingSlide(
            id: 1,
            icon: "bolt.shield.fill",
            iconGradient: indigoGradient,
            iconShadowColor: Color(red: 0.38, green: 0.44, blue: 0.98),
            title: "Smart Filtering",
            body: "We cross-reference live global flight data against your airline's specific ZED agreements.\nNo more dead ends."
        ),
        OnboardingSlide(
            id: 2,
            icon: "star.circle.fill",
            iconGradient: amberGradient,
            iconShadowColor: Color.orange,
            title: "Community Driven",
            body: "Searches cost 1 credit. Help the community by verifying if a route is still accurate\nto earn +5 credits."
        ),
    ]}

    private var isLastSlide: Bool { currentPage == slides.count - 1 }

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Slide carousel ──────────────────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(slides) { slide in
                        SlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // ── Dot indicator + CTA ─────────────────────────────────
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
            dotIndicator

            if isLastSlide {
                startButton
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                nextButton
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLastSlide)
    }

    // MARK: Dot indicator

    private var dotIndicator: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage
                          ? Color(red: 0.55, green: 0.60, blue: 0.98)
                          : Color.white.opacity(0.25))
                    .frame(width: i == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: Next button (slides 0–1)

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
            .background {
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
        .buttonStyle(.plain)
    }

    // MARK: Start Exploring button (slide 2)

    private var startButton: some View {
        Button(action: onFinish) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.38, green: 0.44, blue: 0.98),
                                     Color(red: 0.55, green: 0.28, blue: 0.92)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.55),
                        radius: 24, y: 10
                    )

                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Start Exploring")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
            }
            .frame(height: 60)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Individual slide

private struct SlideView: View {

    let slide: OnboardingSlide

    private let subtleText = Color.white.opacity(0.55)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon badge
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(slide.iconGradient)
                    .opacity(0.15)
                    .frame(width: 140, height: 140)
                    .blur(radius: 24)

                // Glass card
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

            // Text block
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(slide.body)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
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

// MARK: - Preview

#Preview {
    OnboardingView(onFinish: {})
}
