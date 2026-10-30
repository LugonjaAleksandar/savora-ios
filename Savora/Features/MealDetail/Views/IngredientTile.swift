import SwiftUI

/// One ingredient in the detail grid.
struct IngredientTile: View {
    let ingredient: Ingredient

    var body: some View {
        HStack(spacing: Spacing.sm) {
            RemoteImage(url: ingredient.imageURL, contentMode: .fit)
                .padding(6)
                .frame(width: 52, height: 52)
                .background(Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                if !ingredient.measure.isEmpty {
                    Text(ingredient.measure)
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.sm)
        .frame(height: 72)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(Palette.stroke))
    }
}
