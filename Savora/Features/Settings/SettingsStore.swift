import Observation
import SwiftUI

enum AppTheme: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case english = "en"
    case serbian = "sr"
}

protocol SettingsRepository: Sendable {
    var theme: AppTheme { get }
    var language: AppLanguage { get }
    func setTheme(_ theme: AppTheme)
    func setLanguage(_ language: AppLanguage)
}

struct LocalSettingsRepository: SettingsRepository {
    private static let themeKey = "settings_theme"
    private static let languageKey = "settings_language"

    private let store: any KeyValueStore

    init(store: any KeyValueStore) {
        self.store = store
    }

    var theme: AppTheme {
        store.value(String.self, forKey: Self.themeKey).flatMap(AppTheme.init(rawValue:)) ?? .system
    }

    /// First launch is in English; an explicit "System" choice is remembered.
    var language: AppLanguage {
        store.value(String.self, forKey: Self.languageKey).flatMap(AppLanguage.init(rawValue:)) ?? .english
    }

    func setTheme(_ theme: AppTheme) {
        store.setValue(theme.rawValue, forKey: Self.themeKey)
    }

    func setLanguage(_ language: AppLanguage) {
        store.setValue(language.rawValue, forKey: Self.languageKey)
    }
}

@MainActor
@Observable
final class SettingsStore {
    private(set) var theme: AppTheme
    private(set) var language: AppLanguage

    @ObservationIgnored private let repository: any SettingsRepository

    init(repository: any SettingsRepository) {
        self.repository = repository
        theme = repository.theme
        language = repository.language
    }

    var localizer: Localizer {
        Localizer(language: language)
    }

    func setTheme(_ theme: AppTheme) {
        self.theme = theme
        repository.setTheme(theme)
    }

    func setLanguage(_ language: AppLanguage) {
        self.language = language
        repository.setLanguage(language)
    }
}
