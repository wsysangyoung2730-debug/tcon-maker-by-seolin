import SwiftUI

struct BatchView: View {
  @EnvironmentObject private var store: PhotoStore
  let folderID: UUID?
  @State private var settings = false
  @State private var reviewOnly = false
  @State private var selecting = false
  @State private var selection = Set<Int>()
  @State private var moving = false
  private var folderPhotos: [PhotoItem] { store.photos(in: folderID) }
  private var displayed: [PhotoItem] { folderPhotos.filter { !reviewOnly || $0.needsReview } }
  private var selectedIDs: Set<Int> { selection.intersection(folderPhotos.map(\.id)) }
  private var exportIDs: [Int] {
    folderPhotos.filter { $0.status == "done" && (!selecting || selectedIDs.contains($0.id)) }.map(
      \.id)
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        Text("\(folderPhotos.count)장의 사진").font(.largeTitle.bold())
        Text(selecting ? "저장·이동·삭제할 사진을 선택하세요" : "사진을 눌러 편집하고, 길게 눌러 여러 장을 선택하세요")
          .foregroundStyle(.secondary).font(.subheadline)
        LibraryRecoveryNotice()
        if !folderPhotos.isEmpty {
          Button {
            settings = true
          } label: {
            HStack {
              Text("\(store.settings.presetName) · \(store.settings.dimensions)")
              Spacer()
              Image(systemName: "slider.horizontal.3")
              Text("전체 설정").fontWeight(.semibold)
            }.font(.subheadline).padding(16)
              .background(Color.seolin.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
          }.accessibilityIdentifier("batchSettings")
          Picker("사진 상태", selection: $reviewOnly) {
            Text("전체 \(folderPhotos.count)").tag(false)
            Text("확인 필요 \(folderPhotos.filter(\.needsReview).count)").tag(true)
          }.pickerStyle(.segmented).onChange(of: reviewOnly) { _, _ in selection = [] }
        }
        if displayed.isEmpty {
          ContentUnavailableView(
            folderPhotos.isEmpty ? "아직 사진이 없어요" : "확인할 사진이 없어요",
            systemImage: folderPhotos.isEmpty ? "photo.on.rectangle.angled" : "checkmark.circle",
            description: Text(folderPhotos.isEmpty ? "+ 버튼으로 이 폴더에 사진을 추가해 보세요" : "모든 사진을 확인했습니다.")
          )
          .accessibilityIdentifier("emptyFolder")
        }
        LazyVGrid(
          columns: [GridItem(.adaptive(minimum: 145, maximum: 250), spacing: 12)], spacing: 14
        ) {
          ForEach(displayed) { photo in photoCard(photo) }
        }
      }.padding(20).frame(maxWidth: 850).frame(maxWidth: .infinity)
    }.background(Color.appBackground)
      .navigationTitle(store.library.folderName(folderID)).navigationBarTitleDisplayMode(.inline)
      .toolbar(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          if selecting {
            Button("취소") {
              selecting = false
              selection = []
            }.accessibilityIdentifier("cancelPhotoSelection")
          } else {
            ImportActions(compact: true, folderID: folderID)
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        if !folderPhotos.isEmpty {
          VStack(spacing: 12) {
            if selecting {
              HStack {
                Text("\(selectedIDs.count)장 선택").font(.subheadline.weight(.semibold))
                  .accessibilityIdentifier("selectedPhotoCount")
                Spacer()
                Button(selectedIDs == Set(displayed.map(\.id)) ? "선택 해제" : "모두 선택") {
                  selection =
                    selectedIDs == Set(displayed.map(\.id)) ? [] : Set(displayed.map(\.id))
                }.font(.subheadline).accessibilityIdentifier("selectAllPhotos")
              }
              HStack(spacing: 10) {
                Button {
                  moving = true
                } label: {
                  Label("폴더 이동", systemImage: "folder")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 48)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.seolin, lineWidth: 1))
                    .contentShape(RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(.plain).disabled(selectedIDs.isEmpty).accessibilityIdentifier(
                  "moveSelectedPhotos")
                DestructiveOutlineButton(
                  title: "선택한 \(selectedIDs.count)장 삭제", disabled: selectedIDs.isEmpty
                ) {
                  let ids = Array(selectedIDs)
                  Task {
                    await store.remove(ids)
                    selection = []
                    selecting = false
                  }
                }
                .accessibilityIdentifier("deleteSelectedPhotos")
              }
            }
            PrimaryButton(
              title: selecting ? "선택한 \(exportIDs.count)장 저장하기" : "\(exportIDs.count)장 저장하기",
              icon: "square.and.arrow.down"
            ) {
              store.path.append(.export(exportIDs))
            }.disabled(exportIDs.isEmpty).opacity(exportIDs.isEmpty ? 0.5 : 1)
              .accessibilityIdentifier("batchExport")
            Text("원본 사진은 변경되지 않아요").font(.caption).foregroundStyle(.secondary)
              .accessibilityIdentifier("originalNotice")
          }.padding(20).background(.regularMaterial)
        }
      }
      .sheet(isPresented: $settings) { SettingsView(draft: store.settings) }
      .sheet(isPresented: $moving) {
        MovePhotosSheet(ids: selectedIDs, currentFolderID: folderID) {
          selection = []
          selecting = false
        }
      }
      .onChange(of: folderPhotos.map(\.id)) { _, ids in selection.formIntersection(ids) }
      .disabled(store.busy || !store.ready)
  }
  private func photoCard(_ photo: PhotoItem) -> some View {
    Button {
      if selecting {
        if selection.contains(photo.id) {
          selection.remove(photo.id)
        } else {
          selection.insert(photo.id)
        }
      } else {
        store.path.append(.editor(photo.id))
      }
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        PhotoThumbnail(photo: photo).aspectRatio(0.8, contentMode: .fit).overlay(
          alignment: .topTrailing
        ) {
          if selecting {
            Image(systemName: selectedIDs.contains(photo.id) ? "checkmark.circle.fill" : "circle")
              .font(.title2).foregroundStyle(Color.seolin).padding(8)
              .background(Color.panel.opacity(0.9), in: Circle()).padding(6)
          } else if photo.custom {
            Image(systemName: "slider.horizontal.3").font(.caption).padding(8)
              .foregroundStyle(.white).background(Color.brandNavy, in: Circle()).padding(8)
          }
        }
        HStack {
          Text(photo.name).font(.caption.weight(.medium)).lineLimit(1)
          Spacer(minLength: 2)
          StatusPill(warning: photo.needsReview)
        }.padding(10)
      }.background(Color.panel, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
          RoundedRectangle(cornerRadius: 16).stroke(
            selectedIDs.contains(photo.id) ? Color.seolin : Color.secondary.opacity(0.12),
            lineWidth: selectedIDs.contains(photo.id) ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }.buttonStyle(.plain).accessibilityIdentifier("photo-\(photo.id)")
      .accessibilityValue(selectedIDs.contains(photo.id) ? "선택됨" : "선택 안 됨")
      .highPriorityGesture(
        LongPressGesture(minimumDuration: 0.45).onEnded { _ in beginSelection(photo.id) }
      )
      .accessibilityAction(named: Text("사진 선택")) { beginSelection(photo.id) }
  }
  private func beginSelection(_ id: Int) {
    selecting = true
    selection.insert(id)
    UISelectionFeedbackGenerator().selectionChanged()
  }
}
