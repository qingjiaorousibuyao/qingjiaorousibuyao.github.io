import SwiftUI

struct EmptyStateView: View {
    let icon: String; let title: String; let message: String
    var body: some View { ContentUnavailableView(title, systemImage: icon, description: Text(message)).frame(maxWidth: .infinity, minHeight: 260) }
}
