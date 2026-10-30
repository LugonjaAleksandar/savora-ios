import SwiftUI

/// Horizontal category picker. The gradient pill is one view that moves
/// between chips with `matchedGeometryEffect`, so only the selector slides
/// while the chips themselves never shift.
struct CategoryChips: View {
    let categories: [MealCategory]
    let selected: MealCategory?
    let isDimmed: Bool
    let onSelect: (MealCategory) -> Void

    @Namespace private var pill

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm + 4) {
                    ForEach(categories) { category in
                        CategoryChip(category: category, isSelected: category == selected && !isDimmed, pill: pill) {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                onSelect(category)
                                proxy.scrollTo(category.id, anchor: .center)
                            }
                        }
                        .id(category.id)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                // Room for the selected chip's shadow, so it is not clipped by the scroll view.
                .padding(.vertical, Spacing.md)
            }
            .padding(.vertical, -Spacing.md)
        }
        .opacity(isDimmed ? 0.55 : 1)
        .animation(.easeOut(duration: 0.2), value: isDimmed)
    }
}
