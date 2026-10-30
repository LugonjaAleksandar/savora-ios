import SwiftUI

/// Grid item. It only reports taps; the screen decides where to navigate.
struct MealCard: View {
    static let aspectRatio: CGFloat = 0.74

    let meal: MealSummary
    let onTap: () -> Void

    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        Button(action: onTap) {
            Color.clear
                .aspectRatio(Self.aspectRatio, contentMode: .fit)
                .overlay {
                    RemoteImage(url: meal.previewURL)
                }
                .overlay {
                    LinearGradient(stops: [.init(color: .clear, location: 0.45), .init(color: .black.opacity(0.85), location: 1)], startPoint: .top, endPoint: .bottom)
                }
                .overlay(alignment: .bottomLeading) {
                    Text(meal.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(Spacing.md)
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .zoomSource(id: meal.id)
                .shadow(color: Palette.shadow, radius: 16, y: 10)
        }
        .buttonStyle(PressableButtonStyle())
        .overlay(alignment: .topTrailing) {
            FavoriteButton(isFavorite: favorites.isFavorite(meal.id)) {
                favorites.toggle(meal)
            }
            .padding(Spacing.sm + 2)
        }
    }
}

/// Glass heart toggle shared by the grid card and the detail screen.
struct FavoriteButton: View {
    let isFavorite: Bool
    /// iOS 26 already draws toolbar items on glass, so they skip the own backdrop.
    var isInToolbar = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(isFavorite ? Palette.primary : .white)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isFavorite)
                .frame(width: 40, height: 40)
                .background {
                    if needsOwnBackdrop {
                        Circle().fill(.ultraThinMaterial.opacity(0.9))
                    }
                }
                .environment(\.colorScheme, .dark)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.88))
        .sensoryFeedback(.selection, trigger: isFavorite)
    }

    private var needsOwnBackdrop: Bool {
        guard isInToolbar else {
            return true
        }
        if #available(iOS 26, *) {
            return false
        }
        return true
    }
}
