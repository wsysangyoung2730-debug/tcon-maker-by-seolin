import Foundation

/// Original bytes are stored separately; the atomic manifest is the source of truth.
actor PhotoLibraryDisk {
  let root: URL
  private var sources: URL { root.appendingPathComponent("Originals", isDirectory: true) }
  private var analyses: URL { root.appendingPathComponent("Analysis", isDirectory: true) }
  private var manifest: URL { root.appendingPathComponent("library.json") }

  init(root: URL) { self.root = root }

  static var applicationRoot: URL {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("PhotoLibrary", isDirectory: true)
  }

  func load() throws -> PhotoLibrary {
    guard FileManager.default.fileExists(atPath: manifest.path) else { return PhotoLibrary() }
    let library = try JSONDecoder().decode(PhotoLibrary.self, from: Data(contentsOf: manifest))
    guard library.version == 1 else { throw AppFailure("새 버전에서 저장된 사진함입니다. 앱을 업데이트해 주세요.") }
    guard Set(library.photos.map(\.id)).count == library.photos.count,
      Set(library.folders.map(\.id)).count == library.folders.count
    else { throw AppFailure("사진함 정보를 읽을 수 없어요. 저장된 원본은 그대로 보관됩니다.") }
    return library
  }

  func save(_ library: PhotoLibrary) throws {
    try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
    try JSONEncoder().encode(library).write(
      to: manifest, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  func writeOriginal(_ data: Data, id: UUID) throws {
    try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
    try data.write(
      to: originalURL(id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  func readOriginal(_ id: UUID) throws -> Data { try Data(contentsOf: originalURL(id)) }

  /// Rebuildable analysis stays separate from the authoritative originals and manifest.
  func readAnalysis(_ id: UUID) -> String? {
    try? String(contentsOf: analysisURL(id), encoding: .utf8)
  }

  func writeAnalysis(_ value: String?, id: UUID) throws {
    guard let value else { return }
    try FileManager.default.createDirectory(at: analyses, withIntermediateDirectories: true)
    var directory = analyses
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? directory.setResourceValues(values)
    try Data(value.utf8).write(
      to: analysisURL(id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
  }

  private func analysisURL(_ id: UUID) -> URL {
    analyses.appendingPathComponent(id.uuidString).appendingPathExtension("json")
  }

  /// Call only after the manifest no longer references these originals.
  func removeOriginals(_ ids: Set<UUID>) {
    for id in ids {
      try? FileManager.default.removeItem(at: originalURL(id))
      try? FileManager.default.removeItem(at: analysisURL(id))
    }
  }

  private func originalURL(_ id: UUID) -> URL {
    sources.appendingPathComponent(id.uuidString).appendingPathExtension("image")
  }
}
