import Observation
import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case discover
    case favorites
    case settings
}

enum Route: Hashable {
    case meal(MealSummary)
}

/// Navigation state. Only route-level screens call into it; cards and tiles
/// expose `onTap` and leave the decision to their screen.
@MainActor
@Observable
final class Router {
    var path: [Route] = []
    var selectedTab: AppTab = .discover

    func openMeal(_ meal: MealSummary) {
        path.append(.meal(meal))
    }
}

/// Snackbar-style messages with an optional action (used for undo).
@MainActor
@Observable
final class ToastCenter {
    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let actionTitle: String?
        let action: (() -> Void)?
    }

    static let visibleDuration: Duration = .seconds(5)

    private(set) var current: Toast?

    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    func show(_ message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        let toast = Toast(message: message, actionTitle: actionTitle, action: action)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            current = toast
        }
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: Self.visibleDuration)
            guard !Task.isCancelled else {
                return
            }
            self?.dismiss(toast.id)
        }
    }

    func performAction() {
        current?.action?()
        dismiss(current?.id)
    }

    private func dismiss(_ id: UUID?) {
        guard current?.id == id else {
            return
        }
        withAnimation(.easeOut(duration: 0.25)) {
            current = nil
        }
    }
}

extension EnvironmentValues {
    @Entry var zoomNamespace: Namespace.ID?
}

extension View {
    /// Marks the view as the source of the zoom transition into a meal's detail.
    func zoomSource(id: String) -> some View {
        modifier(ZoomSourceModifier(id: id))
    }
}

private struct ZoomSourceModifier: ViewModifier {
    let id: String

    @Environment(\.zoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}
