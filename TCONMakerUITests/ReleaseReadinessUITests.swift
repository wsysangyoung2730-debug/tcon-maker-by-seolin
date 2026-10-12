import XCTest

final class ReleaseReadinessUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testSupportLicensesAndUnavailableCamera() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset"]
    app.launch()
    waitEnabled(app.buttons["importPhotos"])
    #if targetEnvironment(simulator)
    app.scrollViews["homeContent"].swipeUp()
    app.buttons["capturePhoto"].tap()
    XCTAssertTrue(app.alerts["작업을 확인해 주세요"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.alerts.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "카메라를 사용할 수 없어요")).firstMatch.exists)
    app.alerts.buttons["확인"].tap()
    #endif
    app.buttons["openSettings"].tap()
    let about = app.buttons["앱 정보 및 개인정보"]
    for _ in 0..<8 where !about.isHittable { app.swipeUp() }
    XCTAssertTrue(about.isHittable)
    about.tap()
    let licenses = app.buttons["openLicenses"]
    for _ in 0..<6 where !licenses.isHittable { app.swipeUp() }
    XCTAssertTrue(app.buttons["supportLink"].exists)
    XCTAssertTrue(licenses.isHittable)
    licenses.tap()
    XCTAssertTrue(app.navigationBars["오픈소스 고지"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "TensorFlow.js")).firstMatch.exists)
  }

  func testLargestTextSettingsRemainSelectable() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleInterfaceStyle", "Dark"]
    app.launch()
    waitEnabled(app.buttons["importPhotos"])
    app.buttons["openSettings"].tap()
    let passport = app.buttons["여권사진"]
    for _ in 0..<5 where !passport.isHittable { app.swipeUp() }
    XCTAssertTrue(passport.isHittable)
    passport.tap()
    XCTAssertEqual(passport.value as? String, "선택됨")
    XCTAssertTrue(app.buttons["applySettings"].isHittable)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "qa-largest-text-dark"
    shot.lifetime = .keepAlways
    add(shot)
    app.buttons["applySettings"].tap()
    waitEnabled(app.buttons["importPhotos"])
  }

  private func waitEnabled(_ element: XCUIElement) {
    expectation(for: NSPredicate(format: "exists == true AND enabled == true"), evaluatedWith: element)
    waitForExpectations(timeout: 180)
  }
}
