import UIKit
import XCTest

@testable import TCONMaker

@MainActor
final class PhotoPerformanceTests: XCTestCase {
  struct Metric: Decodable {
    let count: Int
    let ms: Double
  }
  func testImportEditAndRestoreProfile() async throws {
    try requirePersonSegmentationRuntime()
    let engine = PhotoEngine()
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIViewController()
    window.makeKeyAndVisible()
    window.rootViewController?.view.addSubview(engine.webView)
    defer {
      engine.webView.removeFromSuperview()
      window.isHidden = true
    }
    let _: EngineAvailability = try await engine.call("ready")
    let _: Bool = try await engine.call("resetMetrics")
    let data = try XCTUnwrap(UIImage(named: "DemoPortrait")?.pngData())
    let args: [String: Any] = [
      "name": "성능예시.png", "mime": "image/png", "base64": data.base64EncodedString(),
    ]
    let start = Date()
    let initial: EngineSnapshot = try await engine.call("import", args)
    let photo = try XCTUnwrap(initial.photos.first)
    XCTAssertTrue(photo.face)
    XCTAssertEqual(photo.status, "done")
    print("PERF import_ms=\(Date().timeIntervalSince(start)*1000)")
    print("PERF import_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
    let _: Bool = try await engine.call("resetMetrics")
    let editStart = Date()
    let edited: PhotoItem = try await engine.call(
      "update", ["id": photo.id, "adjustment": ["bright": 12, "zoom": 1.08]])
    XCTAssertEqual(edited.adjustment.bright, 12)
    print("PERF edit_ms=\(Date().timeIntervalSince(editStart)*1000)")
    print("PERF edit_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
    let editMetrics: [String: Metric] = try await engine.call("metrics")
    XCTAssertEqual(editMetrics["decode"]?.count ?? 0, 0)
    XCTAssertEqual(editMetrics["face"]?.count ?? 0, 0)
    XCTAssertEqual(editMetrics["background"]?.count ?? 0, 0)
    let _: Bool = try await engine.call("resetMetrics")
    var settings = PhotoSettings()
    settings.grid = false
    let _: EngineSnapshot = try await engine.call(
      "settings", ["settings": try settings.dictionary(), "preserve": true])
    let settingsMetrics: [String: Metric] = try await engine.call("metrics")
    XCTAssertEqual(
      settingsMetrics["preview"]?.count ?? 0, 0, "Guide-only changes must not rerender photos")
    let beforeExport: [ExportFile] = try await engine.call("export", ["ids": [photo.id]])
    let edits: [ArchivedPhotoEdit] = try await engine.call("archive", ["includeAnalysis": true])
    let analysis = try XCTUnwrap(edits.first?.analysis)
    let state = try XCTUnwrap(edits.first?.state)
    let _: EngineSnapshot = try await engine.call("clear")
    let _: Bool = try await engine.call("resetMetrics")
    let restoreStart = Date()
    var restoreArgs = args
    restoreArgs["state"] = state
    restoreArgs["analysis"] = analysis
    restoreArgs["single"] = true
    let restored: PhotoItem = try await engine.call("import", restoreArgs)
    XCTAssertEqual(restored.preview, edited.preview)
    print("PERF restore_ms=\(Date().timeIntervalSince(restoreStart)*1000)")
    print("PERF restore_stages=\(try await engine.call("metrics", as: [String: Metric].self))")
    let restoreMetrics: [String: Metric] = try await engine.call("metrics")
    XCTAssertEqual(restoreMetrics["face"]?.count ?? 0, 0)
    XCTAssertEqual(restoreMetrics["background"]?.count ?? 0, 0)
    XCTAssertEqual(restoreMetrics["decode"]?.count, 1)
    XCTAssertEqual(restoreMetrics["preview"]?.count, 1)
    XCTAssertEqual(restored.width, edited.width)
    XCTAssertEqual(restored.height, edited.height)
    XCTAssertEqual(restored.adjustment, edited.adjustment)
    let afterExport: [ExportFile] = try await engine.call("export", ["ids": [restored.id]])
    XCTAssertEqual(
      afterExport.first?.base64, beforeExport.first?.base64,
      "Cache must preserve original-resolution export")
    let _: EngineSnapshot = try await engine.call("clear")
    let _: Bool = try await engine.call("resetMetrics")
    restoreArgs["analysis"] = "damaged cache"
    let fallback: PhotoItem = try await engine.call("import", restoreArgs)
    XCTAssertEqual(
      fallback.preview, edited.preview, "Damaged derived cache must rebuild without losing edits")
    let fallbackMetrics: [String: Metric] = try await engine.call("metrics")
    XCTAssertEqual(fallbackMetrics["background"]?.count, 1)
    XCTAssertEqual(fallbackMetrics["face"]?.count ?? 0, 0)
    let _: EngineSnapshot = try await engine.call("clear")
    restoreArgs.removeValue(forKey: "analysis")
    let legacy: PhotoItem = try await engine.call("import", restoreArgs)
    XCTAssertEqual(
      legacy.preview, edited.preview, "Existing libraries without caches remain compatible")
    var secondArgs = args
    secondArgs["single"] = true
    let second: PhotoItem = try await engine.call("import", secondArgs)
    XCTAssertNotEqual(second.id, legacy.id)
    let library: EngineSnapshot = try await engine.call("snapshot")
    XCTAssertEqual(library.photos.count, 2)

  }
}
