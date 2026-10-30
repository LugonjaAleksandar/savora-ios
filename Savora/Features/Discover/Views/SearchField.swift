import SwiftUI

struct SearchField: View {
    @Binding var text: String
    let placeholder: String

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm + 4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.primary)
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.textTertiary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .font(.body.weight(.medium))
        .padding(.horizontal, Spacing.md + 4)
        .frame(height: 56)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(isFocused ? Palette.primary.opacity(0.6) : Palette.stroke, lineWidth: 1.5))
        .shadow(color: Palette.shadow, radius: 14, y: 6)
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .animation(.easeOut(duration: 0.2), value: text.isEmpty)
    }
}
