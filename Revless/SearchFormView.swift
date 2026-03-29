// SearchFormView.swift
// Revless
//
// Premium dark search interface. Matches the #0A0E17→#1A1A2E gradient established
// in RouteResultsView. All inputs use the same ultraThinMaterial + 0.08 white
// opacity + hairline border glass treatment as ItineraryCard.

import SwiftUI

struct SearchFormView: View {

    @State private var viewModel = SearchViewModel()
    @State private var navigateToResults = false

    // MARK: - Palette

    private let bg = LinearGradient(
        colors: [Color(hex: "#0A0E17"), Color(hex: "#1A1A2E")],
        startPoint: .top, endPoint: .bottom
    )
    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.38, green: 0.44, blue: 0.98),   // electric indigo
            Color(red: 0.55, green: 0.28, blue: 0.92),   // deep violet
        ],
        startPoint: .leading, endPoint: .trailing
    )
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)
    private let subtleText  = Color.white.opacity(0.45)

    // MARK: - Body
    //
    // Layout:  ZStack (gradient bg)
    //          └─ VStack
    //              ├─ ScrollView (header, route block, date, traveler type)
    //              └─ bottomBar  (hero button, pinned with ultraThinMaterial)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            headerSection
                            routeBlock
                            dateBlock
                            travelerBlock
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                        .frame(maxWidth: 540)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)

                    bottomBar
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToResults) {
                RouteResultsView(viewModel: viewModel)
            }
            .alert("Out of Search Credits", isPresented: $viewModel.showOutOfCreditsAlert) {
                Button("Got It", role: .cancel) {}
            } message: {
                Text("You've used all your search credits.\n\nVerify a route on any results card to earn +5 credits and keep searching.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Find Routes")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("ZED-eligible itineraries for your crew")
                .font(.subheadline)
                .foregroundStyle(subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Route Block
    //
    // Two massive airport cards (IATA at 48pt bold rounded) with a
    // circular floating glass swap button centred between them.

    private var routeBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Route")

            HStack(spacing: 10) {
                airportCard(label: "FROM", icon: "airplane.departure", text: $viewModel.origin)
                swapButton.frame(width: 44)
                airportCard(label: "TO",   icon: "airplane.arrival",   text: $viewModel.destination)
            }
        }
    }

    @ViewBuilder
    private func airportCard(label: String, icon: String, text: Binding<String>) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(subtleText)
                .tracking(1.5)

            TextField("---", text: text)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .onChange(of: text.wrappedValue) { _, new in
                    let cleaned = String(new.uppercased().filter { $0.isLetter }.prefix(3))
                    if text.wrappedValue != cleaned { text.wrappedValue = cleaned }
                }

            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(accentColor.opacity(0.70))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 10)
        .background { glass() }
    }

    private var swapButton: some View {
        Button {
            withAnimation(.spring(response: 0.40, dampingFraction: 0.65)) {
                viewModel.swapAirports()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5))
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.30), radius: 10, y: 5)

                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Block
    //
    // .compact DatePicker renders a small tappable date button that opens an
    // inline calendar popover — far less intrusive than .graphical, and it
    // sits cleanly inside the glass container.

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Departure")

            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)

                DatePicker(
                    "",
                    selection: $viewModel.departureDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(accentColor)

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background { glass() }
        }
    }

    // MARK: - Traveler Type Block
    //
    // Custom segmented control: three glassmorphic pills.
    // The selected pill fills with the ctaGradient and emits a glowing shadow;
    // unselected pills remain frosted glass with a hairline border.

    private var travelerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Traveler Type")

            HStack(spacing: 8) {
                ForEach(TravelerType.allCases) { type in
                    travelerPill(type)
                }
            }
        }
    }

    @ViewBuilder
    private func travelerPill(_ type: TravelerType) -> some View {
        let selected = viewModel.travelerType == type
        Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.70)) {
                viewModel.travelerType = type
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: pillIcon(for: type))
                    .font(.system(size: 18))
                    .foregroundStyle(selected ? .white : subtleText)

                Text(type.rawValue.capitalized)
                    .font(.system(size: 12, weight: selected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(selected ? .white : subtleText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selected ? AnyShapeStyle(ctaGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                selected ? Color.clear : Color.white.opacity(0.14),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(
                color: selected ? accentColor.opacity(0.50) : .clear,
                radius: 12, y: 5
            )
        }
        .buttonStyle(.plain)
    }

    private func pillIcon(for type: TravelerType) -> String {
        switch type {
        case .employee:  return "briefcase.fill"
        case .spouse:    return "heart.fill"
        case .companion: return "person.2.fill"
        }
    }

    // MARK: - Pinned bottom bar

    private var bottomBar: some View {
        heroButton
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 34)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
    }

    // MARK: - Hero button
    //
    // Full-width, vibrant gradient fill, indigo glow shadow.
    // Glow intensity scales with the enabled state.

    private var heroButton: some View {
        let enabled = viewModel.origin.count == 3 && viewModel.destination.count == 3
        return Button { navigateToResults = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ctaGradient)
                    .shadow(
                        color: accentColor.opacity(enabled ? 0.65 : 0.20),
                        radius: 20, y: 8
                    )

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Find Routes")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
            }
            .frame(height: 58)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.50)
        .animation(.easeInOut(duration: 0.18), value: enabled)
    }

    // MARK: - Shared helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(subtleText)
            .textCase(.uppercase)
            .tracking(1.2)
    }

    /// Unified glass background: ultraThinMaterial + 8% white tint + 0.5pt hairline border.
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

// MARK: - Color(hex:) convenience initialiser

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
    SearchFormView()
        .environment(AuthViewModel())
}
