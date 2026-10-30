import SwiftUI

struct MealDetailRoute: View {
    private static let imageHeight: CGFloat = 380
    private static let sheetOverlap: CGFloat = 32

    @State private var viewModel: MealDetailViewModel
    @State private var reviewModel: MealReviewModel
    @State private var isReviewSheetPresented = false

    @Environment(FavoritesStore.self) private var favorites
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.localizer) private var l10n
    @Environment(\.openURL) private var openURL

    init(meal: MealSummary, mealsRepository: any MealsRepository, reviewsRepository: any ReviewsRepository) {
        _viewModel = State(initialValue: MealDetailViewModel(preview: meal, repository: mealsRepository))
        _reviewModel = State(initialValue: MealReviewModel(mealID: meal.id, repository: reviewsRepository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                StretchyHeader(height: Self.imageHeight) {
                    HeaderImage(meal: viewModel.summary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    switch viewModel.state {
                    case .loading:
                        DetailSkeleton(title: viewModel.preview.name)
                            .transition(.opacity)
                    case .failed(let failure):
                        StateMessageView(systemImage: "fork.knife", title: l10n.message(for: failure), actionTitle: l10n("action_retry")) {
                            Task { await viewModel.load() }
                        }
                    case .loaded(let meal):
                        MealDetailContent(
                            meal: meal,
                            review: reviewModel.review,
                            onWriteReview: { isReviewSheetPresented = true },
                            onDeleteReview: deleteReview,
                            onOpenLink: { openURL($0) }
                        )
                        .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 24)), removal: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.9), value: viewModel.state)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.background, in: UnevenRoundedRectangle(topLeadingRadius: Self.sheetOverlap, topTrailingRadius: Self.sheetOverlap, style: .continuous))
                .padding(.top, -Self.sheetOverlap)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Palette.background)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(isFavorite: favorites.isFavorite(viewModel.preview.id), isInToolbar: true) {
                    favorites.toggle(viewModel.summary)
                }
            }
        }
        .sheet(isPresented: $isReviewSheetPresented) {
            ReviewSheet(initialReview: reviewModel.review) { rating, comment in
                reviewModel.save(rating: rating, comment: comment)
                isReviewSheetPresented = false
                toasts.show(l10n("review_saved"))
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private func deleteReview() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            reviewModel.delete()
        }
        toasts.show(l10n("review_deleted"))
    }
}

/// Grows with overscroll instead of revealing a gap above the image.
private struct StretchyHeader<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let overscroll = max(proxy.frame(in: .scrollView).minY, 0)
            content()
                .frame(width: proxy.size.width, height: height + overscroll)
                .clipped()
                .offset(y: -overscroll)
        }
        .frame(height: height)
    }
}

/// The preview the grid already decoded sits underneath, so the zoom never
/// lands on an empty frame; the full-resolution image fades in over it.
private struct HeaderImage: View {
    let meal: MealSummary

    var body: some View {
        ZStack {
            RemoteImage(url: meal.previewURL)
            RemoteImage(url: meal.thumbnailURL)
            LinearGradient(colors: [.black.opacity(0.35), .clear, .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct DetailSkeleton: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.display(30))
            HStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Palette.surfaceRaised).frame(width: 90, height: 34)
                }
            }
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .fill(Palette.surfaceRaised)
                .frame(height: 150)
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(Palette.surfaceRaised)
                    .frame(height: 64)
            }
        }
        .shimmering()
    }
}
