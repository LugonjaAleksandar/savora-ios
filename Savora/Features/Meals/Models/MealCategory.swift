import Foundation

struct MealCategory: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    let thumbnailURL: URL
    let description: String

    init(id: String, name: String, thumbnailURL: URL, description: String) {
        self.id = id
        self.name = name
        self.thumbnailURL = thumbnailURL
        self.description = description
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        thumbnailURL = try container.decode(URL.self, forKey: .thumbnailURL)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id = "idCategory"
        case name = "strCategory"
        case thumbnailURL = "strCategoryThumb"
        case description = "strCategoryDescription"
    }
}
