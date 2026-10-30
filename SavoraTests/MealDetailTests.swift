import Foundation
import Testing
@testable import Savora

struct MealDetailTests {
    private let meal = Fixtures.detail

    @Test func parsesFlattenedIngredientsAndSkipsBlanks() {
        #expect(meal.ingredients == [Ingredient(name: "soy sauce", measure: "3/4 cup"), Ingredient(name: "water", measure: "")])
    }

    @Test func splitsInstructionsIntoStepsWithoutHeadings() {
        #expect(meal.steps == ["Preheat oven to 350F.", "Combine soy sauce and water."])
    }

    @Test func normalisesBlankFieldsAndTags() {
        #expect(meal.name == "Teriyaki Chicken Casserole")
        #expect(meal.area == nil)
        #expect(meal.tags == ["Meat", "Casserole"])
        #expect(meal.hasVideo)
        #expect(!meal.hasSource)
    }

    @Test func survivesACacheRoundTrip() throws {
        let restored = try JSONDecoder().decode(MealDetail.self, from: JSONEncoder().encode(meal))

        #expect(restored == meal)
    }
}
