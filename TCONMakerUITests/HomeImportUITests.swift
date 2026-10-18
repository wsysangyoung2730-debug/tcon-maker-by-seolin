import XCTest

final class HomeImportUITests: XCTestCase {
  func testExampleCardAndPrimaryButtonOpenPhotoLibrary() {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset"]
    app.launch()
    let card = app.buttons["homeExamplePhoto"]
    expectation(for: NSPredicate(format: "exists == true AND enabled == true"), evaluatedWith: card)
    waitForExpectations(timeout: 180)
    if UIDevice.current.userInterfaceIdiom == .pad {
      let size = app.buttons["homePhotoSize"]
      let picker = app.buttons["importPhotos"]
      let camera = app.buttons["capturePhoto"]
      XCTAssertTrue(size.isHittable)
      XCTAssertTrue(picker.isHittable)
      XCTAssertTrue(camera.isHittable)
      XCTAssertGreaterThan(size.frame.minY, card.frame.maxY)
      XCTAssertGreaterThan(picker.frame.minY, size.frame.maxY)
      XCTAssertGreaterThan(camera.frame.minY, picker.frame.maxY)
      XCTAssertEqual(card.frame.midX, picker.frame.midX, accuracy: 2)
      capture("store-01-home")
      capture("store-08-home-actions")
      size.tap()
      XCTAssertTrue(app.buttons["applySettings"].waitForExistence(timeout: 10))
      capture("store-07-settings")
      app.buttons["취소"].tap()
    }
    card.tap()
    closePhotoPicker(app)
    let button = app.buttons["importPhotos"]
    for _ in 0..<5 where !button.isHittable { app.swipeUp() }
    XCTAssertTrue(button.isHittable)
    XCTAssertTrue(app.scrollViews["homeContent"].buttons["importPhotos"].exists)
    button.tap()
    closePhotoPicker(app)
  }
  private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
  private func closePhotoPicker(_ app: XCUIApplication) {
    let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["취소", "Cancel"]))
      .firstMatch
    XCTAssertTrue(cancel.waitForExistence(timeout: 15), app.debugDescription)
    cancel.tap()
    XCTAssertTrue(app.buttons["homeExamplePhoto"].waitForExistence(timeout: 10))
  }

  func testLargeTextHomeAndEditorRemainScrollable() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-reset", "--ui-sample",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 240))
    expectation(
      for: NSPredicate(format: "exists == false"),
      evaluatedWith: app.otherElements["processingOverlay"])
    waitForExpectations(timeout: 180)
    app.buttons["photo-1"].tap()
    let tool = app.buttons["tool-맞춤"]
    for _ in 0..<8 where !tool.isHittable { app.swipeUp() }
    XCTAssertTrue(tool.isHittable)
    tool.tap()
    XCTAssertTrue(app.switches["인물 기준 자동 정렬"].waitForExistence(timeout: 10))
    app.buttons["완료"].tap()
    let home = app.tabBars.buttons["홈"]
    if home.exists { home.tap() } else { app.buttons["홈"].firstMatch.tap() }
    let example = app.buttons["homeExamplePhoto"]
    let picker = app.buttons["importPhotos"]
    for _ in 0..<8 where !picker.isHittable { app.scrollViews["homeContent"].swipeUp() }
    XCTAssertTrue(picker.isHittable)
    XCTAssertGreaterThan(picker.frame.minY, example.frame.minY)
  }

  func testNarrowWindowKeepsVerticalEditorAndHome() throws {
    XCUIDevice.shared.orientation = .portrait
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-sample"]
    app.launch()
    guard app.windows.firstMatch.frame.width < 820 else {
      throw XCTSkip("Run on an iPad mini or a compact window")
    }
    XCTAssertTrue(app.buttons["photo-1"].waitForExistence(timeout: 240))
    expectation(
      for: NSPredicate(format: "exists == false"),
      evaluatedWith: app.otherElements["processingOverlay"])
    waitForExpectations(timeout: 180)
    app.buttons["photo-1"].tap()
    let canvas = app.images["editorCanvas"]
    let tool = app.buttons["tool-맞춤"]
    XCTAssertTrue(canvas.waitForExistence(timeout: 10))
    XCTAssertGreaterThanOrEqual(tool.frame.minY, canvas.frame.maxY)
    app.buttons["완료"].tap()
    let home = app.tabBars.buttons["홈"]
    if home.exists { home.tap() } else { app.buttons["홈"].firstMatch.tap() }
    let example = app.buttons["homeExamplePhoto"]
    let picker = app.buttons["importPhotos"]
    XCTAssertTrue(example.waitForExistence(timeout: 10))
    for _ in 0..<8 where !picker.isHittable { app.scrollViews["homeContent"].swipeUp() }
    XCTAssertTrue(picker.isHittable)
    XCTAssertGreaterThan(picker.frame.minY, example.frame.minY)
    picker.tap()
    closePhotoPicker(app)
  }
}
