import PhotosUI
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var profile: LocalProfileStore
    @State private var avatarItem: PhotosPickerItem?
    @State private var editingName = false

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 16) {
                PhotosPicker(selection: $avatarItem, matching: .images) {
                    AvatarView(image: profile.avatar, size: 84)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill").font(.caption).padding(7).foregroundStyle(.white).background(AppPalette.accent, in: Circle())
                        }
                }
                Text(profile.name).font(.title2.bold())
                Button("编辑昵称") { editingName = true }.buttonStyle(.bordered)
            }
            .padding(28)
            .softCard()
            .padding(20)
        }
        .navigationTitle("我的")
        .onChange(of: avatarItem) { _, item in Task { if let data = try? await item?.loadTransferable(type: Data.self) { profile.setAvatar(data) } } }
        .sheet(isPresented: $editingName) { NameEditor() }
    }
}

private struct NameEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profile: LocalProfileStore
    @State private var name = ""
    var body: some View {
        NavigationStack {
            Form { TextField("昵称", text: $name) }
                .navigationTitle("编辑昵称")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("保存") { profile.name = name.nonBlank ?? "我"; dismiss() } }
                }
                .onAppear { name = profile.name }
        }
    }
}
