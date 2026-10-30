import Foundation

struct MealReview: Codable, Hashable, Sendable {
    static let ratingRange = 1...5

    let mealID: String
    let rating: Int
    let comment: String
    let updatedAt: Date

    init(mealID: String, rating: Int, comment: String, updatedAt: Date) {
        precondition(Self.ratingRange.contains(rating), "Rating must be between 1 and 5")
        self.mealID = mealID
        self.rating = rating
        self.comment = comment
        self.updatedAt = updatedAt
    }
}

protocol ReviewsRepository: Sendable {
    func review(forMealID mealID: String) -> MealReview?
    func save(_ review: MealReview)
    func deleteReview(forMealID mealID: String)
}

/// Reviews live on-device only. Swapping this for a remote implementation
/// would not touch the view model or the UI.
struct LocalReviewsRepository: ReviewsRepository {
    private static let keyPrefix = "review_"

    private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    func review(forMealID mealID: String) -> MealReview? {
        store.value(MealReview.self, forKey: Self.keyPrefix + mealID)
    }

    func save(_ review: MealReview) {
        store.setValue(review, forKey: Self.keyPrefix + review.mealID)
    }

    func deleteReview(forMealID mealID: String) {
        store.removeValue(forKey: Self.keyPrefix + mealID)
    }
}
