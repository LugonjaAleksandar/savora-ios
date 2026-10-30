import Foundation

protocol MealsRepository: Sendable {
    func categories(forceRefresh: Bool) async throws(AppFailure) -> [MealCategory]
    func meals(inCategory category: String) async throws(AppFailure) -> [MealSummary]
    func searchMeals(_ query: String) async throws(AppFailure) -> [MealSummary]
    func meal(id: String) async throws(AppFailure) -> MealDetail
    func randomMeal() async throws(AppFailure) -> MealDetail
}

/// Caching strategy:
/// * categories and meal details change rarely, so they are **cache-first** with a TTL;
/// * category listings are **network-first**, falling back to the last cached copy when offline;
/// * search is network only (results are cheap and query-specific).
struct LiveMealsRepository: MealsRepository {
    static let categoriesTTL: Duration = .seconds(24 * 60 * 60)
    static let mealDetailTTL: Duration = .seconds(7 * 24 * 60 * 60)

    private let remote: MealsRemoteDataSource
    private let cache: MealsCache

    init(remote: MealsRemoteDataSource, cache: MealsCache) {
        self.remote = remote
        self.cache = cache
    }

    func categories(forceRefresh: Bool) async throws(AppFailure) -> [MealCategory] {
        let key = "categories"
        if !forceRefresh, let cached = cache.read([MealCategory].self, forKey: key, maxAge: Self.categoriesTTL) {
            return cached
        }
        return try await fetchAndCache(key: key) { () async throws(AppFailure) in try await remote.fetchCategories() }
    }

    func meals(inCategory category: String) async throws(AppFailure) -> [MealSummary] {
        try await fetchAndCache(key: "category_\(category)") { () async throws(AppFailure) in try await remote.fetchMeals(inCategory: category) }
    }

    func searchMeals(_ query: String) async throws(AppFailure) -> [MealSummary] {
        try await remote.searchMeals(query)
    }

    func meal(id: String) async throws(AppFailure) -> MealDetail {
        let key = "meal_\(id)"
        if let cached = cache.read(MealDetail.self, forKey: key, maxAge: Self.mealDetailTTL) {
            return cached
        }
        return try await fetchAndCache(key: key) { () async throws(AppFailure) in try await remote.fetchMeal(id: id) }
    }

    /// Warms the detail cache, so opening the random pick right after is instant.
    func randomMeal() async throws(AppFailure) -> MealDetail {
        let meal = try await remote.fetchRandomMeal()
        cache.write(meal, forKey: "meal_\(meal.id)")
        return meal
    }

    /// On success persists the value; on a network failure serves whatever is
    /// cached (ignoring the TTL), so the app stays usable offline.
    private func fetchAndCache<Value: Codable & Sendable>(key: String, fetch: () async throws(AppFailure) -> Value) async throws(AppFailure) -> Value {
        do {
            let value = try await fetch()
            cache.write(value, forKey: key)
            return value
        } catch {
            if error == .network, let stale = cache.read(Value.self, forKey: key, maxAge: nil) {
                return stale
            }
            throw error
        }
    }
}
