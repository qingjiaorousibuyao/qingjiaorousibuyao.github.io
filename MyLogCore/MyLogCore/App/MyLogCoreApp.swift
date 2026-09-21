import SwiftData
import SwiftUI

@main
struct MyLogCoreApp: App {
    @StateObject private var profile = LocalProfileStore()

    private let container: ModelContainer = {
        let schema = Schema([Contact.self, ChatMessage.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(profile)
        }
        .modelContainer(container)
    }
}
