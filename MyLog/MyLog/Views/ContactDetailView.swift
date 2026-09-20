import SwiftUI

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var contact: Contact
    @State private var isEditing = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(spacing: 16) {
                    profileHeader
                    VStack(spacing: 16) {
                        details
                        placeholder
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 28)
            }
            .ignoresSafeArea(edges: .top)

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.bold())
                            .frame(width: 42, height: 42)
                            .background(.regularMaterial, in: Circle())
                    }
                    .accessibilityLabel("返回")
                    Spacer()
                }
                Spacer()
            }
            .safeAreaPadding(.top)
            .safeAreaPadding(.horizontal, 14)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isEditing) { ContactEditorView(contact: contact) }
    }

    private var profileHeader: some View {
        VStack(spacing: 0) {
            Group {
                if let data = PersistentSettingsStore.loadImage(filename: contact.coverImageFilename),
                   let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    LinearGradient(
                        colors: [MyLogTheme.palePurple, MyLogTheme.pink.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(height: 240)
            .clipped()

            VStack(spacing: 8) {
                ContactAvatar(filename: contact.avatarFilename, size: 92)
                    .offset(y: -46)
                    .padding(.bottom, -46)
                Text(contact.name).font(.title2.bold())
                if let bio = contact.bio?.nilIfBlank {
                    Text(bio).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                HStack(spacing: 12) {
                    NavigationLink { ContactChatView(contact: contact) } label: {
                        Label("聊天", systemImage: "bubble.left")
                    }
                    .buttonStyle(.borderedProminent)
                    Button("编辑资料") { isEditing = true }.buttonStyle(.bordered)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 18)
        }
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 24,
            bottomTrailingRadius: 24,
            topTrailingRadius: 0,
            style: .continuous
        ))
        .softCard()
    }

    @ViewBuilder private var details: some View {
        if contact.gender != nil || contact.birthday != nil || contact.hometown != nil {
            VStack(alignment: .leading, spacing: 12) {
                Text("资料").font(.headline)
                if let gender = contact.gender?.nilIfBlank { detailRow("性别", gender) }
                if let birthday = contact.birthday {
                    detailRow("生日", birthday.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh_CN"))))
                }
                if let hometown = contact.hometown?.nilIfBlank { detailRow("籍贯", hometown) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard()
        }
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            HStack {
                Text("动态 / 回忆").font(.headline)
                Spacer()
                Text("即将推出").font(.caption).foregroundStyle(.secondary)
            }
            ContentUnavailableView("这里以后会保存共同回忆", systemImage: "sparkles")
                .frame(minHeight: 150)
        }
        .padding(16)
        .softCard()
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.secondary).frame(width: 52, alignment: .leading)
            Text(value)
            Spacer()
        }
        .font(.subheadline)
    }
}
