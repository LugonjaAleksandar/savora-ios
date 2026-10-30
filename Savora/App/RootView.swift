import SwiftUI

/// App shell: one `NavigationStack` above the three tabs, so a pushed recipe
/// covers the floating tab bar, and every tab keeps its state while hidden.
struct RootView: View {
    let container: AppContainer

    @State private var router = Router()
    @State private var toasts = ToastCenter()
    @Namespace private var zoom

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                tab(.discover) {
                    DiscoverRoute(repository: container.mealsRepository)
                }
                tab(.favorites) {
                    FavoritesRoute()
                }
                tab(.settings) {
                    SettingsRoute()
                }
                FloatingTabBar(selection: $router.selectedTab)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xs)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .meal(let meal):
                    MealDetailRoute(meal: meal, mealsRepository: container.mealsRepository, reviewsRepository: container.reviewsRepository)
                        .navigationTransition(.zoom(sourceID: meal.id, in: zoom))
                }
            }
        }
        .overlay(alignment: .bottom) {
            ToastOverlay()
        }
        .environment(router)
        .environment(toasts)
        .environment(container.favorites)
        .environment(container.settings)
        .environment(\.localizer, container.settings.localizer)
        .environment(\.zoomNamespace, zoom)
        .preferredColorScheme(container.settings.theme.colorScheme)
        .tint(Palette.primary)
    }

    private func tab(_ tab: AppTab, @ViewBuilder content: () -> some View) -> some View {
        let isSelected = router.selectedTab == tab
        return content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

private struct FloatingTabBar: View {
    @Binding var selection: AppTab

    @Environment(\.localizer) private var l10n

    var body: some View {
        SlidingSelector(items: AppTab.allCases, selection: $selection, expandsSelected: true) { tab, isSelected in
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon(for: tab, isSelected: isSelected))
                    .font(.system(size: 19, weight: .semibold))
                if isSelected {
                    // Ideal width, so the label is never truncated to the
                    // narrow width it has while the pill is still growing.
                    Text(title(for: tab))
                        .font(.subheadline.weight(.bold))
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundStyle(isSelected ? .white : Palette.textSecondary)
            .accessibilityLabel(title(for: tab))
        }
        .frame(height: 56)
        .padding(6)
        .glassCapsule()
    }

    private func icon(for tab: AppTab, isSelected: Bool) -> String {
        switch tab {
        case .discover: isSelected ? "safari.fill" : "safari"
        case .favorites: isSelected ? "heart.fill" : "heart"
        case .settings: "slider.horizontal.3"
        }
    }

    private func title(for tab: AppTab) -> String {
        switch tab {
        case .discover: l10n("nav_discover")
        case .favorites: l10n("nav_favorites")
        case .settings: l10n("nav_settings")
        }
    }
}

private struct ToastOverlay: View {
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.localizer) private var l10n

    var body: some View {
        if let toast = toasts.current {
            HStack(spacing: Spacing.md) {
                Text(toast.message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.background)
                Spacer(minLength: 0)
                if let actionTitle = toast.actionTitle {
                    Button(actionTitle, action: toasts.performAction)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.star)
                }
            }
            .padding(.horizontal, Spacing.md + 4)
            .padding(.vertical, 14)
            .background(Palette.textPrimary, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .shadow(color: Palette.shadow, radius: 16, y: 8)
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, 84)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .id(toast.id)
        }
    }
}

extension View {
    /// Liquid Glass on iOS 26, a material capsule before that.
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular, in: Capsule())
        } else {
            background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.35)))
                .shadow(color: Palette.shadow, radius: 20, y: 10)
        }
    }
}
