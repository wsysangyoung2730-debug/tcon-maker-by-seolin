import XCTest

@testable import TCONMaker

final class PhotoLibraryTests: XCTestCase {
  func testFolderNamesMovesAndDeletingFoldersKeepPhotos() throws {
    var library = PhotoLibrary()
    let spring = try library.createFolder("  봄 심사  ")
    let summer = try library.createFolder("여름 심사")
    XCTAssertEqual(library.folders[0].name, "봄 심사")
    for invalid in ["", "  ", "미분류", "봄 심사", "잘못된/이름", String(repeating: "가", count: 41)] {
      XCTAssertThrowsError(try library.createFolder(invalid))
    }
    XCTAssertThrowsError(try library.renameFolder(summer, to: "봄 심사"))
    try library.renameFolder(spring, to: "3월 심사")
    let a = StoredPhoto(
      id: UUID(), name: "하나.jpg", mime: "image/jpeg", folderID: spring, editState: "saved",
      importedAt: Date())
    let b = StoredPhoto(
      id: UUID(), name: "둘.jpg", mime: "image/jpeg", folderID: spring, editState: nil,
      importedAt: Date())
    library.photos = [a, b]
    try library.movePhotos([a.id], to: summer)
    XCTAssertEqual(library.photos[0].folderID, summer)
    XCTAssertEqual(library.photos[1].folderID, spring)
    XCTAssertThrowsError(try library.movePhotos([b.id], to: UUID()))
    library.deleteFolders([summer])
    XCTAssertEqual(library.photos.count, 2)
    XCTAssertNil(library.photos[0].folderID)
    XCTAssertEqual(library.photos[0].editState, "saved")
    XCTAssertEqual(library.photos[1].folderID, spring)
  }

  func testLibraryAndOriginalsSurviveReopeningAndFolderDeletion() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let disk = PhotoLibraryDisk(root: root)
    var library = PhotoLibrary()
    let folder = try library.createFolder("심사반")
    let id = UUID()
    let second = UUID()
    let bytes = Data([1, 2, 3, 4])
    try await disk.writeOriginal(bytes, id: id)
    try await disk.writeOriginal(Data([5]), id: second)
    library.photos = [
      StoredPhoto(
        id: id, name: "../학생.jpg", mime: "image/jpeg", folderID: folder,
        editState: "{\"version\":1}", importedAt: Date())
    ]
    var settings = PhotoSettings()
    settings.preset("passport")
    library.settings = settings
    try await disk.save(library)
    let reopened = PhotoLibraryDisk(root: root)
    var restored = try await reopened.load()
    XCTAssertEqual(restored.photos[0].id, id)
    XCTAssertEqual(restored.photos[0].editState, library.photos[0].editState)
    XCTAssertEqual(restored.settings?.wmm, 35)
    restored.deleteFolders([folder])
    try await reopened.save(restored)
    let again = try await disk.load()
    let original = try await disk.readOriginal(id)
    XCTAssertNil(again.photos[0].folderID)
    XCTAssertEqual(original, bytes)
    await disk.removeOriginals([second])
    let kept = try await disk.readOriginal(id)
    XCTAssertEqual(kept, bytes)
  }

  func testCorruptManifestIsNotSilentlyReplaced() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let file = root.appendingPathComponent("library.json")
    let bytes = Data("broken".utf8)
    try bytes.write(to: file)
    do {
      _ = try await PhotoLibraryDisk(root: root).load()
      XCTFail("Corruption must be reported")
    } catch { XCTAssertEqual(try Data(contentsOf: file), bytes) }
  }
}
