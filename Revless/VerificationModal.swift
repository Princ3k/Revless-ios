// VerificationModal.swift
// Revless
//
// Crowdsourced verification sheet. Shown when an itinerary carries a stale
// agreement rule (confidence_score < 3). The user answers whether the carrier
// is still allowing the given traveler type, which calls POST /agreements/verify
// and earns them +5 search credits.

import SwiftUI

struct VerificationModal: View {

    let rule: StaleRule
    let travelerType: TravelerType
    /// Called with the user's answer. The sheet should be dismissed by the
    /// parent via the sheet(item:) binding, NOT imperatively here — this keeps
    /// the contract clean.
    var onAnswer: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var hasAnswered = false
    @State private var chosenAccurate: Bool? = nil

    // MARK: - Palette

    private let bg         = Color(red: 0.06, green: 0.07, blue: 0.13)
    private let cardBorder = Color.white.opacity(0.08)
    private let subtleText = Color.white.opacity(0.45)

    // MARK: - Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                if hasAnswered {
                    thanksView
                } else {
                    questionView
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.hidden)   // custom indicator above
        .presentationCornerRadius(28)
        .presentationBackground(bg)
    }

    // MARK: - Question view

    private var questionView: some View {
        VStack(spacing: 28) {

            // Top icon + carrier badge
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.orange)
                }

                carrierBadge
            }

            // Question text
            VStack(spacing: 8) {
                Text("Help verify this route")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Is **\(rule.carrierName)** still allowing **\(travelerType.displayName.lowercased())** travel on this route?")
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }

            confidenceIndicator

            // Yes / No buttons
            HStack(spacing: 12) {
                answerButton(
                    label: "No, it's changed",
                    icon: "xmark.circle.fill",
                    isAccurate: false,
                    color: .red
                )
                answerButton(
                    label: "Yes, still valid",
                    icon: "checkmark.circle.fill",
                    isAccurate: true,
                    color: .green
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Carrier badge

    private var carrierBadge: some View {
        HStack(spacing: 8) {
            Text(rule.carrierIata)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.38, green: 0.44, blue: 0.98).opacity(0.20))
                )
            Text(rule.carrierName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(subtleText)
        }
    }

    // MARK: - Confidence indicator

    private var confidenceIndicator: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Community confidence")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(subtleText)
                Spacer()
                Text("\(rule.confidenceScore) / 10")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(confidenceGradient)
                        .frame(
                            width: geo.size.width * CGFloat(rule.confidenceScore) / 10.0,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 20)
    }

    private var confidenceGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .orange.opacity(0.6)],
            startPoint: .leading, endPoint: .trailing
        )
    }

    // MARK: - Answer button

    @ViewBuilder
    private func answerButton(label: String, icon: String, isAccurate: Bool, color: Color) -> some View {
        Button {
            chosenAccurate = isAccurate
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                hasAnswered = true
            }
            // Give the animation a moment to play, then dismiss
            onAnswer(isAccurate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                dismiss()
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(color.opacity(0.10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(color.opacity(0.25), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Thanks view (shown after answering)

    private var thanksView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.yellow)
                    .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hasAnswered)

            VStack(spacing: 8) {
                Text("Thank you!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your verification helps keep the community's data accurate.")
                    .font(.subheadline)
                    .foregroundStyle(subtleText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            // Credits reward pill
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                Text("+5 search credits")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.green.opacity(0.12)))
        }
        .padding(.horizontal, 32)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            VerificationModal(
                rule: StaleRule(
                    ruleId: UUID(),
                    carrierIata: "QR",
                    carrierName: "Qatar Airways",
                    confidenceScore: 2
                ),
                travelerType: .companion,
                onAnswer: { _ in }
            )
        }
}
