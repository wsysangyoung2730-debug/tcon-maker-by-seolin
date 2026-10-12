import ImageIO
import UIKit
import XCTest

@testable import TCONMaker

@MainActor
final class PhotoEngineTests: XCTestCase {
  func testOfflineFaceBackgroundEditingAndExports() async throws {
    try requirePersonSegmentationRuntime()
    let engine = PhotoEngine()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let controller = UIViewController()
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.addSubview(engine.webView)
    defer {
      engine.webView.removeFromSuperview()
      window.isHidden = true
    }
    let ready: EngineAvailability = try await engine.call("ready")
    XCTAssertTrue(ready.faceAvailable, "Bundled face model must initialize without network")
    XCTAssertTrue(ready.backgroundAvailable, "Bundled segmentation model must initialize")
    let image = try XCTUnwrap(UIImage(named: "DemoPortrait"))
    let data = try XCTUnwrap(image.pngData())
    let args: [String: Any] = [
      "name": "학생.png", "mime": "image/png", "base64": data.base64EncodedString(),
    ]
    let initial: EngineSnapshot = try await engine.call("import", args)
    let first = try XCTUnwrap(initial.photos.first)
    XCTAssertEqual(first.status, "done")
    XCTAssertTrue(first.face, "Known sample portrait should be detected")
    XCTAssertNotNil(first.image)
    XCTAssertEqual(Double(first.width) / Double(first.height), 0.8, accuracy: 0.005)
    let changed: PhotoItem = try await engine.call(
      "update",
      [
        "id": first.id,
        "adjustment": ["bright": 10, "zoom": 1.15, "dx": 0.05, "dy": 0.03, "tilt": 2],
        "composition": ["top": 10, "center": "face"], "background": "clear", "snap": false,
      ])
    XCTAssertEqual(changed.adjustment.bright, 10)
    XCTAssertEqual(changed.composition.top, 10)
    XCTAssertEqual(changed.background, "clear")
    XCTAssertFalse(changed.snap)
    var global = PhotoSettings()
    global.bright = -5
    global.background = "white"
    let preserved: EngineSnapshot = try await engine.call(
      "settings", ["settings": try global.dictionary(), "preserve": true])
    XCTAssertEqual(preserved.photos[0].background, "clear")
    XCTAssertEqual(preserved.photos[0].composition.top, 10)
    let pngs: [ExportFile] = try await engine.call("export", ["ids": [first.id]])
    let png = try XCTUnwrap(pngs.first)
    XCTAssertEqual(png.mime, "image/png")
    let pngData = try XCTUnwrap(Data(base64Encoded: png.base64))
    XCTAssertEqual(pngData.prefix(8), Data([137, 80, 78, 71, 13, 10, 26, 10]))
    let cg = try XCTUnwrap(UIImage(data: pngData)?.cgImage)
    XCTAssertTrue(
      [CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .last, .first].contains(
        cg.alphaInfo))
    attach(pngData, type: "public.png", name: "transparent-export")
    let reset: EngineSnapshot = try await engine.call(
      "settings", ["settings": try global.dictionary(), "preserve": false])
    XCTAssertEqual(reset.photos[0].background, "white")
    XCTAssertEqual(reset.photos[0].adjustment.bright, 0)
    XCTAssertEqual(reset.photos[0].composition.top, 8)
    let turned: PhotoItem = try await engine.call("rotate", ["id": first.id, "direction": 1])
    XCTAssertEqual(turned.rotation, 1)
    let restored: PhotoItem = try await engine.call("reset", ["id": first.id])
    XCTAssertEqual(restored.adjustment.zoom, 1)
    XCTAssertEqual(restored.rotation, 0)
    let batch: EngineSnapshot = try await engine.call("import", args)
    XCTAssertEqual(batch.photos.count, 2)
    let ids = batch.photos.map(\.id)
    let jpegs: [ExportFile] = try await engine.call("export", ["ids": ids])
    XCTAssertEqual(jpegs.count, 2)
    XCTAssertNotEqual(jpegs[0].name, jpegs[1].name)
    for file in jpegs {
      XCTAssertLessThanOrEqual(file.size, 300 * 1024)
      let bytes = try XCTUnwrap(Data(base64Encoded: file.base64))
      XCTAssertNotNil(UIImage(data: bytes))
      XCTAssertEqual(bytes.prefix(2), Data([255, 216]))
    }
    attach(
      try XCTUnwrap(Data(base64Encoded: jpegs[0].base64)), type: "public.jpeg", name: "white-export"
    )
    let zips: [ExportFile] = try await engine.call("export", ["ids": ids, "zip": true])
    let zip = try XCTUnwrap(Data(base64Encoded: zips[0].base64))
    XCTAssertEqual(zip.prefix(4), Data([80, 75, 3, 4]))
    let names = localZipNames(zip)
    XCTAssertEqual(names.count, 2)
    XCTAssertEqual(Set(names).count, 2)
    attach(zip, type: "public.zip-archive", name: "batch-export")
    let deleted: EngineSnapshot = try await engine.call("delete", ["ids": [first.id]])
    XCTAssertEqual(deleted.photos.count, 1)
    let empty: EngineSnapshot = try await engine.call("clear")
    XCTAssertTrue(empty.photos.isEmpty)
    // Persisted edits must be independent of transient engine IDs and survive re-import.
    let imported: EngineSnapshot = try await engine.call("import", args)
    let savedID = try XCTUnwrap(imported.photos.first?.id)
    let _: PhotoItem = try await engine.call("rotate", ["id": savedID, "direction": 1])
    let edited: PhotoItem = try await engine.call(
      "update",
      [
        "id": savedID,
        "adjustment": ["bright": 17, "zoom": 1.2, "dx": 0.04, "dy": -0.03, "tilt": 3],
        "composition": ["top": 12, "center": "body"], "background": "orig", "snap": false,
      ])
    let archive: [ArchivedPhotoEdit] = try await engine.call("archive", ["ids": [savedID]])
    let saved = try XCTUnwrap(archive.first?.state)
    let _: EngineSnapshot = try await engine.call("clear")
    let reimported: EngineSnapshot = try await engine.call("import", args)
    let newID = try XCTUnwrap(reimported.photos.first?.id)
    XCTAssertNotEqual(savedID, newID)
    let recovered: PhotoItem = try await engine.call("restore", ["id": newID, "state": saved])
    XCTAssertEqual(recovered.adjustment, edited.adjustment)
    XCTAssertEqual(recovered.composition, edited.composition)
    XCTAssertEqual(recovered.rotation, edited.rotation)
    XCTAssertEqual(recovered.background, "orig")
    XCTAssertFalse(recovered.snap)
    XCTAssertEqual(recovered.preview, edited.preview)
    let updated = PhotoSettings()
    let inherited: EngineSnapshot = try await engine.call(
      "settings", ["settings": try updated.dictionary(), "preserve": true])
    XCTAssertEqual(inherited.photos[0].composition.top, 12)
    XCTAssertEqual(inherited.photos[0].background, "orig")
  }
  private func attach(_ data: Data, type: String, name: String) {
    let a = XCTAttachment(data: data, uniformTypeIdentifier: type)
    a.name = name
    a.lifetime = .keepAlways
    add(a)
  }
  private func localZipNames(_ data: Data) -> [String] {
    let b = [UInt8](data)
    var offset = 0
    var names: [String] = []
    func little(_ p: Int, _ n: Int) -> Int { (0..<n).reduce(0) { $0 | Int(b[p + $1]) << ($1 * 8) } }
    while offset + 30 <= b.count && Array(b[offset..<offset + 4]) == [80, 75, 3, 4] {
      let size = little(offset + 18, 4)
      let length = little(offset + 26, 2)
      let extra = little(offset + 28, 2)
      guard offset + 30 + length + extra + size <= b.count else { break }
      names.append(String(decoding: b[offset + 30..<offset + 30 + length], as: UTF8.self))
      offset += 30 + length + extra + size
    }
    return names
  }
}
