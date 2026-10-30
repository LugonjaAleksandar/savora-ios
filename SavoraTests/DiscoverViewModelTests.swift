import Foundation
import Testing
@testable import Savora

@MainActor
struct DiscoverViewModelTests {
    private let repository = FakeMealsRepository()

    @Test func startLoadsCategoriesAndTheFirstCategory() async {
        let viewModel = DiscoverViewModel(repository: repository)

        await viewModel.start()

        #expect(viewModel.status == .loaded)
        #expect(viewModel.selectedCategory?.name == "Beef")
        #expect(viewModel.meals == [Fixtures.summary])
        #expect(await repository.requestedCategories == ["Beef"])
    }

    @Test func selectingACategoryLoadsItsMeals() async {
        let viewModel = DiscoverViewModel(repository: repository)
        await viewModel.start()

        await viewModel.select(Fixtures.categories[1]).value

        #expect(viewModel.selectedCategory?.name == "Chicken")
        #expect(await repository.requestedCategories == ["Beef", "Chicken"])
    }

    @Test func searchIsDebouncedSoOnlyTheLastQueryHitsTheRepository() async {
        let viewModel = DiscoverViewModel(repository: repository, searchDebounce: .milliseconds(80))
        await viewModel.start()

        viewModel.searchChanged("c")
        viewModel.searchChanged("ch")
        await viewModel.searchChanged("chicken").value

        #expect(await repository.searchedQueries == ["chicken"])
        #expect(viewModel.isSearching)
    }

    @Test func clearingTheSearchReturnsToTheSelectedCategory() async {
        let viewModel = DiscoverViewModel(repository: repository, searchDebounce: .zero)
        await viewModel.start()
        await viewModel.searchChanged("chicken").value

        await viewModel.searchChanged("").value

        #expect(!viewModel.isSearching)
        #expect(await repository.requestedCategories == ["Beef", "Beef"])
    }

    @Test func failureToLoadCategoriesIsSurfaced() async {
        await repository.setCategoriesResult(.failure(.network))
        let viewModel = DiscoverViewModel(repository: repository)

        await viewModel.start()

        #expect(viewModel.status == .failed(.network))
    }
}
