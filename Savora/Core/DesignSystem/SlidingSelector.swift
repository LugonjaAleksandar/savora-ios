import SwiftUI

/// Segmented control with one gradient thumb that slides between items via
/// `matchedGeometryEffect`. Used by the tab bar and the Settings pickers.
struct SlidingSelector<Item: Hashable, Label: View>: View {
    let items: [Item]
    @Binding var selection: Item
    var expandsSelected = false
    @ViewBuilder let label: (Item, Bool) -> Label

    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                let isSelected = item == selection
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        selection = item
                    }
                } label: {
                    label(item, isSelected)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Palette.brandGradient)
                                    .shadow(color: Palette.primary.opacity(0.32), radius: 10, y: 5)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                }
                .buttonStyle(PressableButtonStyle())
                .layoutPriority(expandsSelected && isSelected ? 1 : 0)
                .frame(maxWidth: expandsSelected && !isSelected ? 72 : .infinity)
            }
        }
    }
}
