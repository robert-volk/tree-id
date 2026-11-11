import SwiftUI
import SwiftData

@main
struct TreeIDApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .tint(Theme.green)
        }
        .modelContainer(for: Entry.self)
    }
}
