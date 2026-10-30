import Foundation
import Testing
@testable import Savora

struct APIClientTests {
    private func client(_ transport: StubTransport) -> APIClient {
        APIClient(transport: transport, baseURL: AppContainer.mealDBBaseURL)
    }

    @Test func buildsURLWithPathAndQuery() async throws {
        let transport = StubTransport(.json(Fixtures.listingJSON))

        _ = try await MealsRemoteDataSource(apiClient: client(transport)).fetchMeals(inCategory: "Sea food")

        #expect(transport.requestedURLs.first?.absoluteString == "https://www.themealdb.com/api/json/v1/1/filter.php?c=Sea%20food")
    }

    @Test(arguments: [
        (StubTransport.Reply.json("{}", status: 404), AppFailure.notFound),
        (.json("{}", status: 503), .server(statusCode: 503)),
        (.json("<html>", status: 200), .parsing),
        (.failure(.notConnectedToInternet), .network),
        (.failure(.timedOut), .network),
    ])
    func mapsFailures(reply: StubTransport.Reply, expected: AppFailure) async {
        await #expect(throws: expected) {
            try await client(StubTransport(reply)).get("categories.php", as: [String: String].self)
        }
    }

    @Test func treatsNullMealsAsEmptyList() async throws {
        let meals = try await MealsRemoteDataSource(apiClient: client(StubTransport(.json(#"{"meals": null}"#)))).searchMeals("zzz")

        #expect(meals.isEmpty)
    }

    @Test func lookupOfUnknownMealIsNotFound() async {
        await #expect(throws: AppFailure.notFound) {
            try await MealsRemoteDataSource(apiClient: client(StubTransport(.json(#"{"meals": null}"#)))).fetchMeal(id: "0")
        }
    }
}
