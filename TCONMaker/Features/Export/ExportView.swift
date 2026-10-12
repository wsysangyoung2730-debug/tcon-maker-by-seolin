import SwiftUI

private struct ExportPresentation: Identifiable {
  let id = UUID()
  let urls: [URL]
  let share: Bool
}
struct ExportView: View {
  @EnvironmentObject private var store: PhotoStore
  let ids: [Int]
  @State private var destination = "photos"
  @State private var presentation: ExportPresentation?
  @State private var settings = false
  @State private var saving = false
  private var photos: [PhotoItem] { store.photos.filter { ids.contains($0.id) } }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HStack(alignment: .top, spacing: 12) {
          Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(.green)
          VStack(alignment: .leading, spacing: 6) {
            Text("사진을 저장해 보세요").font(.title2.bold())
            Text("선택한 사진 \(photos.count)장").foregroundStyle(.secondary)
          }
        }
        HStack(spacing: 10) {
          ForEach(Array(photos.prefix(3))) { photo in
            PhotoThumbnail(photo: photo).aspectRatio(0.8, contentMode: .fit).clipShape(
              RoundedRectangle(cornerRadius: 12))
          }
          if photos.count > 3 {
            Text("+\(photos.count-3)").font(.title.bold()).frame(
              maxWidth: .infinity, maxHeight: .infinity
            ).background(Color.seolin.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
          }
        }.frame(height: 125)
        VStack(spacing: 0) {
          detail("crop", "사진 규격", "\(store.settings.presetName) · \(store.settings.dimensions)")
          Divider()
          detail("doc", "파일 형식", formatDescription)
          Divider()
          detail(
            "externaldrive", "용량 설정",
            store.settings.orig ? "제한 없음" : "최대 \(Int(store.settings.maxkb)) KB · JPG")
          Divider()
          detail("photo", "해상도", "원본 기준 · 최대 1,600만 화소")
        }.background(Color.panel, in: RoundedRectangle(cornerRadius: 16))
        Button("저장 설정 변경", systemImage: "slider.horizontal.3") { settings = true }.font(
          .subheadline)
        VStack(alignment: .leading, spacing: 12) {
          Text("저장 위치").font(.title3.bold())
          VStack(spacing: 0) {
            destinationRow("photos", "사진 앱", "앨범에 사진으로 저장", "photo.on.rectangle")
            Divider()
            destinationRow("files", "파일 앱", "파일 이름을 유지해 저장", "folder")
            Divider()
            destinationRow("zip", "ZIP 파일", "여러 장을 하나로 묶기", "doc.zipper")
          }.background(Color.panel, in: RoundedRectangle(cornerRadius: 16))
        }
        Text("투명 배경 사진은 PNG로 저장되며 용량 제한이 적용되지 않습니다. 저장 전에 결과 파일의 용량과 배경 처리 상태를 확인합니다.").font(
          .caption
        ).foregroundStyle(.secondary)
        if !photos.isEmpty {
          DisclosureGroup("사진별 해상도 확인") {
            ForEach(photos) { photo in
              HStack {
                Text(photo.name).lineLimit(1)
                Spacer()
                Text("\(photo.width) × \(photo.height) px").monospacedDigit()
              }.font(.caption).padding(.vertical, 4)
            }
          }
        }
      }.padding(22).frame(maxWidth: 650)
    }.background(Color.appBackground)
      .navigationTitle("사진 저장").navigationBarTitleDisplayMode(.inline)
      .safeAreaInset(edge: .bottom) {
        VStack(spacing: 16) {
          PrimaryButton(
            title: saving ? "저장 중…" : "\(photos.count)장 저장하기", icon: "square.and.arrow.down"
          ) { Task { await save(share: false) } }.accessibilityIdentifier("savePhotos")
          Text("원본 사진은 변경되지 않아요").font(.caption).foregroundStyle(.secondary)
          Button("다른 앱으로 공유", systemImage: "square.and.arrow.up") {
            Task { await save(share: true) }
          }.accessibilityIdentifier("sharePhotos")
        }.padding(20).background(.regularMaterial).disabled(saving || photos.isEmpty || store.busy)
      }
      .sheet(item: $presentation) { item in
        if item.share {
          ShareSheet(urls: item.urls)
        } else {
          FilesExporter(urls: item.urls) { success in
            presentation = nil
            if success { store.notice = "파일 앱에 저장했습니다." }
          }
        }
      }
      .sheet(isPresented: $settings) { SettingsView(draft: store.settings) }
  }
  private var formatDescription: String {
    let png = photos.filter { $0.background == "clear" }.count
    return png == 0 ? "JPG" : png == photos.count ? "PNG" : "JPG + PNG"
  }
  private func detail(_ icon: String, _ title: String, _ value: String) -> some View {
    HStack(alignment: .top) {
      Image(systemName: icon).frame(width: 24)
      Text(title).fixedSize()
      Spacer(minLength: 8)
      Text(value).foregroundStyle(.secondary).multilineTextAlignment(.trailing)
    }.font(.subheadline).padding(16)
  }
  private func destinationRow(_ key: String, _ title: String, _ subtitle: String, _ icon: String)
    -> some View
  {
    Button {
      destination = key
    } label: {
      HStack(spacing: 14) {
        Image(systemName: icon).font(.title2).frame(width: 34)
        VStack(alignment: .leading, spacing: 4) {
          Text(title).font(.headline).foregroundStyle(.primary)
          Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: destination == key ? "checkmark.circle.fill" : "circle").font(.title2)
          .foregroundStyle(destination == key ? Color.seolin : Color.secondary)
      }.padding(16).contentShape(Rectangle())
    }.buttonStyle(.plain).accessibilityIdentifier("destination-\(key)").accessibilityValue(
      destination == key ? "선택됨" : "선택 안 됨")
  }
  private func save(share: Bool) async {
    saving = true
    defer { saving = false }
    guard let urls = await store.export(ids, zip: destination == "zip") else { return }
    if share {
      presentation = ExportPresentation(urls: urls, share: true)
    } else if destination == "photos" {
      do {
        try await ExportService.saveToPhotos(urls)
        store.notice = "사진 \(urls.count)장을 사진 앱에 저장했습니다."
      } catch { store.report(error) }
    } else {
      presentation = ExportPresentation(urls: urls, share: false)
    }
  }
}
