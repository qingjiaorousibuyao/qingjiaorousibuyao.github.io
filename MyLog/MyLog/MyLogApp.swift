import SwiftUI
import SwiftData

@main
struct MyLogApp: App {
    @StateObject private var theme = ThemeSettings()
    @StateObject private var profile = ProfileSettings()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DiaryPost.self, Contact.self, ChatMessage.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            LaunchContainerView()
                .environmentObject(theme)
                .environmentObject(profile)
        }
            .modelContainer(sharedModelContainer)
    }
}
