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
    app.buttons["finishOnboarding"].tap()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
    app.terminate()
    app.launchArguments = ["--ui-testing", "--ui-onboarding"]
    app.launch()
    XCTAssertTrue(app.buttons["openSettings"].waitForExistence(timeout: 20))
    XCTAssertFalse(app.staticTexts["welcomeTitle"].exists)
  }
}
