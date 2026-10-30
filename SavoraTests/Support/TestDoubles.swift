import Foundation
import Synchronization
@testable import Savora

/// Replays canned responses and records every request it was asked for.
final class StubTransport: HTTPTransport {
    enum Reply: Sendable {
        case json(String, status: Int = 200)
        case failure(URLError.Code)
    }

    private let replies: Mutex<[Reply]>
    private let recorded = Mutex<[URL]>([])

    init(_ replies: Reply...) {
        self.replies = Mutex(replies)
    }

    var requestedURLs: [URL] {
        recorded.withLock { $0 }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let url = request.url!
        recorded.withLock { $0.append(url) }
        let reply = replies.withLock { $0.isEmpty ? Reply.failure(.notConnectedToInternet) : $0.removeFirst() }
        switch reply {
        case .json(let body, let status):
            return (Data(body.utf8), HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!)
        case .failure(let code):
            throw URLError(code)
        }
    }
}

/// Mutable clock for TTL tests.
final class TestClock: Sendable {
    private let current: Mutex<Date>

    init(_ date: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        current = Mutex(date)
    }

    var now: Date {
        current.withLock { $0 }
    }

    func advance(by duration: Duration) {
        current.withLock { $0 = $0.addingTimeInterval(TimeInterval(duration.components.seconds)) }
    }
}

actor FakeMealsRepository: MealsRepository {
    var categoriesResult: Result<[MealCategory], AppFailure> = .success(Fixtures.categories)
    var mealsResult: Result<[MealSummary], AppFailure> = .success([Fixtures.summary])
    var randomResult: Result<MealDetail, AppFailure> = .success(Fixtures.detail)
    private(set) var requestedCategories: [String] = []
    private(set) var searchedQueries: [String] = []

    func setCategoriesResult(_ result: Result<[MealCategory], AppFailure>) {
        categoriesResult = result
    }

    func categories(forceRefresh: Bool) async throws(AppFailure) -> [MealCategory] {
        try categoriesResult.get()
    }

    func meals(inCategory category: String) async throws(AppFailure) -> [MealSummary] {
        requestedCategories.append(category)
        return try mealsResult.get()
    }

    func searchMeals(_ query: String) async throws(AppFailure) -> [MealSummary] {
        searchedQueries.append(query)
        return try mealsResult.get()
    }

    func meal(id: String) async throws(AppFailure) -> MealDetail {
        try randomResult.get()
    }

    func randomMeal() async throws(AppFailure) -> MealDetail {
        try randomResult.get()
    }
}

enum Fixtures {
    static let summary = MealSummary(id: "52772", name: "Teriyaki Chicken Casserole", thumbnailURL: URL(string: "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg")!)

    static let categories = [
        MealCategory(id: "1", name: "Beef", thumbnailURL: URL(string: "https://www.themealdb.com/images/category/beef.png")!, description: ""),
        MealCategory(id: "2", name: "Chicken", thumbnailURL: URL(string: "https://www.themealdb.com/images/category/chicken.png")!, description: ""),
    ]

    static let detail = try! JSONDecoder().decode(MealDetail.self, from: Data(detailJSON.utf8))

    static let detailJSON = """
    {
      "idMeal": "52772",
      "strMeal": "  Teriyaki Chicken Casserole ",
      "strMealThumb": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",
      "strCategory": "Chicken",
      "strArea": "",
      "strInstructions": "STEP 1\\r\\nPreheat oven to 350F.\\r\\n\\r\\n2.\\r\\nCombine soy sauce and water.",
      "strTags": "Meat, Casserole,",
      "strYoutube": "https://www.youtube.com/watch?v=4aZr5hZXP_s",
      "strSource": " ",
      "strIngredient1": "soy sauce",
      "strMeasure1": "3/4 cup",
      "strIngredient2": "water",
      "strMeasure2": null,
      "strIngredient3": "",
      "strMeasure3": ""
    }
    """

    static let categoriesJSON = """
    {"categories": [{"idCategory": "1", "strCategory": "Beef", "strCategoryThumb": "https://www.themealdb.com/images/category/beef.png", "strCategoryDescription": "Beef is the culinary name for meat from cattle."}]}
    """

    static let listingJSON = """
    {"meals": [{"idMeal": "52772", "strMeal": "Teriyaki Chicken Casserole", "strMealThumb": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg"}]}
    """
}
