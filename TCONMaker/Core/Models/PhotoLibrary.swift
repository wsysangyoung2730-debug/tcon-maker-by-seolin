import Foundation

struct PhotoFolder: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  let createdAt: Date
}

struct StoredPhoto: Codable, Identifiable {
  let id: UUID
  var name: String
  var mime: String
  var folderID: UUID?
  var editState: String?
  let importedAt: Date
}

struct PhotoLibrary: Codable {
  var version = 1
  var folders: [PhotoFolder] = []
  var photos: [StoredPhoto] = []
  var settings: PhotoSettings?

  func folderName(_ id: UUID?) -> String {
    folders.first { $0.id == id }?.name ?? "미분류"
  }

  mutating func createFolder(_ raw: String) throws -> UUID {
    let name = try validatedName(raw)
    let id = UUID()
    folders.append(PhotoFolder(id: id, name: name, createdAt: Date()))
    return id
  }

  mutating func renameFolder(_ id: UUID, to raw: String) throws {
    guard let index = folders.firstIndex(where: { $0.id == id }) else {
      throw AppFailure("폴더를 찾을 수 없어요.")
    }
    folders[index].name = try validatedName(raw, excluding: id)
  }

  mutating func deleteFolders(_ ids: Set<UUID>) {
    folders.removeAll { ids.contains($0.id) }
    for index in photos.indices where photos[index].folderID.map(ids.contains) == true {
      photos[index].folderID = nil
    }
  }

  mutating func movePhotos(_ ids: Set<UUID>, to folderID: UUID?) throws {
    guard folderID == nil || folders.contains(where: { $0.id == folderID }) else {
      throw AppFailure("이동할 폴더를 찾을 수 없어요.")
    }
    for index in photos.indices where ids.contains(photos[index].id) {
      photos[index].folderID = folderID
    }
  }

  private func validatedName(_ raw: String, excluding id: UUID? = nil) throws -> String {
    let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, name.count <= 40,
      name.rangeOfCharacter(from: .controlCharacters) == nil,
      !name.contains("/"), !name.contains("\\")
    else { throw AppFailure("폴더 이름은 1~40자로 입력해 주세요. 줄바꿈과 /, \\는 사용할 수 없어요.") }
    guard name.compare("미분류", options: [.caseInsensitive, .diacriticInsensitive]) != .orderedSame,
      !folders.contains(where: {
        $0.id != id
          && $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive])
            == .orderedSame
      })
    else { throw AppFailure("이미 사용 중인 폴더 이름이에요.") }
    return name
  }
}

struct ArchivedPhotoEdit: Decodable {
  let id: Int
  let state: String
  let analysis: String?
}
