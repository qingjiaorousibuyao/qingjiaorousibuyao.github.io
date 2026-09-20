import SwiftUI
import SwiftData

@main
struct MyLogApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([DiaryPost.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(sharedModelContainer)
    }
}

