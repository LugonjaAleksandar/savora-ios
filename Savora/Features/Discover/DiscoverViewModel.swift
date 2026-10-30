import Foundation
import Observation

/// Drives the Discover tab. Every load is *restartable*: starting a new one
/// cancels the previous task, so a slow response can never overwrite a newer
/// selection. Search is debounced the same way.
@MainActor
@Observable
final class DiscoverViewModel {
    enum Status: Equatable {
        case loading
        case loaded
        case failed(AppFailure)
    }

    static let searchDebounce: Duration = .milliseconds(350)

    private(set) var status: Status = .loading
    private(set) var categories: [MealCategory] = []
    private(set) var selectedCategory: MealCategory?
    private(set) var meals: [MealSummary] = []
    private(set) var query = ""
    private(set) var isFetchingRandomMeal = false

    @ObservationIgnored private let repository: any MealsRepository
    @ObservationIgnored private let searchDebounce: Duration
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    init(repository: any MealsRepository, searchDebounce: Duration = DiscoverViewModel.searchDebounce) {
        self.repository = repository
        self.searchDebounce = searchDebounce
    }

    var isSearching: Bool {
        !query.isEmpty
    }

    func start() async {
        guard categories.isEmpty else {
            return
        }
        await restart { [self] in await loadCategoriesAndMeals(forceRefresh: false) }.value
    }

    func refresh() async {
        await restart { [self] in
            if isSearching {
                await search(query)
            } else if let selectedCategory {
                await loadMeals(in: selectedCategory)
            } else {
                status = .loading
                await loadCategoriesAndMeals(forceRefresh: true)
            }
        }.value
    }

    @discardableResult
    func select(_ category: MealCategory) -> Task<Void, Never> {
        if category == selectedCategory, !isSearching, status == .loaded {
            return Task {}
        }
        selectedCategory = category
        query = ""
        status = .loading
        return restart { [self] in await loadMeals(in: category) }
    }

    @discardableResult
    func searchChanged(_ text: String) -> Task<Void, Never> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != query else {
            return Task {}
        }
        query = trimmed
        status = .loading
        return restart { [self] in
            if trimmed.isEmpty {
                if let selectedCategory {
                    await loadMeals(in: selectedCategory)
                }
                return
            }
            do {
                try await Task.sleep(for: searchDebounce)
            } catch {
                return
            }
            await search(trimmed)
        }
    }

    /// The random pick is returned rather than stored: navigating to it is the
    /// screen's job, not the view model's.
    func randomMeal() async throws(AppFailure) -> MealSummary {
        isFetchingRandomMeal = true
        defer { isFetchingRandomMeal = false }
        return try await repository.randomMeal().summary
    }

    private func restart(_ operation: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        loadTask?.cancel()
        let task = Task { await operation() }
        loadTask = task
        return task
    }

    private func loadCategoriesAndMeals(forceRefresh: Bool) async {
        do {
            let categories = try await repository.categories(forceRefresh: forceRefresh)
            guard !Task.isCancelled else {
                return
            }
            self.categories = categories
            guard let category = selectedCategory ?? categories.first else {
                meals = []
                status = .loaded
                return
            }
            selectedCategory = category
            await loadMeals(in: category)
        } catch {
            apply(failure: error)
        }
    }

    private func loadMeals(in category: MealCategory) async {
        do {
            apply(meals: try await repository.meals(inCategory: category.name))
        } catch {
            apply(failure: error)
        }
    }

    private func search(_ query: String) async {
        do {
            apply(meals: try await repository.searchMeals(query))
        } catch {
            apply(failure: error)
        }
    }

    private func apply(meals: [MealSummary]) {
        guard !Task.isCancelled else {
            return
        }
        self.meals = meals
        status = .loaded
    }

    private func apply(failure: AppFailure) {
        guard !Task.isCancelled else {
            return
        }
        status = .failed(failure)
    }
}
