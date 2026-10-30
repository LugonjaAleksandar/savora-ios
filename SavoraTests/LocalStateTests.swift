import Foundation
import Testing
@testable import Savora

@MainActor
struct FavoritesStoreTests {
    private let store = InMemoryKeyValueStore()

    @Test func favoritesPersistAcrossLaunches() {
        FavoritesStore(repository: LocalFavoritesRepository(store: store)).toggle(Fixtures.summary)

        let relaunched = FavoritesStore(repository: LocalFavoritesRepository(store: store))

        #expect(relaunched.favorites == [Fixtures.summary])
    }

    @Test func undoRestoresTheOriginalPosition() {
        let favorites = FavoritesStore(repository: LocalFavoritesRepository(store: store))
        let meals = (1...3).map { MealSummary(id: "\($0)", name: "Meal \($0)", thumbnailURL: Fixtures.summary.thumbnailURL) }
        meals.reversed().forEach { favorites.add($0) }

        let index = favorites.remove("2")
        favorites.add(meals[1], at: index ?? 0)

        #expect(favorites.favorites.map(\.id) == ["1", "2", "3"])
    }
}

@MainActor
struct MealReviewModelTests {
    private let store = InMemoryKeyValueStore()

    @Test func savedReviewIsTrimmedAndPersisted() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        MealReviewModel(mealID: "1", repository: LocalReviewsRepository(store: store), now: { date }).save(rating: 4, comment: "  More garlic  ")

        let reopened = MealReviewModel(mealID: "1", repository: LocalReviewsRepository(store: store))

        #expect(reopened.review == MealReview(mealID: "1", rating: 4, comment: "More garlic", updatedAt: date))
    }

    @Test func deleteRemovesTheReview() {
        let model = MealReviewModel(mealID: "1", repository: LocalReviewsRepository(store: store))
        model.save(rating: 5, comment: "")

        model.delete()

        #expect(model.review == nil)
        #expect(LocalReviewsRepository(store: store).review(forMealID: "1") == nil)
    }
}

struct SettingsRepositoryTests {
    private let repository = LocalSettingsRepository(store: InMemoryKeyValueStore())

    @Test func firstLaunchDefaultsToEnglishAndSystemTheme() {
        #expect(repository.language == .english)
        #expect(repository.theme == .system)
    }

    @Test func choosingSystemLanguageIsRemembered() {
        repository.setLanguage(.system)

        #expect(repository.language == .system)
    }
}

struct LocalizerTests {
    @Test(arguments: [(0, "Nema recepata"), (1, "1 recept"), (3, "3 recepta"), (5, "5 recepata"), (21, "21 recept")])
    func serbianPluralsFollowOneFewOther(count: Int, expected: String) {
        #expect(Localizer(language: .serbian)("meals_count", count) == expected)
    }

    @Test func serbianDatesUseLatinScriptLikeTheCopy() {
        let formatted = Localizer(language: .serbian).date(Date(timeIntervalSince1970: 1_793_318_400))

        #expect(formatted.unicodeScalars.allSatisfy { $0.isASCII })
    }

    @Test func englishCopyAndPlurals() {
        let l10n = Localizer(language: .english)

        #expect(l10n("nav_discover") == "Discover")
        #expect(l10n("meals_count", 1) == "1 recipe")
        #expect(l10n("meals_section_category", "Beef") == "Beef recipes")
    }
}
