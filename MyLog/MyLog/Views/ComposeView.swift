import SwiftUI
import SwiftData
import PhotosUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var text: String
    @State private var selection: [PhotosPickerItem] = []
    @State private var photos: [Data]
    let parentID: UUID?
    let editingPost: DiaryPost?

    init(parentID: UUID? = nil, editingPost: DiaryPost? = nil) {
        self.parentID = parentID
        self.editingPost = editingPost
        _text = State(initialValue: editingPost?.text ?? "")
        _photos = State(initialValue: editingPost?.photos ?? [])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextEditor(text: $text)
                        .font(.body)
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty { Text("现在在想什么？").foregroundStyle(.secondary).padding(.top, 8).allowsHitTesting(false) }
                        }
                    if !photos.isEmpty {
                        EditablePhotoGrid(data: $photos)
                    }
                    HStack {
                        if photos.count < 9 {
                            PhotosPicker(selection: $selection, maxSelectionCount: 9 - photos.count, matching: .images) {
                                Label("添加照片", systemImage: "photo.badge.plus")
                            }
                        }
                        if !photos.isEmpty {
                            Button("重新选择") { photos.removeAll(); selection.removeAll() }
                        }
                        Spacer()
                        Text("\(photos.count)/9").foregroundStyle(.secondary).font(.caption)
                        Text("\(text.count)").foregroundStyle(.secondary).font(.caption)
                    }
                }
                .padding()
            }
            .navigationTitle(editingPost != nil ? "编辑记录" : parentID == nil ? "新记录" : "回复自己")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let editingPost {
                            editingPost.text = cleanText
                            editingPost.photos = photos
                        } else {
                            context.insert(DiaryPost(text: cleanText, photos: photos, parentID: parentID))
                        }
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photos.isEmpty)
                }
            }
            .onChange(of: selection) { _, items in
                guard !items.isEmpty else { return }
                Task {
                    let additions = await items.asyncCompactMap { try? await $0.loadTransferable(type: Data.self) }
                    photos = Array((photos + additions).prefix(9))
                    selection.removeAll()
                }
            }
        }
    }
}

private struct EditablePhotoGrid: View {
    @Binding var data: [Data]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                ZStack(alignment: .topTrailing) {
                    if let image = UIImage(data: item) {
                        Image(uiImage: image).resizable().scaledToFill()
                            .frame(height: 105).frame(maxWidth: .infinity).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button { data.remove(at: index) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3).symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.65))
                            .padding(5)
                    }
                    .accessibilityLabel("删除第\(index + 1)张照片")
                }
            }
        }
    }
}

private extension Array where Element == PhotosPickerItem {
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var values: [T] = []
        for item in self { if let value = await transform(item) { values.append(value) } }
        return values
    }
}
