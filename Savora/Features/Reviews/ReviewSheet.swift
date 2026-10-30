import SwiftUI

struct ReviewSheet: View {
    let onSave: (Int, String) -> Void

    @State private var rating: Int
    @State private var comment: String

    @Environment(\.localizer) private var l10n

    init(initialReview: MealReview?, onSave: @escaping (Int, String) -> Void) {
        self.onSave = onSave
        _rating = State(initialValue: initialReview?.rating ?? 0)
        _comment = State(initialValue: initialReview?.comment ?? "")
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(l10n("review_sheet_title"))
                .font(.display(28))
                .padding(.top, Spacing.lg)

            HStack(spacing: Spacing.sm) {
                ForEach(MealReview.ratingRange, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = star
                        }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 38))
                            .foregroundStyle(star <= rating ? Palette.star : Palette.textTertiary)
                            .scaleEffect(star == rating ? 1.15 : 1)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.85))
                }
            }
            .sensoryFeedback(.selection, trigger: rating)

            Text(rating == 0 ? " " : l10n.ratingLabel(rating))
                .font(.headline)
                .foregroundStyle(Palette.primary)
                .contentTransition(.opacity)

            TextField(l10n("review_comment_hint"), text: $comment, axis: .vertical)
                .lineLimit(3...6)
                .padding(Spacing.md)
                .background(Palette.surfaceRaised, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

            Button {
                onSave(rating, comment)
            } label: {
                Text(l10n("review_save"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Palette.brandGradient, in: Capsule())
                    .opacity(rating == 0 ? 0.5 : 1)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(rating == 0)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .presentationDetents([.height(460), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Radius.lg + 4)
        .presentationBackground(Palette.background)
    }
}
