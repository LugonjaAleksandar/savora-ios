import SwiftUI

/// The loaded recipe. Links and the review sheet are reported upwards, so
/// the route stays the only place that navigates or presents.
struct MealDetailContent: View {
    private static let ingredientColumns = [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)]

    let meal: MealDetail
    let review: MealReview?
    let onWriteReview: () -> Void
    let onDeleteReview: () -> Void
    let onOpenLink: (URL) -> Void

    @Environment(\.localizer) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(meal.name)
                .font(.display(30))
                .padding(.bottom, Spacing.md)

            FlowLayout {
                if let category = meal.category {
                    MetaChip(systemImage: "fork.knife", label: category)
                }
                if let area = meal.area {
                    MetaChip(systemImage: "globe.europe.africa.fill", label: area)
                }
                MetaChip(systemImage: "basket.fill", label: l10n("detail_ingredients_count", meal.ingredients.count))
                ForEach(meal.tags, id: \.self) { tag in
                    MetaChip(systemImage: "number", label: tag)
                }
            }
            .padding(.bottom, Spacing.lg)

            ReviewSection(review: review, onWrite: onWriteReview, onDelete: onDeleteReview)
                .padding(.bottom, Spacing.xl)

            SectionHeading(title: l10n("detail_ingredients"), trailing: "\(meal.ingredients.count)")
            LazyVGrid(columns: Self.ingredientColumns, spacing: Spacing.sm) {
                ForEach(Array(meal.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    IngredientTile(ingredient: ingredient)
                }
            }
            .padding(.bottom, Spacing.xl)

            SectionHeading(title: l10n("detail_instructions"))
            InstructionSteps(steps: meal.steps)

            if meal.hasVideo || meal.hasSource {
                HStack(spacing: Spacing.sm) {
                    if let url = meal.youtubeURL, meal.hasVideo {
                        Button {
                            onOpenLink(url)
                        } label: {
                            Label(l10n("detail_watch_video"), systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: 0xFF0033))
                    }
                    if let url = meal.sourceURL, meal.hasSource {
                        Button {
                            onOpenLink(url)
                        } label: {
                            Label(l10n("detail_source"), systemImage: "arrow.up.right.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .controlSize(.large)
                .font(.subheadline.weight(.bold))
                .padding(.top, Spacing.sm)
            }
        }
    }
}

private struct SectionHeading: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(24))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(.bottom, Spacing.md)
    }
}

private struct MetaChip: View {
    let systemImage: String
    let label: String

    var body: some View {
        Label(label, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.textPrimary)
            .labelStyle(MetaChipLabelStyle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Palette.surfaceRaised, in: Capsule())
    }
}

private struct MetaChipLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(Palette.primary)
            configuration.title
        }
    }
}

private struct InstructionSteps: View {
    let steps: [String]

    @Environment(\.localizer) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(spacing: Spacing.xs) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Palette.brandGradient, in: Circle())
                        if index < steps.count - 1 {
                            LinearGradient(colors: [Palette.primary.opacity(0.5), Palette.stroke], startPoint: .top, endPoint: .bottom)
                                .frame(width: 2)
                                .clipShape(Capsule())
                        }
                    }
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(l10n("detail_step", index + 1))
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Palette.primary)
                        Text(step)
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
    }
}
