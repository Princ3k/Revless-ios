// MainTabView.swift
// Revless
//
// Root navigation shell. Owns the selected-tab state so child views (e.g.
// HomeDashboardView) can programmatically switch tabs via a Binding.
//
// Tab bar appearance is configured imperatively through UIKit so we get
// full control over the glass blur, unselected opacity, and selected tint
// without fighting SwiftUI's default opaque white bar.

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    // Accent colour duplicated here so the tint modifier has access
    private let accentColor = Color(red: 0.55, green: 0.60, blue: 0.98)

    // MARK: - Tab bar appearance (UIKit)

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        // Ultra-thin dark blur — the deep navy gradient shows through
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor  = UIColor(white: 1.0, alpha: 0.04)

        // Hairline separator
        appearance.shadowColor = UIColor(white: 1.0, alpha: 0.08)

        let item = UITabBarItemAppearance()
        let unselected = UIColor(white: 1.0, alpha: 0.38)
        let selected   = UIColor(red: 0.55, green: 0.60, blue: 0.98, alpha: 1.0)

        item.normal.iconColor   = unselected
        item.selected.iconColor = selected
        item.normal.titleTextAttributes   = [.foregroundColor: unselected,
                                             .font: UIFont.systemFont(ofSize: 10, weight: .medium)]
        item.selected.titleTextAttributes = [.foregroundColor: selected,
                                             .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]

        appearance.stackedLayoutAppearance      = item
        appearance.inlineLayoutAppearance       = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance  = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeDashboardView(selectedTab: $selectedTab)
                .tabItem { Label("Home",    systemImage: "house.fill") }
                .tag(0)

            SearchFormView()
                .tabItem { Label("Search",  systemImage: "magnifyingglass") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(2)
        }
        .tint(accentColor)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { _ in }
        )) {
            OnboardingView {
                hasSeenOnboarding = true
            }
            .interactiveDismissDisabled()
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
    MainTabView()
        .environment(AuthViewModel())
        .environment(RecentSearchStore())
}
