import XCTest

/// Opt in only on an explicitly authorized physical device: this writes two demo photos.
final class DeviceExportUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
    #if targetEnvironment(simulator)
      throw XCTSkip("Physical-device permission and camera checks")
    #endif
    try XCTSkipUnless(ProcessInfo.processInfo.environment["TCON_DEVICE_IO_TESTS"] == "1")
  }

  func testCameraPermissionDeniedThenAllowedAndCancel() {
    let app = XCUIApplication()
    app.resetAuthorizationStatus(for: .camera)
    launch(app, sample: false)
    openCamera(app)
    respondToPermission(allow: false)
    XCTAssertTrue(app.alerts["작업을 확인해 주세요"].waitForExistence(timeout: 15))
    XCTAssertTrue(app.alerts.buttons["설정 열기"].exists)
    app.alerts.buttons["확인"].tap()
    app.terminate()
    app.resetAuthorizationStatus(for: .camera)
    launch(app, sample: false)
    openCamera(app)
    respondToPermission(allow: true)
    let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "취소"])).firstMatch
    let importedPhoto = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "촬영_")).firstMatch
    expectation(for: NSPredicate { _, _ in cancel.exists || importedPhoto.exists }, evaluatedWith: app)
    waitForExpectations(timeout: 20)
    if importedPhoto.exists {
      // A user may finish a capture while permission automation is running.
      XCTAssertTrue(app.images["editorCanvas"].exists)
    } else {
      cancel.tap()
      XCTAssertTrue(app.buttons["capturePhoto"].waitForExistence(timeout: 10))
    }
  }

  func testPhotoPermissionDeniedThenSaveDemoPhotos() {
    let app = XCUIApplication()
    app.resetAuthorizationStatus(for: .photos)
    launch(app, sample: true)
    app.buttons["batchExport"].tap()
    app.buttons["savePhotos"].tap()
    respondToPermission(allow: false)
    XCTAssertTrue(app.alerts["작업을 확인해 주세요"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.alerts.buttons["설정 열기"].exists)
    app.alerts.buttons["확인"].tap()
    app.terminate()
    app.resetAuthorizationStatus(for: .photos)
    launch(app, sample: true)
    app.buttons["batchExport"].tap()
    app.buttons["savePhotos"].tap()
    respondToPermission(allow: true)
    XCTAssertTrue(app.alerts["안내"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.alerts.staticTexts["사진 2장을 사진 앱에 저장했습니다."].exists)
    app.alerts.buttons["확인"].tap()
  }

  func testFileAndShareSheetsCancelWithoutLeavingEditor() {
    let app = XCUIApplication()
    launch(app, sample: true)
    app.buttons["batchExport"].tap()
    let zip = app.buttons["destination-zip"]
    for _ in 0..<6 where !zip.isHittable { app.swipeUp() }
    zip.tap()
    app.buttons["savePhotos"].tap()
    let fileSave = app.buttons.matching(NSPredicate(format: "label IN %@", ["Save", "저장"])).firstMatch
    XCTAssertTrue(fileSave.waitForExistence(timeout: 20))
    dismissSystemSheet(app)
    waitHittable(app.buttons["savePhotos"])
    app.buttons["sharePhotos"].tap()
    let close = app.buttons.matching(NSPredicate(format: "label IN %@", ["Close", "닫기"])).firstMatch
    XCTAssertTrue(close.waitForExistence(timeout: 20))
    close.tap()
    waitHittable(app.buttons["savePhotos"])
    XCTAssertFalse(app.alerts["작업을 확인해 주세요"].exists)
  }

  private func dismissSystemSheet(_ app: XCUIApplication) {
    // iOS 26 Files exposes Save and Browse, and dismisses with the sheet handle.
    let handle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.09))
    handle.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)))
  }
  private func waitHittable(_ element: XCUIElement) {
    expectation(for: NSPredicate(format: "exists == true AND hittable == true"), evaluatedWith: element)
    waitForExpectations(timeout: 10)
  }
  private func launch(_ app: XCUIApplication, sample: Bool) {
    app.launchArguments = ["--ui-testing", "--ui-reset"] + (sample ? ["--ui-sample"] : [])
    app.launch()
    if sample {
      XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 180))
      expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.otherElements["processingOverlay"])
    } else {
      expectation(for: NSPredicate(format: "exists == true AND enabled == true"), evaluatedWith: app.buttons["importPhotos"])
    }
    waitForExpectations(timeout: 180)
  }
  private func openCamera(_ app: XCUIApplication) {
    app.scrollViews["homeContent"].swipeUp()
    app.buttons["capturePhoto"].tap()
  }
  private func respondToPermission(allow: Bool) {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alert = springboard.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout: 20))
    let denyLabels = ["Don’t Allow", "Don't Allow", "허용 안 함", "허용하지 않음"]
    let button = allow
      ? alert.buttons.matching(NSPredicate(format: "NOT (label IN %@)", denyLabels)).firstMatch
      : alert.buttons.matching(NSPredicate(format: "label IN %@", denyLabels)).firstMatch
    XCTAssertTrue(button.exists)
    button.tap()
  }
}
