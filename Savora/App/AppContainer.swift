import Foundation

/// Composition root: the only place concrete implementations are chosen.
/// Everything below receives its dependencies through initializers.
@MainActor
final class AppContainer {
    nonisolated static let mealDBBaseURL = URL(string: "https://www.themealdb.com/api/json/v1/1/")!

    let mealsRepository: any MealsRepository
    let reviewsRepository: any ReviewsRepository
    let favorites: FavoritesStore
    let settings: SettingsStore

    init(mealsRepository: any MealsRepository, reviewsRepository: any ReviewsRepository, favorites: FavoritesStore, settings: SettingsStore) {
        self.mealsRepository = mealsRepository
        self.reviewsRepository = reviewsRepository
        self.favorites = favorites
        self.settings = settings
    }

    static func live() -> AppContainer {
        // Generous HTTP cache, so meal photos load once and render offline.
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024)

        let store = UserDefaultsStore()
        let apiClient = APIClient(transport: URLSessionTransport(session: .shared), baseURL: mealDBBaseURL)
        return AppContainer(
            mealsRepository: LiveMealsRepository(remote: MealsRemoteDataSource(apiClient: apiClient), cache: MealsCache(store: store)),
            reviewsRepository: LocalReviewsRepository(store: store),
            favorites: FavoritesStore(repository: LocalFavoritesRepository(store: store)),
            settings: SettingsStore(repository: LocalSettingsRepository(store: store))
        )
    }
}
