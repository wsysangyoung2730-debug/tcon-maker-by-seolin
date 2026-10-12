import XCTest

final class OnboardingUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testFirstLaunchAndCompletionPersist() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--ui-onboarding", "--ui-reset-onboarding", "--ui-reset",
    ]
    app.launch()
    XCTAssertTrue(app.staticTexts["welcomeTitle"].waitForExistence(timeout: 15))
    XCTAssertFalse(app.otherElements["processingOverlay"].exists)
    XCTAssertFalse(app.buttons["openSettings"].exists)
    let shot = XCTAttachment(screenshot: app.screenshot())
    shot.name = "10-onboarding"
    shot.lifetime = .keepAlways
    add(shot)
    let finish = app.buttons["finishOnboarding"]
    for _ in 0..<6 where !finish.isHittable { app.scrollViews["welcomeContent"].swipeUp() }
    XCTAssertTrue(finish.isHittable)
    XCTAssertTrue(app.scrollViews["welcomeContent"].buttons["startTutorial"].exists)
    XCTAssertGreaterThan(app.buttons["startTutorial"].frame.minY, app.staticTexts["welcomeOriginalNotice"].frame.maxY)
    let actions = XCTAttachment(screenshot: app.screenshot())
    actions.name = "qa-onboarding-inline-actions"
    actions.lifetime = .keepAlways
    add(actions)
    finish.tap()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
    app.terminate()
    app.launchArguments = ["--ui-testing", "--ui-onboarding"]
    app.launch()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
    XCTAssertFalse(app.staticTexts["welcomeTitle"].exists)
  }
}
