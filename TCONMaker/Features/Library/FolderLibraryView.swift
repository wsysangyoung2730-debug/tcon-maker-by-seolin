import SwiftUI

struct FolderLibraryView: View {
  @EnvironmentObject private var store: PhotoStore
  @State private var selecting = false
  @State private var selection = Set<UUID>()
  @State private var naming = false
  @State private var renameTarget: PhotoFolder?
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("작업 사진을 폴더별로 정리하세요")
          .font(.subheadline).foregroundStyle(.secondary)
        LibraryRecoveryNotice()
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 145, maximum: 300), spacing: 14)], spacing: 14
        ) {
          folderCard(id: nil, name: "미분류")
            .disabled(selecting).opacity(selecting ? 0.45 : 1)
          ForEach(store.library.folders) { folder in folderCard(id: folder.id, name: folder.name) }
        }
        if store.library.folders.isEmpty {
          Label("+ 버튼으로 심사일이나 수련반 폴더를 만들어 보세요", systemImage: "folder.badge.plus")
            .font(.subheadline).foregroundStyle(.secondary).padding(.top, 10)
        }
        Text("홈에서 추가한 사진은 미분류에 보관돼요.\n폴더 안에서 추가하면 해당 폴더에 바로 보관됩니다.")
          .font(.caption).foregroundStyle(.secondary)
      }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
    }.background(Color.appBackground)
      .navigationTitle("파일").navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button(selecting ? "취소" : "선택") {
            selecting.toggle()
            selection = []
          }
          .accessibilityIdentifier("selectFolders").disabled(store.library.folders.isEmpty)
          Button {
            renameTarget = nil
            naming = true
          } label: {
            Image(systemName: "plus")
          }
          .accessibilityLabel("새 폴더").accessibilityIdentifier("newFolder")
        }
      }
      .disabled(!store.ready || store.busy)
      .safeAreaInset(edge: .bottom) {
        if selecting {
          VStack(spacing: 12) {
            HStack {
              Text("폴더 \(selection.count)개 선택").font(.subheadline.weight(.semibold))
              Spacer()
              Button("이름 변경") {
                renameTarget = store.library.folders.first { selection.contains($0.id) }
                naming = true
              }.disabled(selection.count != 1).accessibilityIdentifier("renameFolder")
            }
            DestructiveOutlineButton(
              title: "선택한 \(selection.count)개 폴더 삭제", disabled: selection.isEmpty
            ) {
              let ids = selection
              Task {
                await store.deleteFolders(ids)
                selection = []
                selecting = false
              }
            }
            .accessibilityIdentifier("deleteFolders")
            Text("폴더 안의 사진은 미분류로 옮겨집니다").font(.caption).foregroundStyle(.secondary)
          }.padding(20).background(.regularMaterial)
        }
      }
      .sheet(isPresented: $naming) { FolderNameSheet(folder: renameTarget) }

  }
  private func folderCard(id: UUID?, name: String) -> some View {
    Button {
      if selecting, let id {
        if selection.contains(id) { selection.remove(id) } else { selection.insert(id) }
      } else {
        store.path.append(.folder(id))
      }
    } label: {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Image(systemName: id == nil ? "tray.full.fill" : "folder.fill")
            .font(.system(size: 38)).foregroundStyle(Color.seolin)
          Spacer()
          if selecting, let id {
            Image(systemName: selection.contains(id) ? "checkmark.circle.fill" : "circle")
              .font(.title2).foregroundStyle(Color.seolin)
          }
        }
        VStack(alignment: .leading, spacing: 5) {
          Text(name).font(.headline).foregroundStyle(.primary).lineLimit(2)
          Text("사진 \(store.savedCount(in: id))장").font(.subheadline).foregroundStyle(.secondary)
        }
      }.padding(20).frame(maxWidth: .infinity, minHeight: 145, alignment: .leading)
        .background(Color.panel, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
          RoundedRectangle(cornerRadius: 18).stroke(
            id.map(selection.contains) == true ? Color.seolin : Color.secondary.opacity(0.12),
            lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }.buttonStyle(.plain).accessibilityIdentifier(id == nil ? "folder-unfiled" : "folder-\(name)")
      .accessibilityValue(
        selecting && id.map(selection.contains) == true ? "선택됨" : "사진 \(store.savedCount(in: id))장")
  }
}

struct LibraryRecoveryNotice: View {
  @EnvironmentObject private var store: PhotoStore
  var body: some View {
    if store.missingCount > 0 {
      VStack(alignment: .leading, spacing: 8) {
        Label(
          "\(store.missingCount)장을 불러오지 못했어요. 저장 파일은 보관되어 있습니다.",
          systemImage: "exclamationmark.triangle")
        Button("사진 다시 불러오기") { Task { await store.retryRestore() } }
      }.font(.subheadline).padding(16).background(
        Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
    if store.saveFailed {
      VStack(alignment: .leading, spacing: 8) {
        Text("아직 기기에 보관하지 못한 편집이 있어요")
        Button("변경사항 다시 보관하기") { Task { await store.retrySave() } }
      }.font(.subheadline).padding(16).background(
        Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
  }
}
