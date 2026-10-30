import Foundation

struct Ingredient: Hashable, Sendable {
    let name: String
    let measure: String

    var imageURL: URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return URL(string: "https://www.themealdb.com/images/ingredients/\(encoded)-small.png")
    }
}

struct MealDetail: Hashable, Identifiable, Sendable {
    /// TheMealDB flattens ingredients into `strIngredient1...20` / `strMeasure1...20`.
    static let maxIngredients = 20

    let id: String
    let name: String
    let thumbnailURL: URL
    let category: String?
    let area: String?
    let instructions: String
    let ingredients: [Ingredient]
    let tags: [String]
    let youtubeURL: URL?
    let sourceURL: URL?

    var summary: MealSummary {
        MealSummary(id: id, name: name, thumbnailURL: thumbnailURL)
    }

    /// Instructions split into readable steps, dropping the "STEP 1" style
    /// heading lines some recipes include.
    var steps: [String] {
        instructions
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.wholeMatch(of: /(?i)(step\s*\d+|\d+\.?)/) == nil }
    }

    var hasVideo: Bool {
        youtubeURL?.host() != nil
    }

    var hasSource: Bool {
        sourceURL?.host() != nil
    }
}

/// Coded in TheMealDB's own flat shape, so the cache can store and restore it
/// with the same decoder the network uses.
extension MealDetail: Codable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FlatKey.self)

        func text(_ key: String) -> String? {
            let value = (try? container.decodeIfPresent(String.self, forKey: FlatKey(key)))?.trimmingCharacters(in: .whitespacesAndNewlines)
            return value?.isEmpty == false ? value : nil
        }

        guard let id = text("idMeal"), let name = text("strMeal"), let thumbnail = text("strMealThumb").flatMap(URL.init(string:)) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Meal is missing id, name or thumbnail"))
        }

        self.id = id
        self.name = name
        thumbnailURL = thumbnail
        category = text("strCategory")
        area = text("strArea")
        instructions = text("strInstructions") ?? ""
        ingredients = (1...Self.maxIngredients).compactMap { index in
            text("strIngredient\(index)").map { Ingredient(name: $0, measure: text("strMeasure\(index)") ?? "") }
        }
        tags = (text("strTags") ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        youtubeURL = text("strYoutube").flatMap(URL.init(string:))
        sourceURL = text("strSource").flatMap(URL.init(string:))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: FlatKey.self)
        try container.encode(id, forKey: FlatKey("idMeal"))
        try container.encode(name, forKey: FlatKey("strMeal"))
        try container.encode(thumbnailURL.absoluteString, forKey: FlatKey("strMealThumb"))
        try container.encodeIfPresent(category, forKey: FlatKey("strCategory"))
        try container.encodeIfPresent(area, forKey: FlatKey("strArea"))
        try container.encode(instructions, forKey: FlatKey("strInstructions"))
        for (offset, ingredient) in ingredients.enumerated() {
            try container.encode(ingredient.name, forKey: FlatKey("strIngredient\(offset + 1)"))
            try container.encode(ingredient.measure, forKey: FlatKey("strMeasure\(offset + 1)"))
        }
        try container.encode(tags.joined(separator: ","), forKey: FlatKey("strTags"))
        try container.encodeIfPresent(youtubeURL?.absoluteString, forKey: FlatKey("strYoutube"))
        try container.encodeIfPresent(sourceURL?.absoluteString, forKey: FlatKey("strSource"))
    }
}

private struct FlatKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        nil
    }
}
