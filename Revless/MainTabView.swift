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
    @Environment(ThemeManager.self) private var theme

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private var accentColor: Color { theme.accent }

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

        // Only style the unselected state here; the selected colour is
        // driven by SwiftUI's .tint(accentColor) so ThemeManager changes
        // (Porter dark-blue vs. generic indigo) propagate automatically.
        item.normal.iconColor = unselected
        item.normal.titleTextAttributes = [
            .foregroundColor: unselected,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        item.selected.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

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

            AgreementMatrixView()
                .tabItem { Label("Agreements", systemImage: "doc.text.magnifyingglass") }
                .tag(2)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(3)
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

// MARK: - Preview

#Preview {
    MainTabView()
        .environment(AuthViewModel())
        .environment(RecentSearchStore())
        .environment(ThemeManager())
}
