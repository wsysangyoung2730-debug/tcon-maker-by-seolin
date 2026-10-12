import XCTest

final class HomeImportUITests: XCTestCase {
  func testExampleCardAndPrimaryButtonOpenPhotoLibrary() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--ui-reset"]
    app.launch()
    let card = app.buttons["homeExamplePhoto"]
    expectation(for: NSPredicate(format: "exists == true AND enabled == true"), evaluatedWith: card)
    waitForExpectations(timeout: 180)
    card.tap()
    closePhotoPicker(app)
    let button = app.buttons["importPhotos"]
    for _ in 0..<5 where !button.isHittable { app.swipeUp() }
    XCTAssertTrue(button.isHittable)
    XCTAssertTrue(app.scrollViews["homeContent"].buttons["importPhotos"].exists)
    button.tap()
    closePhotoPicker(app)
  }
  private func closePhotoPicker(_ app: XCUIApplication) {
    let cancel = app.buttons.matching(NSPredicate(format: "label IN %@", ["취소", "Cancel"])).firstMatch
    XCTAssertTrue(cancel.waitForExistence(timeout: 15), app.debugDescription)
    cancel.tap()
    XCTAssertTrue(app.buttons["homeExamplePhoto"].waitForExistence(timeout: 10))
  }
}
