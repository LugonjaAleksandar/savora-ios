import Foundation
import SwiftUI

/// Resolves copy from `Localizable.xcstrings` for the language picked in
/// Settings, independent of the device language. Plural rules (Serbian has
/// one/few/other) come from the catalog and are applied with `locale`.
struct Localizer: Sendable {
    let locale: Locale

    private let languageCode: String?

    init(language: AppLanguage) {
        switch language {
        case .system:
            languageCode = nil
            locale = .autoupdatingCurrent
        case .english, .serbian:
            languageCode = language.rawValue
            locale = Locale(identifier: language.rawValue)
        }
    }

    func callAsFunction(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    func callAsFunction(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: self(key), locale: locale, arguments: arguments)
    }

    func message(for failure: AppFailure) -> String {
        switch failure {
        case .network: self("error_network")
        case .server: self("error_server")
        case .notFound: self("error_not_found")
        case .parsing, .unknown: self("error_unknown")
        }
    }

    func ratingLabel(_ rating: Int) -> String {
        self("review_rating_label_\(rating)")
    }

    func date(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.abbreviated).day().locale(formattingLocale))
    }

    /// The Serbian copy is Latin script, but `sr` alone formats dates in Cyrillic.
    private var formattingLocale: Locale {
        locale.language.languageCode?.identifier == "sr" ? Locale(identifier: "sr-Latn") : locale
    }

    private var bundle: Bundle {
        guard let languageCode, let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"), let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

extension EnvironmentValues {
    @Entry var localizer = Localizer(language: .english)
}
