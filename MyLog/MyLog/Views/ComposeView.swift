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
            VStack(alignment: .leading, spacing: 14) {
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty { Text("现在在想什么？").foregroundStyle(.secondary).padding(.top, 8).allowsHitTesting(false) }
                    }
                if !photos.isEmpty { PhotoGrid(data: photos).frame(maxHeight: 290) }
                HStack {
                    PhotosPicker(selection: $selection, maxSelectionCount: 4, matching: .images) {
                        Label("照片", systemImage: "photo")
                    }
                    Spacer()
                    Text("\(text.count)").foregroundStyle(.secondary).font(.caption)
                }
            }
            .padding()
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
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && photos.isEmpty)
                }
            }
            .onChange(of: selection) { _, items in
                Task { photos = await items.asyncCompactMap { try? await $0.loadTransferable(type: Data.self) } }
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
