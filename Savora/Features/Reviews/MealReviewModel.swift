import Foundation
import Observation

/// Owns the review of one meal for the lifetime of its detail screen.
@MainActor
@Observable
final class MealReviewModel {
    private(set) var review: MealReview?

    @ObservationIgnored private let mealID: String
    @ObservationIgnored private let repository: any ReviewsRepository
    @ObservationIgnored private let now: () -> Date

    init(mealID: String, repository: any ReviewsRepository, now: @escaping () -> Date = Date.init) {
        self.mealID = mealID
        self.repository = repository
        self.now = now
        review = repository.review(forMealID: mealID)
    }

    func save(rating: Int, comment: String) {
        let review = MealReview(mealID: mealID, rating: rating, comment: comment.trimmingCharacters(in: .whitespacesAndNewlines), updatedAt: now())
        repository.save(review)
        self.review = review
    }

    func delete() {
        repository.deleteReview(forMealID: mealID)
        review = nil
    }
}
