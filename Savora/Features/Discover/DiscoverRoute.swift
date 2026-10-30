import SwiftUI

struct DiscoverRoute: View {
    /// Roughly the greeting block's height, after which the search field is pinned.
    private static let pinnedSearchOffset: CGFloat = 190

    @State private var viewModel: DiscoverViewModel
    @State private var searchText = ""
    @State private var isSearchPinned = false

    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Environment(\.localizer) private var l10n

    init(repository: any MealsRepository) {
        _viewModel = State(initialValue: DiscoverViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                DiscoverHeader(isFetchingRandomMeal: viewModel.isFetchingRandomMeal, onSurpriseMe: openRandomMeal)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                Section {
                    CategoryChips(categories: viewModel.categories, selected: viewModel.selectedCategory, isDimmed: viewModel.isSearching) { category in
                        searchText = ""
                        viewModel.select(category)
                    }
                    .padding(.vertical, Spacing.md)

                    DiscoverSectionTitle(viewModel: viewModel)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.bottom, Spacing.md)

                    DiscoverContent(viewModel: viewModel, onMealTap: router.openMeal)
                        .padding(.horizontal, Spacing.lg)
                } header: {
                    SearchField(text: $searchText, placeholder: l10n("meals_search_hint"))
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background {
                            // Only once pinned, so the resting header blends into the glow.
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .ignoresSafeArea(edges: .top)
                                .opacity(isSearchPinned ? 1 : 0)
                        }
                        .animation(.easeOut(duration: 0.2), value: isSearchPinned)
                }
            }
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > Self.pinnedSearchOffset
        } action: { _, isPinned in
            isSearchPinned = isPinned
        }
        .scrollDismissesKeyboard(.immediately)
        .background(GlowBackground())
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: searchText) { _, text in
            viewModel.searchChanged(text)
        }
    }

    private func openRandomMeal() {
        Task {
            do throws(AppFailure) {
                router.openMeal(try await viewModel.randomMeal())
            } catch {
                toasts.show(l10n.message(for: error))
            }
        }
    }
}

private struct DiscoverSectionTitle: View {
    let viewModel: DiscoverViewModel

    @Environment(\.localizer) private var l10n

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(24))
                .lineLimit(1)
                .contentTransition(.opacity)
            Spacer()
            if viewModel.status == .loaded {
                Text(l10n("meals_count", viewModel.meals.count))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Palette.primary.opacity(0.1), in: Capsule())
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.status)
    }

    private var title: String {
        if viewModel.isSearching {
            return l10n("meals_section_search", viewModel.query)
        }
        return viewModel.selectedCategory.map { l10n("meals_section_category", $0.name) } ?? ""
    }
}

private struct DiscoverContent: View {
    private static let columns = [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)]

    let viewModel: DiscoverViewModel
    let onMealTap: (MealSummary) -> Void

    @Environment(\.localizer) private var l10n

    var body: some View {
        switch viewModel.status {
        case .loading:
            LazyVGrid(columns: Self.columns, spacing: Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(Palette.surfaceRaised)
                        .aspectRatio(MealCard.aspectRatio, contentMode: .fit)
                        .shimmering()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                }
            }
        case .failed(let failure):
            StateMessageView(systemImage: "wifi.slash", title: l10n.message(for: failure), actionTitle: l10n("action_retry")) {
                Task { await viewModel.refresh() }
            }
        case .loaded where viewModel.meals.isEmpty:
            StateMessageView(systemImage: "takeoutbag.and.cup.and.straw", title: l10n("meals_empty_title"), subtitle: l10n("meals_empty_subtitle"))
        case .loaded:
            LazyVGrid(columns: Self.columns, spacing: Spacing.md) {
                ForEach(Array(viewModel.meals.enumerated()), id: \.element.id) { index, meal in
                    MealCard(meal: meal) {
                        onMealTap(meal)
                    }
                    .staggeredEntrance(index: index)
                }
            }
            // Re-identify per result set so the staggered entrance replays on every category or query.
            .id("\(viewModel.selectedCategory?.id ?? "")-\(viewModel.query)")
        }
    }
}

private extension View {
    func staggeredEntrance(index: Int) -> some View {
        modifier(StaggeredEntrance(delay: Double(index % 8) * 0.05))
    }
}

private struct StaggeredEntrance: ViewModifier {
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .offset(y: isVisible ? 0 : 24)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85).delay(delay)) {
                    isVisible = true
                }
            }
    }
}
