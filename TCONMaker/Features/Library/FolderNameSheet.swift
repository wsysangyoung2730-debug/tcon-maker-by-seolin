import SwiftUI

struct FolderNameSheet: View {
  @EnvironmentObject private var store: PhotoStore
  @Environment(\.dismiss) private var dismiss
  var folder: PhotoFolder?
  var onCreated: ((UUID) -> Void)?
  @State private var name = ""
  @State private var problem: String?
  @State private var saving = false
  @FocusState private var focused: Bool
  var body: some View {
    NavigationStack {
      Form {
        Section("폴더 이름") {
          TextField("예: 10월 승급 심사", text: $name).focused($focused)
            .submitLabel(.done).onSubmit { save() }.accessibilityIdentifier("folderName")
          Text("최대 40자 · 같은 이름의 폴더는 만들 수 없어요")
            .font(.caption).foregroundStyle(.secondary)
          if let problem { Text(problem).font(.caption).foregroundStyle(.red) }
        }
      }
      .navigationTitle(folder == nil ? "새 폴더" : "이름 변경")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() }.disabled(saving) }
        ToolbarItem(placement: .confirmationAction) {
          Button(folder == nil ? "만들기" : "완료") { save() }
            .fontWeight(.semibold).disabled(
              saving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
            .accessibilityIdentifier("saveFolder")
        }
      }
      .onAppear {
        name = folder?.name ?? ""
        focused = true
      }
      .interactiveDismissDisabled(saving)
    }.presentationDetents([.medium])
  }
  private func save() {
    guard !saving else { return }
    saving = true
    Task {
      do {
        if let folder {
          try await store.renameFolder(folder.id, to: name)
        } else {
          let id = try await store.createFolder(name)
          onCreated?(id)
        }
        dismiss()
      } catch { problem = (error as? AppFailure)?.message ?? "폴더를 저장하지 못했어요. 기기 저장 공간을 확인해 주세요." }
      saving = false
    }
  }
}
