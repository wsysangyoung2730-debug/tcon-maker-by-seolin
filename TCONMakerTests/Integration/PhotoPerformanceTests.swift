import UIKit
import XCTest

@testable import TCONMaker

@MainActor
final class PhotoPerformanceTests: XCTestCase {
  struct Metric: Decodable { let count: Int; let ms: Double }
  func testImportEditAndRestoreProfile() async throws {
    let engine = PhotoEngine()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIViewController()
    window.makeKeyAndVisible()
    window.rootViewController?.view.addSubview(engine.webView)
    defer { engine.webView.removeFromSuperview(); window.isHidden = true }
    let _: EngineAvailability = try await engine.call("ready")
    let _: Bool = try await engine.call("resetMetrics")
    let data = try XCTUnwrap(UIImage(named: "DemoPortrait")?.pngData())
    let args: [String: Any] = ["name":"성능예시.png", "mime":"image/png", "base64":data.base64EncodedString()]
    let start = Date()
    let initial: EngineSnapshot = try await engine.call("import", args)
    let photo = try XCTUnwrap(initial.photos.first)
    XCTAssertTrue(photo.face)
    XCTAssertEqual(photo.status, "done")
    print("PERF import_ms=\(Date().timeIntervalSince(start)*1000)")
    print("PERF import_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
    let _: Bool = try await engine.call("resetMetrics")
    let editStart = Date()
    let edited: PhotoItem = try await engine.call("update", ["id":photo.id,"adjustment":["bright":12,"zoom":1.08]])
    XCTAssertEqual(edited.adjustment.bright, 12)
    print("PERF edit_ms=\(Date().timeIntervalSince(editStart)*1000)")
    print("PERF edit_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
    let edits: [ArchivedPhotoEdit] = try await engine.call("archive")
    let state = try XCTUnwrap(edits.first?.state)
    let _: EngineSnapshot = try await engine.call("clear")
    let _: Bool = try await engine.call("resetMetrics")
    let restoreStart = Date()
    let imported: EngineSnapshot = try await engine.call("import", args)
    let id = try XCTUnwrap(imported.photos.first?.id)
    let restored: PhotoItem = try await engine.call("restore", ["id":id,"state":state])
    XCTAssertEqual(restored.preview, edited.preview)
    print("PERF restore_ms=\(Date().timeIntervalSince(restoreStart)*1000)")
    print("PERF restore_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
  }
}
