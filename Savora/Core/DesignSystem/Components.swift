import SwiftUI

/// Soft warm glows behind every tab, matching the Flutter `GlowBackground`.
struct GlowBackground: View {
    var body: some View {
        ZStack {
            Palette.background
            Circle()
                .fill(Palette.glowWarm)
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -150, y: -320)
            Circle()
                .fill(Palette.glowCool)
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 170, y: 120)
        }
        .ignoresSafeArea()
    }
}

/// Scales content down slightly while pressed, used by every tappable card.
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GradientButton: View {
    let title: String
    let systemImage: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .controlSize(.small)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.md + 2)
            .padding(.vertical, 12)
            .background(Palette.brandGradient, in: Capsule())
            .shadow(color: Palette.primary.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading)
    }
}

struct RatingStars: View {
    let rating: Int
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 2) {
            ForEach(MealReview.ratingRange, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Palette.star : Palette.textTertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(rating)/5"))
    }
}

struct StateMessageView: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(Palette.brandGradient, in: Circle())
            Text(title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                GradientButton(title: actionTitle, systemImage: "arrow.clockwise", action: action)
                    .padding(.top, Spacing.sm)
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

/// `AsyncImage` with a warm placeholder and a short fade-in. Responses are
/// kept by the shared `URLCache` configured at launch.
struct RemoteImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            case .failure:
                Palette.surfaceRaised
                    .overlay(Image(systemName: "fork.knife").foregroundStyle(Palette.textTertiary))
            case .empty:
                Palette.surfaceRaised.shimmering()
            @unknown default:
                Palette.surfaceRaised
            }
        }
    }
}

extension View {
    /// Sweeping highlight used for skeletons and image placeholders.
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                }
                .clipped()
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

/// Wraps children onto new lines, used for the meta chips on the detail screen.
struct FlowLayout: Layout {
    var spacing: CGFloat = Spacing.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.indices.isEmpty, current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width += (current.indices.isEmpty ? 0 : spacing) + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}
