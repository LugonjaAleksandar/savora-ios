import Foundation
import Observation

@MainActor
@Observable
final class MealDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(MealDetail)
        case failed(AppFailure)
    }

    let preview: MealSummary
    private(set) var state: State = .loading

    @ObservationIgnored private let repository: any MealsRepository

    init(preview: MealSummary, repository: any MealsRepository) {
        self.preview = preview
        self.repository = repository
    }

    /// The loaded meal once available, otherwise the summary the screen was opened with.
    var summary: MealSummary {
        if case .loaded(let meal) = state {
            return meal.summary
        }
        return preview
    }

    func load() async {
        if case .loaded = state {
            return
        }
        state = .loading
        do {
            state = .loaded(try await repository.meal(id: preview.id))
        } catch {
            state = .failed(error)
        }
    }
}
