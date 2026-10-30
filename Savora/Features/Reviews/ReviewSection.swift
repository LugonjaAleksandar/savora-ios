import SwiftUI

/// Either a call to action or the saved review. Editing and deleting are
/// reported to the route, which owns the sheet and the confirmation toast.
struct ReviewSection: View {
    let review: MealReview?
    let onWrite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            if let review {
                SavedReviewCard(review: review, onEdit: onWrite, onDelete: onDelete)
            } else {
                ReviewCallToAction(onWrite: onWrite)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: review)
    }
}

private struct ReviewCallToAction: View {
    let onWrite: () -> Void

    @Environment(\.localizer) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(l10n("review_cta_title"))
                .font(.title3.weight(.bold))
            Text(l10n("review_cta_subtitle"))
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
            GradientButton(title: l10n("review_cta_button"), systemImage: "star.fill", action: onWrite)
                .padding(.top, Spacing.sm + 4)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg - 1.5, style: .continuous))
        .padding(1.5)
        .background(Palette.brandGradient, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

private struct SavedReviewCard: View {
    let review: MealReview
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Environment(\.localizer) private var l10n

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(l10n("review_section_title"))
                    .font(.title3.weight(.bold))
                Spacer()
                RatingStars(rating: review.rating, size: 20)
            }
            Text(l10n.ratingLabel(review.rating))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.primary)
            if !review.comment.isEmpty {
                Text("“\(review.comment)”")
                    .font(.body.italic())
                    .lineSpacing(4)
                    .padding(.top, Spacing.sm)
            }
            HStack {
                Text(l10n("review_updated_at", l10n.date(review.updatedAt)))
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
                Spacer()
                Button(l10n("review_edit"), systemImage: "pencil", action: onEdit)
                Button(l10n("review_delete"), systemImage: "trash", role: .destructive, action: onDelete)
                    .tint(Palette.danger)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Palette.stroke))
    }
}
