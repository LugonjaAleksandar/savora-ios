import SwiftUI

struct DiscoverHeader: View {
    let isFetchingRandomMeal: Bool
    let onSurpriseMe: () -> Void

    @Environment(\.localizer) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(greeting)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                Spacer()
                GradientButton(title: l10n("meals_surprise_me"), systemImage: "dice.fill", isLoading: isFetchingRandomMeal, action: onSurpriseMe)
            }
            title
                .font(.display(38))
                .lineSpacing(-4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, Spacing.md)
    }

    private var title: Text {
        let highlight = Text(l10n("meals_header_title_highlight"))
            .italic()
            .foregroundStyle(Palette.brandGradient)
        return Text("\(l10n("meals_header_title_prefix")) \(highlight)\(l10n("meals_header_title_suffix"))")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 {
            return l10n("greeting_morning")
        }
        return hour < 18 ? l10n("greeting_afternoon") : l10n("greeting_evening")
    }
}
