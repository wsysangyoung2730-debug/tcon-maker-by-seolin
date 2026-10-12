import UIKit
import XCTest

@testable import TCONMaker

@MainActor
final class ReleaseRecoveryTests: XCTestCase {
  func testConsecutiveEditsPersistAndEngineRestartsFromDisk() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = PhotoStore(libraryRoot: root)
    store.settings.background = "orig"
    let window = mount(store.engine)
    defer { window.isHidden = true }
    await store.prepare()
    XCTAssertTrue(store.ready)
    let data = try XCTUnwrap(UIImage(named: "DemoPortrait")?.pngData())
    try await store.importNormalized((data, "복구.png", "image/png"), folderID: nil)
    let id = try XCTUnwrap(store.photos.first?.id)
    let first = Task { await store.update(id: id, adjustment: Adjustment(bright: 5)) }
    let second = Task { await store.update(id: id, adjustment: Adjustment(bright: 19)) }
    await first.value
    await second.value
    XCTAssertEqual(store.photos.first?.adjustment.bright, 19)
    let expected = store.photos.first?.preview
    store.engine.webViewWebContentProcessDidTerminate(store.engine.webView)
    XCTAssertFalse(store.ready)
    XCTAssertTrue(store.engine.needsReload)
    await store.prepare()
    XCTAssertTrue(store.ready, store.error ?? "")
    XCTAssertEqual(store.photos.count, 1)
    XCTAssertEqual(store.photos.first?.adjustment.bright, 19)
    XCTAssertEqual(store.photos.first?.preview, expected)
    XCTAssertEqual(store.library.photos.count, 1)
  }

  func testUnresolvedJavaScriptTimesOutAndCanRetry() async throws {
    let engine = PhotoEngine()
    let window = mount(engine)
    defer { window.isHidden = true }
    let _: EngineAvailability = try await engine.call("ready")
    _ = try await engine.webView.evaluateJavaScript(
      "window.TCONPendingPromise = new Promise(() => {}); window.TCONNative.execute = () => window.TCONPendingPromise; true;")
    engine.operationTimeout = 0.15
    do {
      let _: EngineAvailability = try await engine.call("ready")
      XCTFail("A stuck engine must finish with an error")
    } catch { XCTAssertTrue(error.localizedDescription.contains("시간이 초과")) }
    XCTAssertTrue(engine.needsReload)
    engine.operationTimeout = 120
    engine.restart()
    let ready: EngineAvailability = try await engine.call("ready")
    XCTAssertTrue(ready.faceAvailable)
    XCTAssertFalse(engine.needsReload)
  }

  private func mount(_ engine: PhotoEngine) -> UIWindow {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let controller = UIViewController()
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.addSubview(engine.webView)
    return window
  }
}
