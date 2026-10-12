import XCTest

final class TutorialUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testPracticeReplayAndRealLibraryStaySeparate() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-onboarding", "--ui-reset-onboarding", "--ui-reset",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["startTutorial"].waitForExistence(timeout: 15))
    tap(app.buttons["startTutorial"], in: app)
    XCTAssertTrue(app.buttons["tutorialPickPhoto"].waitForExistence(timeout: 10))
    app.buttons["tutorialPickPhoto"].tap()
    XCTAssertTrue(app.staticTexts["tutorialPhotoPicked"].exists)
    app.buttons["tutorialNext"].tap()
    app.buttons["tutorialPreset-passport"].tap()
    XCTAssertEqual(app.staticTexts["tutorialDimensions"].label, "35 × 45 mm")
    app.sliders["tutorialZoom"].adjust(toNormalizedSliderPosition: 0.7)
    capture("11-tutorial-crop")
    app.buttons["tutorialNext"].tap()
    app.buttons["tutorialNewFolder"].tap()
    XCTAssertEqual(app.staticTexts["tutorialFolderFeedback"].label, "승급 심사 폴더를 만들었어요")
    capture("12-tutorial-folder")
    app.buttons["tutorialNext"].tap()
    app.buttons["tutorialPhoto-1"].press(forDuration: 0.8)
    app.buttons["tutorialPhoto-2"].tap()
    XCTAssertEqual(app.staticTexts["tutorialSelectionCount"].label, "2장 선택")
    capture("13-tutorial-selection")
    tap(app.buttons["tutorialSaveSelected"], in: app)
    XCTAssertEqual(app.staticTexts["tutorialProgress"].label, "5 / 5")
    tap(app.buttons["tutorialDestination-zip"], in: app)
    XCTAssertEqual(app.buttons["tutorialDestination-zip"].value as? String, "선택됨")
    tap(app.buttons["tutorialPracticeSave"], in: app)
    XCTAssertTrue(app.staticTexts["tutorialSaveComplete"].exists)
    capture("14-tutorial-save")
    app.buttons["tutorialNext"].tap()
    waitReady(app)
    app.tabBars.buttons["파일"].tap()
    XCTAssertTrue(app.buttons["folder-unfiled"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.buttons["folder-unfiled"].value as? String, "사진 0장")
    XCTAssertFalse(app.buttons["folder-승급 심사"].exists)
    app.tabBars.buttons["홈"].tap()
    app.buttons["openSettings"].tap()
    XCTAssertEqual(app.buttons["TCON"].value as? String, "선택됨")
    tap(app.buttons["openTutorial"], in: app)
    XCTAssertTrue(app.buttons["tutorialPickPhoto"].waitForExistence(timeout: 10))
    XCTAssertEqual(app.staticTexts["tutorialProgress"].label, "1 / 5")
    XCTAssertFalse(app.staticTexts["tutorialPhotoPicked"].exists)
    app.buttons["closeTutorial"].tap()
    XCTAssertTrue(app.buttons["applySettings"].waitForExistence(timeout: 10))
    app.buttons["취소"].tap()
    app.terminate()
    app.launchArguments = ["--ui-testing", "--ui-onboarding"]
    app.launch()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
    XCTAssertFalse(app.staticTexts["welcomeTitle"].exists)
  }

  func testCloseBackAndSkip() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-onboarding", "--ui-reset-onboarding", "--ui-reset",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["startTutorial"].waitForExistence(timeout: 15))
    tap(app.buttons["startTutorial"], in: app)
    XCTAssertTrue(app.buttons["tutorialNext"].waitForExistence(timeout: 10))
    app.buttons["tutorialNext"].tap()
    app.buttons["tutorialPrevious"].tap()
    XCTAssertEqual(app.staticTexts["tutorialProgress"].label, "1 / 5")
    app.buttons["closeTutorial"].tap()
    XCTAssertTrue(app.staticTexts["welcomeTitle"].waitForExistence(timeout: 10))
    tap(app.buttons["startTutorial"], in: app)
    XCTAssertTrue(app.buttons["skipTutorial"].waitForExistence(timeout: 10))
    app.buttons["skipTutorial"].tap()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
  }

  private func tap(_ element: XCUIElement, in app: XCUIApplication) {
    for _ in 0..<6 {
      if element.isHittable { break }
      app.swipeUp()
    }
    XCTAssertTrue(element.isHittable)
    element.tap()
  }
  private func waitReady(_ app: XCUIApplication) {
    let ready = NSPredicate(format: "exists == true AND enabled == true")
    expectation(for: ready, evaluatedWith: app.buttons["importPhotos"])
    waitForExpectations(timeout: 180)
  }
  private func capture(_ name: String) {
    let shot = XCTAttachment(screenshot: XCUIApplication().screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}
