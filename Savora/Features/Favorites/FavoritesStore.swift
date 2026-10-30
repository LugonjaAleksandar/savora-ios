import Foundation
import Observation

protocol FavoritesRepository: Sendable {
    func favorites() -> [MealSummary]
    func save(_ favorites: [MealSummary])
}

/// Stores the full `MealSummary` (not just the id), so the Saved tab renders
/// instantly and offline, without a network round-trip per item.
struct LocalFavoritesRepository: FavoritesRepository {
    private static let key = "favorites"

    private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    func favorites() -> [MealSummary] {
        store.value([MealSummary].self, forKey: Self.key) ?? []
    }

    func save(_ favorites: [MealSummary]) {
        store.setValue(favorites, forKey: Self.key)
    }
}

/// App-wide, because the heart appears on grid cards, the detail screen and
/// the Saved tab at the same time.
@MainActor
@Observable
final class FavoritesStore {
    private(set) var favorites: [MealSummary]

    @ObservationIgnored private let repository: any FavoritesRepository

    init(repository: any FavoritesRepository) {
        self.repository = repository
        favorites = repository.favorites()
    }

    func isFavorite(_ mealID: String) -> Bool {
        favorites.contains { $0.id == mealID }
    }

    func toggle(_ meal: MealSummary) {
        if isFavorite(meal.id) {
            remove(meal.id)
        } else {
            add(meal)
        }
    }

    /// New favorites go to the top; `index` restores a removed one to where it was.
    func add(_ meal: MealSummary, at index: Int = 0) {
        guard !isFavorite(meal.id) else {
            return
        }
        var updated = favorites
        updated.insert(meal, at: min(max(index, 0), updated.count))
        update(updated)
    }

    /// Returns the removed position, so the caller can offer an undo.
    @discardableResult
    func remove(_ mealID: String) -> Int? {
        guard let index = favorites.firstIndex(where: { $0.id == mealID }) else {
            return nil
        }
        var updated = favorites
        updated.remove(at: index)
        update(updated)
        return index
    }

    private func update(_ favorites: [MealSummary]) {
        self.favorites = favorites
        repository.save(favorites)
    }
}
