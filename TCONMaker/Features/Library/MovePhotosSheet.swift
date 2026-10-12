import SwiftUI

struct MovePhotosSheet: View {
  @EnvironmentObject private var store: PhotoStore
  @Environment(\.dismiss) private var dismiss
  let ids: Set<Int>
  let currentFolderID: UUID?
  let onMoved: () -> Void
  @State private var creating = false
  var body: some View {
    NavigationStack {
      List {
        Section("선택한 \(ids.count)장을 옮길 폴더") {
          destination(nil, "미분류")
          ForEach(store.library.folders) { folder in destination(folder.id, folder.name) }
        }
      }
      .navigationTitle("폴더로 이동").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            creating = true
          } label: {
            Image(systemName: "folder.badge.plus")
          }
          .accessibilityLabel("새 폴더").accessibilityIdentifier("newMoveFolder")
        }
      }
      .disabled(store.busy)
      .sheet(isPresented: $creating) { FolderNameSheet() }
    }
  }
  private func destination(_ id: UUID?, _ name: String) -> some View {
    Button {
      Task {
        if await store.movePhotos(ids, to: id) {
          onMoved()
          dismiss()
        }
      }
    } label: {
      HStack {
        Image(systemName: id == nil ? "tray" : "folder").foregroundStyle(Color.seolin)
        Text(name).foregroundStyle(.primary)
        Spacer()
        if id == currentFolderID { Text("현재 폴더").font(.caption).foregroundStyle(.secondary) }
      }.padding(.vertical, 8).contentShape(Rectangle())
    }.buttonStyle(.plain).disabled(id == currentFolderID)
      .accessibilityIdentifier("moveTo-\(name)")
  }
}
