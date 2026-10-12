import PhotosUI
import SwiftUI

enum AppRoute: Hashable {
  case batch
  case editor(Int)
  case export([Int])
}
@MainActor
final class PhotoStore: ObservableObject {
  let engine = PhotoEngine()
  @Published var settings: PhotoSettings
  @Published var photos: [PhotoItem] = []
  @Published var path: [AppRoute] = []
  @Published var busy = false
  @Published var progress = ""
  @Published var error: String?
  @Published var notice: String?
  @Published var ready = false
  @Published var faceAvailable = false
  @Published var backgroundAvailable = false
  @Published var library = PhotoLibrary()
  @Published var saveFailed = false
  let disk: PhotoLibraryDisk
  var storedIDs: [Int: UUID] = [:]
  private var started = false
  init(libraryRoot: URL? = nil) {
    var root = libraryRoot ?? PhotoLibraryDisk.applicationRoot
    #if DEBUG
      if libraryRoot == nil, ProcessInfo.processInfo.arguments.contains("--ui-testing") {
        root = root.deletingLastPathComponent().appendingPathComponent("UITestPhotoLibrary")
        if ProcessInfo.processInfo.arguments.contains("--ui-reset") {
          try? FileManager.default.removeItem(at: root)
        }
      }
    #endif
    disk = PhotoLibraryDisk(root: root)
    settings =
      (UserDefaults.standard.data(forKey: "photoSettings").flatMap {
        try? JSONDecoder().decode(PhotoSettings.self, from: $0)
      }) ?? PhotoSettings()
    settings.validate()
    ExportService.cleanOldExports()
    #if DEBUG
      if ProcessInfo.processInfo.arguments.contains("--ui-testing") { settings = PhotoSettings() }
    #endif
  }
  func prepare() async {
    guard !started else { return }
    started = true
    progress = "사진 도구 준비 중…"
    busy = true
    defer { busy = false }
    do {
      do { library = try await disk.load() } catch {
        throw AppFailure("저장된 사진함을 열지 못했어요. 기존 파일은 보관되어 있습니다. 다시 시도해 주세요.")
      }
      if let saved = library.settings {
        settings = saved
        settings.validate()
      }
      let state: EngineAvailability = try await engine.call("ready")
      faceAvailable = state.faceAvailable
      backgroundAvailable = state.backgroundAvailable
      let _: EngineSnapshot = try await engine.call(
        "settings", ["settings": try settings.dictionary(), "preserve": true])
      await restoreMissingPhotos()
      ready = true
      busy = false
      progress = ""
      if !state.faceAvailable || !state.backgroundAvailable {
        notice = "자동 인식 일부를 준비하지 못했어요. 원본 배경과 수동 편집을 사용할 수 있습니다."
      }
      #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-sample"), library.photos.isEmpty,
          let sample = UIImage(named: "DemoPortrait")?.pngData()
        {
          await importing(total: 2) { _ in (sample, "예시.png") }
        }
      #endif
    } catch {
      self.error = error.localizedDescription
      progress = "준비 실패"
      started = false
    }
  }
  private func accept(_ snapshot: EngineSnapshot) {
    photos = snapshot.photos.filter { storedIDs[$0.id] != nil }
    faceAvailable = snapshot.faceAvailable
    backgroundAvailable = snapshot.backgroundAvailable
  }
  func importSelections(_ items: [PhotosPickerItem], folderID: UUID? = nil) async {
    await importing(total: items.count, folderID: folderID) { index in
      guard let data = try await items[index].loadTransferable(type: Data.self) else {
        throw AppFailure("선택한 사진을 가져오지 못했어요.")
      }
      let ext = items[index].supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
      return (data, "사진_\(UUID().uuidString.prefix(6)).\(ext)")
    }
  }
  func importFiles(_ urls: [URL], folderID: UUID? = nil) async {
    await importing(total: urls.count, folderID: folderID) { index in
      let url = urls[index]
      let access = url.startAccessingSecurityScopedResource()
      defer { if access { url.stopAccessingSecurityScopedResource() } }
      return (try Data(contentsOf: url), url.lastPathComponent)
    }
  }
  func importCamera(_ image: UIImage, folderID: UUID? = nil) async {
    await importing(total: 1, folderID: folderID) { _ in
      guard let data = image.jpegData(compressionQuality: 1) else {
        throw AppFailure("촬영한 사진을 읽지 못했어요.")
      }
      return (data, "촬영_\(UUID().uuidString.prefix(6)).jpg")
    }
  }
  private func importing(
    total: Int, folderID: UUID? = nil, read: (Int) async throws -> (Data, String)
  ) async {
    guard total > 0, !busy, ready else { return }
    busy = true
    defer {
      busy = false
      progress = ""
    }
    guard folderID == nil || library.folders.contains(where: { $0.id == folderID }) else {
      error = "사진을 추가할 폴더를 찾을 수 없어요."
      return
    }
    let oldIDs = Set(photos.map(\.id))
    var failures: [String] = []
    for index in 0..<total {
      progress = "사진 맞추는 중 \(index+1) / \(total)"
      do {
        let (data, name) = try await read(index)
        let normalized = try await Task.detached(priority: .userInitiated) {
          try PhotoImport.normalize(data, name: name)
        }.value
        try await importNormalized(normalized, folderID: folderID)
      } catch { failures.append(error.localizedDescription) }
    }
    let added = photos.filter { !oldIDs.contains($0.id) }
    if added.count == 1, let item = added.first, item.status == "done" {
      path = [.batch, .editor(item.id)]
    } else if !added.isEmpty {
      path = [.batch]
    }
    if !failures.isEmpty { error = failures.joined(separator: "\n") }
  }
  func applySettings(_ value: PhotoSettings, preserve: Bool) async {
    guard !busy else { return }
    busy = true
    progress = "전체 설정 적용 중…"
    defer {
      busy = false
      progress = ""
    }
    var validated = value
    validated.validate()
    do {
      let state: EngineSnapshot = try await engine.call(
        "settings", ["settings": try validated.dictionary(), "preserve": preserve])
      settings = validated
      accept(state)
      UserDefaults.standard.set(try JSONEncoder().encode(validated), forKey: "photoSettings")
      try await checkpoint()
    } catch { self.error = error.localizedDescription }
  }
  func update(
    id: Int, adjustment: Adjustment? = nil, background: String? = nil,
    composition: Composition? = nil, snap: Bool? = nil, realign: Bool = false
  ) async {
    var payload: [String: Any] = ["id": id, "realign": realign]
    do {
      if let adjustment { payload["adjustment"] = try adjustment.dictionary() }
      if let background { payload["background"] = background }
      if let composition { payload["composition"] = try composition.dictionary() }
      if let snap { payload["snap"] = snap }
    } catch {
      self.error = error.localizedDescription
      return
    }
    await edit("update", payload: payload)
  }
  func edit(_ command: String, payload: [String: Any]) async {
    guard !busy else { return }
    busy = true
    progress = "사진 조정 중…"
    defer {
      busy = false
      progress = ""
    }
    do {
      let photo: PhotoItem = try await engine.call(command, payload)
      if let i = photos.firstIndex(where: { $0.id == photo.id }) { photos[i] = photo }
      try await checkpoint()
    } catch { self.error = error.localizedDescription }
  }
  func remove(_ ids: [Int]) async {
    guard !busy else { return }
    busy = true
    defer { busy = false }
    do {
      let stable = Set(ids.compactMap { storedIDs[$0] })
      var candidate = library
      candidate.photos.removeAll { stable.contains($0.id) }
      try await disk.save(candidate)
      library = candidate
      for id in ids { storedIDs.removeValue(forKey: id) }
      photos.removeAll { ids.contains($0.id) }
      await disk.removeOriginals(stable)
      let state: EngineSnapshot = try await engine.call("delete", ["ids": ids])
      accept(state)
    } catch { self.error = error.localizedDescription }
  }
  func export(_ ids: [Int], zip: Bool) async -> [URL]? {
    guard !busy else { return nil }
    busy = true
    progress = "원본으로 저장 파일 만드는 중…"
    defer {
      busy = false
      progress = ""
    }
    do {
      let files: [ExportFile] = try await engine.call("export", ["ids": ids, "zip": zip])
      return try ExportService.write(files)
    } catch {
      self.error = error.localizedDescription
      return nil
    }
  }
  func photo(_ id: Int) -> PhotoItem? { photos.first { $0.id == id } }
}
