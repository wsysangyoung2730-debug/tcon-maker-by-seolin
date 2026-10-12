import XCTest

/// Captures real app screens. Only the existing DEBUG sample import supplies fictional data.
final class AppStoreCaptureTests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testCaptureStoreScreenshots() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-sample", "-AppleInterfaceStyle", "Light"]
    app.launch()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 240))
    idle(app)
    #if targetEnvironment(simulator)
      // Capture the actual original-background workflow. Apple person segmentation
      // is tested/captured separately on the physical iPhone, not mocked here.
      app.buttons["batchSettings"].tap()
      let original = app.buttons["원본"]
      for _ in 0..<6 where !original.isHittable { app.swipeUp() }
      original.tap()
      app.buttons["applySettings"].tap()
      idle(app)
    #endif
    app.buttons["photo-1"].tap()
    XCTAssertTrue(app.images["editorCanvas"].waitForExistence(timeout: 20))
    capture(app, "03-editor")
    app.buttons["tool-배경"].tap()
    capture(app, "04-background")
    app.buttons["완료"].tap()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 20))
    app.buttons["photo-1"].press(forDuration: 0.8)
    app.buttons["photo-2"].tap()
    XCTAssertEqual(app.staticTexts["selectedPhotoCount"].label, "2장 선택")
    capture(app, "05-selection")
    app.buttons["batchExport"].tap()
    XCTAssertTrue(app.buttons["savePhotos"].waitForExistence(timeout: 10))
    capture(app, "06-export")
    back(app)
    app.buttons["cancelPhotoSelection"].tap()
    back(app)
    for name in ["10월 승급 심사", "유단자 심사"] {
      app.buttons["newFolder"].tap()
      let field = app.textFields["folderName"]
      XCTAssertTrue(field.waitForExistence(timeout: 10))
      field.tap()
      field.typeText(name + "\n")
      XCTAssertTrue(app.buttons["folder-\(name)"].waitForExistence(timeout: 10))
    }
    app.buttons["folder-unfiled"].tap()
    app.buttons["photo-1"].press(forDuration: 0.8)
    app.buttons["photo-2"].tap()
    app.buttons["moveSelectedPhotos"].tap()
    app.buttons["moveTo-10월 승급 심사"].tap()
    expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.buttons["photo-1"])
    waitForExpectations(timeout: 10)
    back(app)
    capture(app, "02-folders")
    selectHome(app)
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 10))
    capture(app, "01-home")
    let logo = app.images["seolinSignature"]
    for _ in 0..<4 where !logo.isHittable { app.scrollViews["homeContent"].swipeUp() }
    capture(app, "08-home-actions")
    app.scrollViews["homeContent"].swipeDown()
    app.buttons["openSettings"].tap()
    XCTAssertTrue(app.buttons["applySettings"].waitForExistence(timeout: 10))
    capture(app, "07-settings")
    app.buttons["취소"].tap()
  }

  private func selectHome(_ app: XCUIApplication) {
    let tab = app.tabBars.buttons["홈"]
    if tab.exists { tab.tap() }
    else { app.buttons["홈"].firstMatch.tap() }
  }
  private func back(_ app: XCUIApplication) { app.navigationBars.buttons.element(boundBy: 0).tap() }
  private func idle(_ app: XCUIApplication) {
    expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["processingOverlay"])
    waitForExpectations(timeout: 180)
  }
  private func capture(_ app: XCUIApplication, _ name: String) {
    idle(app)
    _ = XCTWaiter.wait(for: [], timeout: 0.6)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "store-" + name
    shot.lifetime = .keepAlways
    add(shot)
  }
}
