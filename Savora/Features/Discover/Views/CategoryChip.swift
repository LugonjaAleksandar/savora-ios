import SwiftUI

/// One category in `CategoryChips`. It only reports taps.
struct CategoryChip: View {
    let category: MealCategory
    let isSelected: Bool
    let pill: Namespace.ID
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm + 2) {
                RemoteImage(url: category.thumbnailURL, contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .padding(5)
                    .background(isSelected ? .white.opacity(0.25) : Palette.surfaceRaised, in: Circle())
                Text(category.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? .white : Palette.textPrimary)
            }
            .padding(.leading, 6)
            .padding(.trailing, Spacing.md + 2)
            .frame(height: 56)
            .background {
                ZStack {
                    Capsule()
                        .fill(Palette.surface)
                        .overlay(Capsule().strokeBorder(Palette.stroke))
                    if isSelected {
                        Capsule()
                            .fill(Palette.brandGradient)
                            .shadow(color: Palette.primary.opacity(0.35), radius: 12, y: 6)
                            .matchedGeometryEffect(id: "pill", in: pill)
                    }
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
