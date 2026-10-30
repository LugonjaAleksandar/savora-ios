import SwiftUI

/// One saved recipe. It only reports taps; the Saved screen navigates.
struct FavoriteTile: View {
    let meal: MealSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                RemoteImage(url: meal.previewURL)
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .zoomSource(id: meal.id)
                Text(meal.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(Spacing.sm)
            .padding(.trailing, Spacing.sm)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .shadow(color: Palette.shadow, radius: 14, y: 8)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
