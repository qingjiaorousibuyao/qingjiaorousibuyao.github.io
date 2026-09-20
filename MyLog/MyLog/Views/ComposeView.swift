import SwiftUI
import SwiftData
import PhotosUI

struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var text = ""
    @State private var selection: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    var parentID: UUID? = nil

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
            .navigationTitle(parentID == nil ? "新记录" : "回复自己")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") {
                        context.insert(DiaryPost(text: text.trimmingCharacters(in: .whitespacesAndNewlines), photos: photos, parentID: parentID))
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

