import SwiftData
import SwiftUI

struct ContactGroupListView: View {
    let title: String; let filter: ContactFilter
    @Query(sort: \Contact.createdAt, order: .reverse) private var contacts: [Contact]
    private var data: [Contact] { contacts.filter { contact in switch filter { case .all: true; case .favorite: contact.isFavorite; case let .group(group): contact.group == group } } }
    var body: some View { List(data) { contact in NavigationLink { ContactProfileView(contact: contact) } label: { HStack { ContactAvatar(path: contact.avatarPath, size: 48); Text(contact.nickname) } } }.navigationTitle(title).overlay { if data.isEmpty { EmptyStateView(icon: "person.2.slash", title: "这里还没有联系人", message: "创建或调整联系人后会显示在这里。") } }.hidesEunoiaTabBar() }
}
