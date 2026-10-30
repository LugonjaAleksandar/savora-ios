import Foundation

/// TheMealDB endpoints. TheMealDB answers "no results" with `{"meals": null}`
/// rather than `[]`, which the envelopes normalise to an empty list.
struct MealsRemoteDataSource: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchCategories() async throws(AppFailure) -> [MealCategory] {
        try await apiClient.get("categories.php", as: CategoriesEnvelope.self).categories ?? []
    }

    func fetchMeals(inCategory category: String) async throws(AppFailure) -> [MealSummary] {
        try await apiClient.get("filter.php", query: ["c": category], as: MealsEnvelope<MealSummary>.self).meals ?? []
    }

    func searchMeals(_ query: String) async throws(AppFailure) -> [MealSummary] {
        try await apiClient.get("search.php", query: ["s": query], as: MealsEnvelope<MealSummary>.self).meals ?? []
    }

    func fetchMeal(id: String) async throws(AppFailure) -> MealDetail {
        try await first(of: apiClient.get("lookup.php", query: ["i": id], as: MealsEnvelope<MealDetail>.self))
    }

    func fetchRandomMeal() async throws(AppFailure) -> MealDetail {
        try await first(of: apiClient.get("random.php", as: MealsEnvelope<MealDetail>.self))
    }

    private func first(of envelope: MealsEnvelope<MealDetail>) throws(AppFailure) -> MealDetail {
        guard let meal = envelope.meals?.first else {
            throw .notFound
        }
        return meal
    }
}

private struct CategoriesEnvelope: Decodable {
    let categories: [MealCategory]?
}

private struct MealsEnvelope<Meal: Decodable>: Decodable {
    let meals: [Meal]?
}
