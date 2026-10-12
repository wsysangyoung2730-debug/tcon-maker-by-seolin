import Foundation

extension PhotoStore {
  func folderID(for id: Int) -> UUID? {
    library.photos.first { $0.id == storedIDs[id] }?.folderID
  }

  func photos(in folderID: UUID?) -> [PhotoItem] {
    let ids = Set(library.photos.filter { $0.folderID == folderID }.map(\.id))
    return photos.filter { storedIDs[$0.id].map(ids.contains) == true }
  }

  func savedCount(in folderID: UUID?) -> Int {
    library.photos.filter { $0.folderID == folderID }.count
  }

  var missingCount: Int { library.photos.count - storedIDs.count }

  func importNormalized(_ normalized: (Data, String, String), folderID: UUID?) async throws {
    let stableID = UUID()
    var importedID: Int?
    do {
      try await disk.writeOriginal(normalized.0, id: stableID)
      let photo: PhotoItem = try await engine.call(
        "import",
        [
          "name": normalized.1, "mime": normalized.2, "base64": normalized.0.base64EncodedString(),
          "single": true,
        ])
      importedID = photo.id
      let edits: [ArchivedPhotoEdit] = try await engine.call(
        "archive", ["ids": [photo.id], "includeAnalysis": true])
      try? await disk.writeAnalysis(edits.first?.analysis, id: stableID)
      var candidate = library
      candidate.settings = settings
      candidate.photos.append(
        StoredPhoto(
          id: stableID, name: normalized.1, mime: normalized.2,
          folderID: folderID, editState: edits.first?.state, importedAt: Date()))
      try await disk.save(candidate)
      library = candidate
      storedIDs[photo.id] = stableID
      photos.append(photo)
    } catch {
      if let importedID {
        let _: EngineSnapshot? = try? await engine.call("delete", ["ids": [importedID]])
      }
      await disk.removeOriginals([stableID])
      throw AppFailure("사진을 사진함에 보관하지 못했어요. 기기의 저장 공간과 선택한 파일을 확인해 주세요.")
    }
  }

  func checkpoint(ids: [Int]? = nil) async throws {
    do {
      var payload: [String: Any] = ["includeAnalysis": true]
      if let ids { payload["ids"] = ids }
      let edits: [ArchivedPhotoEdit] = try await engine.call("archive", payload)
      var candidate = library
      candidate.settings = settings
      for edit in edits {
        guard let stableID = storedIDs[edit.id],
          let i = candidate.photos.firstIndex(where: { $0.id == stableID })
        else { continue }
        candidate.photos[i].editState = edit.state
        try? await disk.writeAnalysis(edit.analysis, id: stableID)
      }
      try await disk.save(candidate)
      library = candidate
      saveFailed = false
    } catch {
      saveFailed = true
      throw AppFailure("변경사항을 기기에 보관하지 못했어요. 저장 공간을 확인한 뒤 파일 탭에서 다시 저장해 주세요.")
    }
  }

  func retrySave() async {
    guard !busy, ready else { return }
    busy = true
    defer { busy = false }
    do { try await checkpoint() } catch { self.error = error.localizedDescription }
  }

  func restoreMissingPhotos() async {
    let loaded = Set(storedIDs.values)
    let pending = library.photos.filter { !loaded.contains($0.id) }
    var failures: [String] = []
    for (index, saved) in pending.enumerated() {
      progress = "사진함 불러오는 중 \(index + 1) / \(pending.count)"
      var importedID: Int?
      do {
        let data = try await disk.readOriginal(saved.id)
        var payload: [String: Any] = [
          "name": saved.name, "mime": saved.mime, "base64": data.base64EncodedString(),
          "single": true,
        ]
        if let state = saved.editState { payload["state"] = state }
        if let analysis = await disk.readAnalysis(saved.id) { payload["analysis"] = analysis }
        let photo: PhotoItem = try await engine.call("import", payload)
        importedID = photo.id
        let edits: [ArchivedPhotoEdit] = try await engine.call(
          "archive", ["ids": [photo.id], "includeAnalysis": true])
        try? await disk.writeAnalysis(edits.first?.analysis, id: saved.id)
        storedIDs[photo.id] = saved.id
        photos.append(photo)
      } catch {
        if let importedID {
          let _: EngineSnapshot? = try? await engine.call("delete", ["ids": [importedID]])
        }
        failures.append(saved.name)
      }
    }
    if !failures.isEmpty {
      error = "\(failures.count)장의 사진을 불러오지 못했어요. 저장된 파일은 유지됩니다. 파일 탭에서 다시 시도해 주세요."
    }
  }

  func retryRestore() async {
    guard !busy, ready else { return }
    busy = true
    defer {
      busy = false
      progress = ""
    }
    await restoreMissingPhotos()
  }

  func createFolder(_ name: String) async throws -> UUID {
    guard !busy, ready else { throw AppFailure("사진 처리 후 다시 시도해 주세요.") }
    busy = true
    defer { busy = false }
    var candidate = library
    let id = try candidate.createFolder(name)
    try await disk.save(candidate)
    library = candidate
    return id
  }

  func renameFolder(_ id: UUID, to name: String) async throws {
    guard !busy, ready else { throw AppFailure("사진 처리 후 다시 시도해 주세요.") }
    busy = true
    defer { busy = false }
    var candidate = library
    try candidate.renameFolder(id, to: name)
    try await disk.save(candidate)
    library = candidate
  }

  func deleteFolders(_ ids: Set<UUID>) async {
    guard !busy, ready else { return }
    busy = true
    defer { busy = false }
    do {
      var candidate = library
      candidate.deleteFolders(ids)
      try await disk.save(candidate)
      library = candidate
    } catch { self.error = "폴더를 삭제하지 못했어요. 기기 저장 공간을 확인하고 다시 시도해 주세요." }
  }

  @discardableResult
  func movePhotos(_ ids: Set<Int>, to folderID: UUID?) async -> Bool {
    guard !busy, ready else { return false }
    busy = true
    defer { busy = false }
    do {
      var candidate = library
      try candidate.movePhotos(Set(ids.compactMap { storedIDs[$0] }), to: folderID)
      try await disk.save(candidate)
      library = candidate
      return true
    } catch {
      self.error = error.localizedDescription
      return false
    }
  }
}
