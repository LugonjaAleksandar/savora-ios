import Foundation

/// Lightweight meal used by lists, favorites and as the zoom-transition
/// placeholder while `MealDetail` loads.
struct MealSummary: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let thumbnailURL: URL

    /// TheMealDB serves resized variants at `/medium`, several times lighter for grids.
    var previewURL: URL {
        thumbnailURL.appending(path: "medium")
    }

    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case thumbnailURL = "strMealThumb"
    }
}
