import Foundation
import Testing
@testable import Savora

struct MealsRepositoryTests {
    private let clock = TestClock()
    private let store = InMemoryKeyValueStore()

    private func repository(_ transport: StubTransport) -> LiveMealsRepository {
        let apiClient = APIClient(transport: transport, baseURL: AppContainer.mealDBBaseURL)
        return LiveMealsRepository(remote: MealsRemoteDataSource(apiClient: apiClient), cache: MealsCache(store: store, now: { [clock] in clock.now }))
    }

    @Test func categoriesAreServedFromCacheWithinTTL() async throws {
        let transport = StubTransport(.json(Fixtures.categoriesJSON))
        let repository = repository(transport)

        _ = try await repository.categories(forceRefresh: false)
        clock.advance(by: .seconds(60 * 60))
        let cached = try await repository.categories(forceRefresh: false)

        #expect(cached.map(\.name) == ["Beef"])
        #expect(transport.requestedURLs.count == 1)
    }

    @Test func expiredCategoriesAreRefetched() async throws {
        let transport = StubTransport(.json(Fixtures.categoriesJSON), .json(Fixtures.categoriesJSON))
        let repository = repository(transport)

        _ = try await repository.categories(forceRefresh: false)
        clock.advance(by: LiveMealsRepository.categoriesTTL + .seconds(1))
        _ = try await repository.categories(forceRefresh: false)

        #expect(transport.requestedURLs.count == 2)
    }

    @Test func categoryListingFallsBackToStaleCacheWhenOffline() async throws {
        let repository = repository(StubTransport(.json(Fixtures.listingJSON), .failure(.notConnectedToInternet)))

        _ = try await repository.meals(inCategory: "Chicken")
        clock.advance(by: .seconds(30 * 24 * 60 * 60))
        let offline = try await repository.meals(inCategory: "Chicken")

        #expect(offline == [Fixtures.summary])
    }

    @Test func serverErrorsAreNotMaskedByCache() async throws {
        let repository = repository(StubTransport(.json(Fixtures.listingJSON), .json("{}", status: 500)))

        _ = try await repository.meals(inCategory: "Chicken")

        await #expect(throws: AppFailure.server(statusCode: 500)) {
            try await repository.meals(inCategory: "Chicken")
        }
    }

    @Test func randomMealWarmsTheDetailCache() async throws {
        let transport = StubTransport(.json(#"{"meals": [\#(Fixtures.detailJSON)]}"#))
        let repository = repository(transport)

        let random = try await repository.randomMeal()
        let opened = try await repository.meal(id: random.id)

        #expect(opened == random)
        #expect(transport.requestedURLs.count == 1)
    }

    @Test func corruptCacheEntriesAreDropped() async throws {
        store.set(Data("not json".utf8), forKey: "meals_cache_categories")

        let cached = MealsCache(store: store).read([MealCategory].self, forKey: "categories", maxAge: nil)

        #expect(cached == nil)
        #expect(store.data(forKey: "meals_cache_categories") == nil)
    }
}
