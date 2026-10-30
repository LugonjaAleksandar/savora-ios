import SwiftUI

struct FavoritesRoute: View {
    @Environment(FavoritesStore.self) private var favorites
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.localizer) private var l10n

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(l10n("favorites_title"))
                    .font(.display(38))
                Text(l10n("favorites_subtitle", favorites.favorites.count))
                    .font(.headline)
                    .foregroundStyle(Palette.textSecondary)
                    .contentTransition(.numericText())
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
            .plainRow()

            if favorites.favorites.isEmpty {
                StateMessageView(systemImage: "heart.fill", title: l10n("favorites_empty_title"), subtitle: l10n("favorites_empty_subtitle"))
                    .padding(.top, 120)
                    .plainRow()
            }

            ForEach(favorites.favorites) { meal in
                FavoriteTile(meal: meal) {
                    router.openMeal(meal)
                }
                .plainRow()
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        remove(meal)
                    } label: {
                        Label(l10n("review_delete"), systemImage: "trash")
                    }
                }
            }

            Color.clear
                .frame(height: Spacing.tabBarClearance)
                .plainRow()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(GlowBackground())
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: favorites.favorites)
    }

    private func remove(_ meal: MealSummary) {
        guard let index = favorites.remove(meal.id) else {
            return
        }
        toasts.show(l10n("favorites_removed"), actionTitle: l10n("favorites_undo")) { [favorites] in
            favorites.add(meal, at: index)
        }
    }
}

private extension View {
    func plainRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
    }
}
