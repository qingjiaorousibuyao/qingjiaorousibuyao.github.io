import SwiftData
import SwiftUI

@main
struct EunoiaApp: App {
    private let container: ModelContainer = {
        let schema = Schema([Contact.self, ChatMessage.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("无法创建本地数据库：\(error.localizedDescription)") }
    }()

    var body: some Scene {
        WindowGroup { RootTabView() }
            .modelContainer(container)
    }
}
