import SwiftUI

@main
struct SavoraApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
