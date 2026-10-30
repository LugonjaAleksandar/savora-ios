import SwiftUI

struct SettingsRoute: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.localizer) private var l10n

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(l10n("settings_title"))
                    .font(.display(38))
                    .padding(.top, Spacing.md)

                SettingsGroup(title: l10n("settings_theme"), systemImage: "paintpalette.fill") {
                    SlidingSelector(items: AppTheme.allCases, selection: themeBinding) { theme, isSelected in
                        OptionLabel(title: title(for: theme), isSelected: isSelected)
                    }
                    .frame(height: 46)
                }

                SettingsGroup(title: l10n("settings_language"), systemImage: "globe") {
                    SlidingSelector(items: AppLanguage.allCases, selection: languageBinding) { language, isSelected in
                        OptionLabel(title: title(for: language), isSelected: isSelected)
                    }
                    .frame(height: 46)
                }

                SettingsGroup(title: l10n("settings_about"), systemImage: "info.circle.fill") {
                    Text(l10n("settings_about_body"))
                        .font(.subheadline)
                        .foregroundStyle(Palette.textSecondary)
                        .lineSpacing(3)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.tabBarClearance)
        }
        .background(GlowBackground())
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { settings.theme }, set: { settings.setTheme($0) })
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { settings.language }, set: { settings.setLanguage($0) })
    }

    private func title(for theme: AppTheme) -> String {
        switch theme {
        case .system: l10n("settings_theme_system")
        case .light: l10n("settings_theme_light")
        case .dark: l10n("settings_theme_dark")
        }
    }

    /// Language names stay in their own language, so they are findable whatever the current one is.
    private func title(for language: AppLanguage) -> String {
        switch language {
        case .system: l10n("settings_language_system")
        case .english: "English"
        case .serbian: "Srpski"
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
            content()
        }
        .padding(Spacing.md + 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).strokeBorder(Palette.stroke))
    }
}

private struct OptionLabel: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(isSelected ? .white : Palette.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
